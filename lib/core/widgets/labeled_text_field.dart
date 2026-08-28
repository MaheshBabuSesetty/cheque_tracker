import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// The label-above-input composition used throughout the login and
/// collection screens: a small bold letter-spaced caption sitting above a
/// filled, rounded-border field (the field's own visual style comes from
/// `AppTheme`'s `inputDecorationTheme` — this widget only adds the caption).
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.prefixText,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.monospace = false,
    this.autovalidateMode,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;
  final String? prefixText;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool monospace;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: context.semanticColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          onChanged: onChanged,
          autovalidateMode: autovalidateMode,
          style: monospace ? const TextStyle(fontFamily: 'monospace') : null,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
