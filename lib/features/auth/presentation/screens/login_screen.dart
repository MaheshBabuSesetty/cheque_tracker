import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/providers/app_version_provider.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/labeled_text_field.dart';
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _useDemoAgent() {
    _usernameController.text = AppConstants.demoUsername;
    _passwordController.text = AppConstants.demoPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (AsyncValue<User?>? previous, AsyncValue<User?> next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
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

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white, fontSize: 18),
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
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
                ),
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
                              Text('Sign in', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 19)),
                              const SizedBox(height: 5),
                              Text(
                                'Use the field agent credentials issued with the web account.',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 20),
                              LabeledTextField(
                                label: 'USERNAME',
                                controller: _usernameController,
                                hintText: 'agent.rashid',
                                validator: (v) => Validators.notEmpty(v, fieldName: 'Username'),
                              ),
                              const SizedBox(height: 13),
                              LabeledTextField(
                                label: 'PASSWORD',
                                controller: _passwordController,
                                obscureText: true,
                                hintText: '••••••••',
                                validator: Validators.password,
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 9),
                                Text(
                                  errorMessage,
                                  style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
                                ),
                              ],
                              const SizedBox(height: 20),
                              AppPrimaryButton(
                                label: 'Sign in',
                                isLoading: isLoading,
                                onPressed: _submit,
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                              ),
                              // Local-development convenience only — must never render in a
                              // release build, since it would advertise a working credential
                              // to anyone who opens the app. See the security audit's F-1.
                              if (kDebugMode)
                                Center(
                                  child: TextButton(
                                    onPressed: isLoading ? null : _useDemoAgent,
                                    child: Text(
                                      'Use demo agent — ${AppConstants.demoUsername} / ${AppConstants.demoPassword}',
                                      style: const TextStyle(
                                        color: AppColors.goldLink,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _VersionFooter extends ConsumerWidget {
  const _VersionFooter();

  Future<void> _showUpdateSheet(BuildContext context, AppVersionStatus status) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update available', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontSize: 17.5)),
            const SizedBox(height: 6),
            Text(
              'Version ${status.latestVersion} is ready — you have ${status.currentVersion}.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            if (status.releaseNotes != null) ...[
              const SizedBox(height: 12),
              Text(status.releaseNotes!, style: const TextStyle(fontSize: 12, height: 1.4)),
            ],
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: 'Update now',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                if (context.mounted) {
                  context.showSnackBar('This would open the App Store / Play Store in production.');
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

    return Column(
      children: [
        if (updateStatus != null && updateStatus.updateAvailable) ...[
          GestureDetector(
            onTap: () => _showUpdateSheet(context, updateStatus),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.pendingBg, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update_alt, size: 14, color: AppColors.goldLink),
                  const SizedBox(width: 6),
                  Text(
                    'Update available — v${updateStatus.latestVersion}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldLink),
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
            style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
        ],
        const Text('© Sobha Realty 2026', style: TextStyle(fontSize: 10, color: AppColors.textFaint)),
      ],
    );
  }
}
