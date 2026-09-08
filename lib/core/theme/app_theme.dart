import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'theme_extensions.dart';

class AppTheme {
  const AppTheme._();

  static InputDecorationTheme _inputDecorationTheme({
    required Color fill,
    required Color borderColor,
    required Color hintColor,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      hintStyle: TextStyle(color: hintColor),
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
      scaffoldBackgroundColor: AppSemanticColors.light.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppSemanticColors.light.pageBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppSemanticColors.light.surface,
        borderColor: AppSemanticColors.light.inputBorder,
        hintColor: AppSemanticColors.light.textFaint,
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
      scaffoldBackgroundColor: AppSemanticColors.dark.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppSemanticColors.dark.pageBackground,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppSemanticColors.dark.surface,
        borderColor: AppSemanticColors.dark.inputBorder,
        hintColor: AppSemanticColors.dark.textFaint,
      ),
      extensions: const [AppSemanticColors.dark],
    );
  }
}
