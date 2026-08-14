import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/dependency_injection.dart';

part 'theme_mode_provider.g.dart';

/// Persisted light/dark/system preference, restored on app start and
/// written through to [StorageService] on every change so it survives
/// restarts. Wrapping `MaterialApp.themeMode` with `AnimatedTheme`-driven
/// widgets gives the smooth cross-fade when this value changes.
@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final stored = await ref.read(storageServiceProvider).getThemeMode();
    if (stored != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(storageServiceProvider).saveThemeMode(mode.name);
  }
}
