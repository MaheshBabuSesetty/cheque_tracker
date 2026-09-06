import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/providers/app_version_provider.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../../../core/widgets/sobha_wordmark.dart';
import '../../../../services/version_check_service.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  // ignore: prefer_final_fields
  bool _rememberDevice = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberDevice: _rememberDevice,
        );
  }

  // ignore: unused_element
  void _submitSso() {
    ref.read(authProvider.notifier).loginWithSso(rememberDevice: _rememberDevice);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (
      AsyncValue<User?>? previous,
      AsyncValue<User?> next,
    ) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
          }
        },
        error: (error, _) => context.showSnackBar(
          error is Failure ? error.message : 'Login failed. Please try again.',
          isError: true,
        ),
      );
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.hasError && authState.error is Failure
        ? (authState.error as Failure).message
        : null;
    final colors = context.semanticColors;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
              child: ResponsiveContent(
                child: Column(
                  children: [
                    const SobhaWordmark(fontSize: 27),
                    Container(
                      width: 44,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 11),
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.pageBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                ),
                child: ResponsiveContent(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign in',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 19),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Use the field agent credentials issued with the web account.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LabeledTextField(
                                  label: 'USERNAME',
                                  controller: _usernameController,
                                  hintText: 'e.g. agent.smith',
                                  validator: (v) => Validators.notEmpty(
                                    v,
                                    fieldName: 'Username',
                                  ),
                                ),
                                const SizedBox(height: 13),
                                LabeledTextField(
                                  label: 'PASSWORD',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  hintText: '••••••••',
                                  validator: Validators.password,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: colors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                if (errorMessage != null) ...[
                                  const SizedBox(height: 9),
                                  Text(
                                    errorMessage,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                // "Remember this device" checkbox disabled — commented out
                                // for reuse later. _rememberDevice stays true by default.
                                // const SizedBox(height: 10),
                                // InkWell(
                                //   onTap: () => setState(
                                //     () => _rememberDevice = !_rememberDevice,
                                //   ),
                                //   borderRadius: BorderRadius.circular(6),
                                //   child: Padding(
                                //     padding: const EdgeInsets.symmetric(vertical: 4),
                                //     child: Row(
                                //       mainAxisSize: MainAxisSize.min,
                                //       children: [
                                //         SizedBox(
                                //           width: 20,
                                //           height: 20,
                                //           child: Checkbox(
                                //             value: _rememberDevice,
                                //             onChanged: (value) => setState(
                                //               () => _rememberDevice = value ?? true,
                                //             ),
                                //             visualDensity: VisualDensity.compact,
                                //             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                //             activeColor: AppColors.gold,
                                //           ),
                                //         ),
                                //         const SizedBox(width: 8),
                                //         Text(
                                //           'Remember this device',
                                //           style: TextStyle(
                                //             fontSize: 12,
                                //             color: colors.textMuted,
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                const SizedBox(height: 10),
                                AppPrimaryButton(
                                  label: 'Sign in',
                                  isLoading: isLoading,
                                  onPressed: _submit,
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: Colors.black,
                                ),
                                // SSO sign-in disabled — commented out for reuse later.
                                // const SizedBox(height: 18),
                                // Row(
                                //   children: [
                                //     Expanded(child: Divider(color: colors.hairline)),
                                //     Padding(
                                //       padding: const EdgeInsets.symmetric(horizontal: 10),
                                //       child: Text(
                                //         'OR',
                                //         style: TextStyle(
                                //           fontSize: 10.5,
                                //           fontWeight: FontWeight.w700,
                                //           letterSpacing: 0.6,
                                //           color: colors.textFaint,
                                //         ),
                                //       ),
                                //     ),
                                //     Expanded(child: Divider(color: colors.hairline)),
                                //   ],
                                // ),
                                // const SizedBox(height: 18),
                                // _MicrosoftSignInButton(
                                //   isLoading: isLoading,
                                //   onPressed: _submitSso,
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                        child: const _VersionFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sign in with Microsoft" — the light/outlined button style Microsoft's
/// own branding guidelines specify, deliberately distinct from the gold
/// primary button so it reads as an alternate path, not a second primary
/// CTA. The four-square mark is drawn directly (official brand colors,
/// no asset/font needed) rather than fetched or rasterized.
// ignore: unused_element
class _MicrosoftSignInButton extends StatelessWidget {
  const _MicrosoftSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
          side: BorderSide(color: colors.surfaceBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black54),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _MicrosoftLogo(),
                  const SizedBox(width: 10),
                  Text(
                    'Sign in with Microsoft',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Microsoft's four-square mark, official brand colors.
class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo();

  @override
  Widget build(BuildContext context) {
    const gap = 2.0;
    const squareSize = 9.0;
    Widget square(Color color) => Container(width: squareSize, height: squareSize, color: color);

    return SizedBox(
      width: squareSize * 2 + gap,
      height: squareSize * 2 + gap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [square(const Color(0xFFF25022)), const SizedBox(width: gap), square(const Color(0xFF7FBA00))],
          ),
          const SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [square(const Color(0xFF00A4EF)), const SizedBox(width: gap), square(const Color(0xFFFFB900))],
          ),
        ],
      ),
    );
  }
}

class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  Future<void> _showUpdateSheet(BuildContext context, AppVersionStatus status) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: sheetContext.semanticColors.pageBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Update available',
                    style: Theme.of(
                      sheetContext,
                    ).textTheme.titleLarge?.copyWith(fontSize: 17.5),
                  ),
                ),
                IconButton(
                  tooltip: 'Later',
                  icon: Icon(Icons.close, size: 20, color: sheetContext.semanticColors.textMuted),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Version ${status.latestVersion} is ready — you have ${status.currentVersion}.',
              style: TextStyle(
                fontSize: 12.5,
                color: sheetContext.semanticColors.textMuted,
              ),
            ),
            if (status.releaseNotes != null) ...[
              const SizedBox(height: 12),
              Text(
                status.releaseNotes!,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: 'Update now',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  context.showSnackBar(
                    'This would open the App Store / Play Store in production.',
                  );
                }
              },
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final info = versionAsync.value;
    final updateStatus = info?.updateStatus;
    final colors = context.semanticColors;

    return Column(
      children: [
        if (updateStatus != null && updateStatus.updateAvailable) ...[
          GestureDetector(
            onTap: () => _showUpdateSheet(context, updateStatus),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.pendingBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.system_update_alt, size: 14, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Update available — v${updateStatus.latestVersion}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (info != null) ...[
          Text(
            'v${info.version} (${info.buildNumber})',
            style: TextStyle(
              fontSize: 10.5,
              color: colors.textFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          '© Sobha Realty 2026',
          style: TextStyle(fontSize: 10, color: colors.textFaint),
        ),
      ],
    );
  }
}
