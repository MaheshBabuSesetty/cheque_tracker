import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/version_check_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';
import 'app_primary_button.dart';

/// Blocks the app behind a non-dismissible dialog when a newer Loadly build
/// is available. There's deliberately no "Later" — ad-hoc APK distribution
/// has no staged/optional rollout concept, so every detected update is
/// mandatory. `PopScope(canPop: false)` swallows the Android back
/// button/gesture and `barrierDismissible: false` stops a tap outside from
/// closing it; the only way past this screen is to actually update.
Future<void> showForceUpdateDialog(BuildContext context, AppVersionStatus status) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => PopScope(canPop: false, child: _ForceUpdateDialog(status: status)),
  );
}

class _ForceUpdateDialog extends StatelessWidget {
  const _ForceUpdateDialog({required this.status});

  final AppVersionStatus status;

  Future<void> _openUpdate() async {
    final url = status.updateUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    // Defensive allowlist (found during a security review): updateUrl is
    // always LoadlyVersionCheckService.shareUrl today, a hardcoded constant,
    // so this can't currently be tripped — but VersionCheckService is an
    // interface, and nothing stops a future implementation from deriving
    // this from this app's own API response instead. Scoping the launch to
    // the one host this is meant for means that day can't turn an
    // update-check response into an arbitrary externally-launched URL.
    if (uri.scheme != 'https' || uri.host != 'loadly.io') return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return AlertDialog(
      backgroundColor: colors.pageBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Update required'),
      content: Text(
        'Version ${status.latestVersion} (build ${status.latestBuildNumber}) is available. '
        'You must update to keep using the app — build ${status.currentBuildNumber} is no longer supported.',
        style: TextStyle(fontSize: 13, color: colors.textMuted, height: 1.4),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: AppPrimaryButton(
            label: 'Update now',
            onPressed: _openUpdate,
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
