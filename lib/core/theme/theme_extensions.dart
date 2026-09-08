import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens the brand palette in [AppColors] doesn't cover on its own
/// — every one of these was, until now, a literal color repeated across
/// screens (`Colors.white`, `AppColors.cream`, ad-hoc hex like `0xFF3A4552`)
/// that looked fine in the app's original light-only design but broke down
/// once dark mode was wired up: text colors that already came from
/// [ThemeData] would flip to a light-on-dark palette while the container
/// around them stayed a hardcoded light color, producing washed-out,
/// low-contrast screens in dark mode.
///
/// [light]'s values are the *exact* hex codes every screen used to hardcode
/// — light mode's appearance is unchanged. [dark] is new design work: same
/// gold accent, brand-tinted dark surfaces instead of an inverted/generic
/// Material dark theme.
///
/// Access via `context.semanticColors` (extension below) or
/// `Theme.of(context).extension<AppSemanticColors>()!`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.pageBackground,
    required this.surface,
    required this.surfaceBorder,
    required this.hairline,
    required this.dashedBorder,
    required this.inputBorder,
    required this.cardShadow,
    required this.textMuted,
    required this.textFaint,
    required this.bodyText,
    required this.inactiveIcon,
    required this.accent,
    required this.success,
    required this.successBg,
    required this.successBorder,
    required this.matchedBg,
    required this.matchedBorder,
    required this.pendingBg,
    required this.warning,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.neutralTint,
    required this.neutralTintBorder,
    required this.placeholderBg,
  });

  /// Scaffold/header background — was `AppColors.cream` everywhere.
  final Color pageBackground;

  /// Card/sheet/list-row background — was `Colors.white`.
  final Color surface;

  /// Border around a [surface] card — was `Colors.black.withValues(alpha: 0.07-0.08)`.
  final Color surfaceBorder;

  /// Thin dividers/hairline borders — was `Colors.black.withValues(alpha: 0.05-0.09)`.
  final Color hairline;

  /// Dashed/empty-capture-tile outline — noticeably stronger than
  /// [surfaceBorder]/[hairline] — was `Colors.black.withValues(alpha: 0.2-0.22)`.
  final Color dashedBorder;

  /// Border for a manually-styled "looks like a TextField" container (the
  /// vendor search box, the mobile-number field) — matches the real
  /// `InputDecorationTheme` border color from [AppTheme] so both look
  /// consistent. Was `Colors.black.withValues(alpha: 0.16)`.
  final Color inputBorder;

  final Color cardShadow;

  /// Was `AppColors.textMuted` used directly — now theme-aware.
  final Color textMuted;

  /// Was `AppColors.textFaint` used directly — now theme-aware.
  final Color textFaint;

  /// Secondary slate body text inside tinted cards — was the ad-hoc literal
  /// `Color(0xFF3A4552)` repeated across `collect_screen.dart`/`signature_sheet.dart`.
  final Color bodyText;

  /// Inactive bottom-tab icon/label — was the ad-hoc literal `Color(0xFFA9B2BB)`.
  final Color inactiveIcon;

  /// Links/icons/CTAs on a [surface] background — was `AppColors.goldLink`
  /// used directly. `goldLink` is deliberately darker than [AppColors.gold]
  /// for contrast on a light surface; dark mode needs a brighter gold for
  /// the same reason in reverse.
  final Color accent;

  /// Was `AppColors.success` used directly — now theme-aware (brighter in
  /// dark mode for contrast).
  final Color success;

  /// Filled/verified capture-tile tint pair — was `Color(0xFFEEF8F2)` /
  /// `Color(0xFF05744F)`.
  final Color successBg;
  final Color successBorder;

  /// A second, paler success-tint pair used for "vendor matched"/OCR-read
  /// cards — was `Color(0xFFF4FBF7)` / `Color(0xFFCDEADB)`. Kept distinct
  /// from [successBg]/[successBorder] since light mode already used two
  /// visually-different pale-green pairs.
  final Color matchedBg;
  final Color matchedBorder;

  /// "Scanning…" pill background — was `AppColors.pendingBg` used directly.
  final Color pendingBg;

  /// Was `AppColors.warning` used directly — now theme-aware.
  final Color warning;

  /// Was `AppColors.danger` used directly — now theme-aware (brighter in
  /// dark mode for contrast).
  final Color danger;

  /// Error/mismatch-tint pair — was `Color(0xFFFDF0EF)` / `Color(0xFFF3CFCB)`.
  final Color dangerBg;
  final Color dangerBorder;

  /// Neutral gold-tinted card/avatar pair (vendor-picked card, step-card
  /// "tinted" variant, list-row avatar) — was `Color(0xFFFAF8F1)` /
  /// `Color(0xFFECDFB6)`.
  final Color neutralTint;
  final Color neutralTintBorder;

  /// Empty/disabled capture-tile, dashed-box, and input-affix background —
  /// was `Color(0xFFFBFAF6)` (and the near-identical `0xFFF4F2EC`/`0xFFF7F5EF`/
  /// `0xFFFAFAF7` one-off variants, consolidated into this single token).
  final Color placeholderBg;

  static const light = AppSemanticColors(
    pageBackground: AppColors.cream,
    surface: Colors.white,
    surfaceBorder: Color(0x14000000),
    hairline: Color(0x12000000),
    dashedBorder: Color(0x33000000),
    inputBorder: Color(0x29000000),
    cardShadow: Color(0x1A000000),
    textMuted: AppColors.textMuted,
    textFaint: AppColors.textFaint,
    bodyText: Color(0xFF3A4552),
    inactiveIcon: Color(0xFFA9B2BB),
    accent: AppColors.goldLink,
    success: AppColors.success,
    successBg: Color(0xFFEEF8F2),
    successBorder: Color(0xFF05744F),
    matchedBg: Color(0xFFF4FBF7),
    matchedBorder: Color(0xFFCDEADB),
    pendingBg: AppColors.pendingBg,
    warning: AppColors.warning,
    danger: AppColors.danger,
    dangerBg: Color(0xFFFDF0EF),
    dangerBorder: Color(0xFFF3CFCB),
    neutralTint: Color(0xFFFAF8F1),
    neutralTintBorder: Color(0xFFECDFB6),
    placeholderBg: Color(0xFFFBFAF6),
  );

  static const dark = AppSemanticColors(
    pageBackground: Color(0xFF141210),
    surface: Color(0xFF1F1C17),
    surfaceBorder: Color(0x1FFFFFFF),
    hairline: Color(0x1AFFFFFF),
    dashedBorder: Color(0x40FFFFFF),
    inputBorder: Color(0x29FFFFFF),
    cardShadow: Color(0x33000000),
    textMuted: Color(0xFFA7AFB8),
    textFaint: Color(0xFF7C848D),
    bodyText: Color(0xFFD8DEE3),
    inactiveIcon: Color(0xFF6B7580),
    accent: Color(0xFFE0B94A),
    success: Color(0xFF3DDC97),
    successBg: Color(0x263DDC97),
    successBorder: Color(0xFF3DDC97),
    matchedBg: Color(0x1A3DDC97),
    matchedBorder: Color(0x663DDC97),
    pendingBg: Color(0x33C9A227),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFFF6B60),
    dangerBg: Color(0x33B3261E),
    dangerBorder: Color(0x80B3261E),
    neutralTint: Color(0x1FC9A227),
    neutralTintBorder: Color(0x59C9A227),
    placeholderBg: Color(0xFF262219),
  );

  @override
  AppSemanticColors copyWith({
    Color? pageBackground,
    Color? surface,
    Color? surfaceBorder,
    Color? hairline,
    Color? dashedBorder,
    Color? inputBorder,
    Color? cardShadow,
    Color? textMuted,
    Color? textFaint,
    Color? bodyText,
    Color? inactiveIcon,
    Color? accent,
    Color? success,
    Color? successBg,
    Color? successBorder,
    Color? matchedBg,
    Color? matchedBorder,
    Color? pendingBg,
    Color? warning,
    Color? danger,
    Color? dangerBg,
    Color? dangerBorder,
    Color? neutralTint,
    Color? neutralTintBorder,
    Color? placeholderBg,
  }) {
    return AppSemanticColors(
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      hairline: hairline ?? this.hairline,
      dashedBorder: dashedBorder ?? this.dashedBorder,
      inputBorder: inputBorder ?? this.inputBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      bodyText: bodyText ?? this.bodyText,
      inactiveIcon: inactiveIcon ?? this.inactiveIcon,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      matchedBg: matchedBg ?? this.matchedBg,
      matchedBorder: matchedBorder ?? this.matchedBorder,
      pendingBg: pendingBg ?? this.pendingBg,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      neutralTint: neutralTint ?? this.neutralTint,
      neutralTintBorder: neutralTintBorder ?? this.neutralTintBorder,
      placeholderBg: placeholderBg ?? this.placeholderBg,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      pageBackground: m(pageBackground, other.pageBackground),
      surface: m(surface, other.surface),
      surfaceBorder: m(surfaceBorder, other.surfaceBorder),
      hairline: m(hairline, other.hairline),
      dashedBorder: m(dashedBorder, other.dashedBorder),
      inputBorder: m(inputBorder, other.inputBorder),
      cardShadow: m(cardShadow, other.cardShadow),
      textMuted: m(textMuted, other.textMuted),
      textFaint: m(textFaint, other.textFaint),
      bodyText: m(bodyText, other.bodyText),
      inactiveIcon: m(inactiveIcon, other.inactiveIcon),
      accent: m(accent, other.accent),
      success: m(success, other.success),
      successBg: m(successBg, other.successBg),
      successBorder: m(successBorder, other.successBorder),
      matchedBg: m(matchedBg, other.matchedBg),
      matchedBorder: m(matchedBorder, other.matchedBorder),
      pendingBg: m(pendingBg, other.pendingBg),
      warning: m(warning, other.warning),
      danger: m(danger, other.danger),
      dangerBg: m(dangerBg, other.dangerBg),
      dangerBorder: m(dangerBorder, other.dangerBorder),
      neutralTint: m(neutralTint, other.neutralTint),
      neutralTintBorder: m(neutralTintBorder, other.neutralTintBorder),
      placeholderBg: m(placeholderBg, other.placeholderBg),
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
