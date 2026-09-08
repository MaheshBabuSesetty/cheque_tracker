import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../../../core/widgets/sobha_wordmark.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/main_tab_notifier.dart';
import 'collect_screen.dart';
import 'transactions_screen.dart';

/// Post-login app shell: the black top bar (brand + online status + the
/// avatar that opens `ProfileScreen`, where sign-out actually lives), an
/// `IndexedStack` for the two tabs, and the bottom tab bar. Tab switching
/// is a plain `int` notifier rather than a nested `Navigator` — neither
/// tab needs its own back stack.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(mainTabIndexProvider);
    final agentName = ref.watch(authProvider).value?.name ?? '';

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            initials: _initials(agentName),
            onAvatarTap: () =>
                Navigator.of(context).pushNamed(RouteNames.profile),
          ),
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: const [CollectScreen(), TransactionsScreen()],
            ),
          ),
          _BottomTabBar(
            index: tabIndex,
            onChanged: (index) =>
                ref.read(mainTabIndexProvider.notifier).setIndex(index),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2);
    return parts.map((p) => p[0]).join().toUpperCase();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.initials, required this.onAvatarTap});

  final String initials;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 13),
        child: ResponsiveContent(
          child: Row(
            children: [
              const SobhaWordmark(fontSize: 16.5),
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.online,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'ONLINE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? '·' : initials,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.hairline)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.add_box_outlined,
                label: 'Collect',
                active: index == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _TabButton(
                icon: Icons.receipt_long_outlined,
                label: 'Transactions',
                active: index == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.onSurface
        : context.semanticColors.inactiveIcon;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
