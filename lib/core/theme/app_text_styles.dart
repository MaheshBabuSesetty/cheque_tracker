import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 [TextTheme] used by both light and dark `ThemeData`. Kept as
/// a single source so typography stays consistent across brightness modes.
///
/// Two-typeface brand pairing: Playfair Display (a Georgia-like serif) for
/// display/headline/title styles — the "Sobha" wordmark, screen titles,
/// amounts — and Poppins for everything read at body/UI size (inputs,
/// buttons, labels), matching the approved design's serif-heading /
/// sans-body split.
class AppTextStyles {
  const AppTextStyles._();

  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      );
}
