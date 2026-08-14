import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thin fill bar showing "N of 6 complete" on the collect screen header.
/// Animates toward [progress] (0..1) whenever a step is completed.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 4,
        color: Colors.black.withValues(alpha: 0.09),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0, 1)),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, value, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(color: AppColors.gold),
          ),
        ),
      ),
    );
  }
}
