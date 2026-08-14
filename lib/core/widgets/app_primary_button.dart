import 'package:flutter/material.dart';

import 'animated_widgets/animated_press_button.dart';

/// Shared primary CTA button with a built-in loading state, so features
/// don't each re-implement "disable + show spinner while pending".
/// [backgroundColor]/[foregroundColor] override the theme's default button
/// colors for screens with a fixed brand look (e.g. the gold sign-in/submit
/// buttons on splash-adjacent screens) that shouldn't shift with the
/// light/dark theme toggle.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressButton(
      onTap: isLoading ? () {} : (onPressed ?? () {}),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: backgroundColor == null && foregroundColor == null
              ? null
              : ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  disabledBackgroundColor: backgroundColor?.withValues(alpha: 0.5),
                ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: foregroundColor,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
