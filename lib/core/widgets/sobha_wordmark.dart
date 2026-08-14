import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// The gold "Sobha" brand mark, rendered with the literal design values
/// (not the themed text style) since it must look identical regardless of
/// the active `ThemeMode`. [boxed] draws the tinted/bordered frame used on
/// the splash screen; without it, it's bare text for tighter contexts
/// (login header, main-shell top bar).
class SobhaWordmark extends StatelessWidget {
  const SobhaWordmark({super.key, this.fontSize = 27, this.boxed = false});

  final double fontSize;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      AppConstants.brandWordmark,
      style: GoogleFonts.playfairDisplay(
        color: AppColors.gold,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        letterSpacing: fontSize * 0.02,
        height: 1,
      ),
    );

    if (!boxed) return text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.gold.withValues(alpha: 0.08),
      ),
      child: text,
    );
  }
}
