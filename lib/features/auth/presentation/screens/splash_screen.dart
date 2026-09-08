import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_device/safe_device.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animated_widgets/gold_loading_bar.dart';
import '../../../../core/widgets/sobha_wordmark.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_notifier.dart';

/// Resolves the session (via `AuthNotifier.build()`, which checks the
/// cached user / hits `getCurrentUser`) before deciding whether to land on
/// [RouteNames.login] or [RouteNames.home] — the auth-guard redirect point
/// referenced from `app_router.dart`.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _blockedForIntegrity = false;

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  /// Root/jailbreak check as a defense-in-depth layer, given this app
  /// handles Emirates ID and cheque data — skipped in debug builds so the
  /// team can keep using rooted/jailbroken test devices and emulators.
  /// Detection failures fail OPEN (treated as "not compromised") rather
  /// than blocking legitimate users if the plugin itself misbehaves.
  Future<bool> _isDeviceCompromised() async {
    if (kDebugMode) return false;
    try {
      return await SafeDevice.isJailBroken;
    } catch (_) {
      return false;
    }
  }

  Future<void> _redirect() async {
    if (await _isDeviceCompromised()) {
      if (!mounted) return;
      setState(() => _blockedForIntegrity = true);
      return;
    }

    User? user;
    try {
      user = await ref.read(authProvider.future);
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      user == null ? RouteNames.login : RouteNames.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: _blockedForIntegrity
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SobhaWordmark(fontSize: 38, boxed: true),
                    const SizedBox(height: 24),
                    Text(
                      'This app can\'t run here',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'For the security of the Emirates ID and cheque data it handles, '
                      'this app can\'t run on a rooted or jailbroken device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SobhaWordmark(fontSize: 38, boxed: true),
                  const SizedBox(height: 24),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const GoldLoadingBar(),
                ],
              ),
      ),
    );
  }
}
