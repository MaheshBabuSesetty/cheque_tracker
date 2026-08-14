import 'package:flutter/material.dart';

/// Sobha Field Collection brand palette — pinned to the exact values from
/// the approved design (black/gold/cream), not a generic Material seed.
/// `AppTheme` derives `ColorScheme`s from [gold] via `ColorScheme.fromSeed`
/// for standard widgets; screens that need the literal brand look
/// (splash, login, the collection flow) reference these tokens directly.
class AppColors {
  const AppColors._();

  static const Color gold = Color(0xFFC9A227);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color cream = Color(0xFFF5F3EE);

  /// Link/secondary-brand text on light backgrounds (darker than [gold] for
  /// contrast — e.g. "Use demo agent…", "Change", helper links).
  static const Color goldLink = Color(0xFF8A6D1A);

  static const Color textMuted = Color(0xFF66707D);
  static const Color textFaint = Color(0xFF94A0AB);

  static const Color success = Color(0xFF05744F);
  static const Color successBg = Color(0xFFE7F6EF);
  static const Color pendingBg = Color(0xFFF6ECC9);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFB3261E);

  static const Color online = Color(0xFF4ADE80);

  /// Kept as the seed for `ColorScheme.fromSeed` in AppTheme.
  static const Color seed = gold;
}
