import 'package:flutter/material.dart';

/// Custom design tokens that don't have a home in [ColorScheme]/[TextTheme].
/// Access via `Theme.of(context).extension<AppSemanticColors>()!`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.cardShadow,
  });

  final Color success;
  final Color warning;
  final Color cardShadow;

  static const light = AppSemanticColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFED6C02),
    cardShadow: Color(0x1A000000),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    cardShadow: Color(0x33000000),
  );

  @override
  AppSemanticColors copyWith({Color? success, Color? warning, Color? cardShadow}) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
