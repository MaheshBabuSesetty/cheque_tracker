import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The thin gold progress bar on the splash screen — plays once, purely
/// decorative. Actual navigation is driven by the real session check in
/// `SplashScreen`, independent of this animation's timing.
class GoldLoadingBar extends StatefulWidget {
  const GoldLoadingBar({super.key, this.width = 116, this.duration = const Duration(milliseconds: 1700)});

  final double width;
  final Duration duration;

  @override
  State<GoldLoadingBar> createState() => _GoldLoadingBarState();
}

class _GoldLoadingBarState extends State<GoldLoadingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(2),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _controller.value,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
      ),
    );
  }
}
