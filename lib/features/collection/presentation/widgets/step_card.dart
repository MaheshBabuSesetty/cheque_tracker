import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extensions.dart';

/// One numbered card in the "New collection" form (Vendor, Representative,
/// Emirates ID, …): a circled step number, title, a DONE/REQUIRED/OPTIONAL
/// pill, and arbitrary [child] content below.
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.number,
    required this.title,
    required this.done,
    required this.child,
    this.tinted = false,
    this.optional = false,
  });

  final int number;
  final String title;
  final bool done;
  final Widget child;

  /// Consent step uses a tinted gold card instead of the plain white ones.
  final bool tinted;

  /// True for steps that never block Submit (e.g. "Voucher & documents").
  /// Always shows the "done" gold number circle and an "OPTIONAL" pill in
  /// the same neutral styling as an incomplete required step's "REQUIRED"
  /// pill, regardless of [done] — an optional step is never "incomplete".
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final numberDone = optional || done;
    final badgeText = optional ? 'OPTIONAL' : (done ? 'DONE' : 'REQUIRED');
    final badgeTinted = done && !optional;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? colors.neutralTint : colors.surface,
        border: Border.all(color: tinted ? colors.neutralTintBorder : colors.surfaceBorder),
        borderRadius: BorderRadius.circular(14),
        boxShadow: tinted ? null : [BoxShadow(color: colors.cardShadow, blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: numberDone ? AppColors.gold : AppColors.ink),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: numberDone ? AppColors.ink : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeTinted ? colors.successBg : colors.hairline,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: badgeTinted ? colors.success : colors.textFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
