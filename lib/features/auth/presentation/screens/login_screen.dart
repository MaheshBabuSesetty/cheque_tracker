import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/labeled_text_field.dart';
import '../../../../core/widgets/sobha_wordmark.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _agentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _agentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
          agentId: _agentIdController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _useDemoAgent() {
    _agentIdController.text = AppConstants.demoAgentId;
    _passwordController.text = AppConstants.demoAgentPassword;
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
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
                          label: 'AGENT ID',
                          controller: _agentIdController,
                          hintText: 'agent.rashid',
                          validator: (v) => Validators.notEmpty(v, fieldName: 'Agent ID'),
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
                        Center(
                          child: TextButton(
                            onPressed: isLoading ? null : _useDemoAgent,
                            child: Text(
                              'Use demo agent — ${AppConstants.demoAgentId} / ${AppConstants.demoAgentPassword}',
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
            ),
          ],
        ),
      ),
    );
  }
}
