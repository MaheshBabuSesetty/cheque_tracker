import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_notifier.dart';

/// Reached by tapping the initials avatar in the app shell's top bar.
/// Read-only account summary plus the sign-out action — no editable
/// fields, since agent profiles are managed on the web portal.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.07))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('← Back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldLink)),
                  ),
                  const SizedBox(height: 11),
                  Text('Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17.5)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 20),
                child: user == null
                    ? const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: Text('Not signed in.', style: TextStyle(color: AppColors.textFaint))),
                      )
                    : _ProfileBody(user: user),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final User user;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    return parts.map((p) => p[0]).join().toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign out?'),
        content: const Text(
          'You will need your agent ID and password to sign back in.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(user.name).isEmpty ? '·' : _initials(user.name),
                  style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 13),
              Text(user.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _ProfileCard(
          children: [
            const Text('ACCOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4)),
            const SizedBox(height: 12),
            _ProfileRow(label: 'Agent ID', value: user.id),
            _ProfileRow(label: 'Email', value: user.email),
            const _ProfileRow(label: 'Role', value: 'Field collection agent', isLast: true),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, size: 17, color: AppColors.danger),
            label: const Text('Sign out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
