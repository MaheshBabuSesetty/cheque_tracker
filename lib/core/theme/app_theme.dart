import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'theme_extensions.dart';

class AppTheme {
  const AppTheme._();

  static InputDecorationTheme _inputDecorationTheme({required Color fill, required Color borderColor}) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      hintStyle: const TextStyle(color: AppColors.textFaint),
      border: border(borderColor),
      enabledBorder: border(borderColor),
      focusedBorder: border(AppColors.gold, 1.5),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.5),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: Colors.white,
        borderColor: Colors.black.withValues(alpha: 0.16),
      ),
      extensions: const [AppSemanticColors.light],
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: colorScheme.surfaceContainerHighest,
        borderColor: Colors.white.withValues(alpha: 0.16),
      ),
      extensions: const [AppSemanticColors.dark],
    );
  }
}
