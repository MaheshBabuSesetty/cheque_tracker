// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted light/dark/system preference, restored on app start and
/// written through to [StorageService] on every change so it survives
/// restarts. Wrapping `MaterialApp.themeMode` with `AnimatedTheme`-driven
/// widgets gives the smooth cross-fade when this value changes.

@ProviderFor(AppThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

/// Persisted light/dark/system preference, restored on app start and
/// written through to [StorageService] on every change so it survives
/// restarts. Wrapping `MaterialApp.themeMode` with `AnimatedTheme`-driven
/// widgets gives the smooth cross-fade when this value changes.
final class AppThemeModeProvider
    extends $NotifierProvider<AppThemeMode, ThemeMode> {
  /// Persisted light/dark/system preference, restored on app start and
  /// written through to [StorageService] on every change so it survives
  /// restarts. Wrapping `MaterialApp.themeMode` with `AnimatedTheme`-driven
  /// widgets gives the smooth cross-fade when this value changes.
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  AppThemeMode create() => AppThemeMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appThemeModeHash() => r'6a8cdfb688b50f0e5acffab5d775b6fea5abbeff';

/// Persisted light/dark/system preference, restored on app start and
/// written through to [StorageService] on every change so it survives
/// restarts. Wrapping `MaterialApp.themeMode` with `AnimatedTheme`-driven
/// widgets gives the smooth cross-fade when this value changes.

abstract class _$AppThemeMode extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
