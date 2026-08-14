// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_tab_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the `IndexedStack` in `MainShellScreen` (0 = Collect, 1 =
/// Transactions) — a plain int, per the routing guidance for tab sections
/// that don't need their own navigation stack.

@ProviderFor(MainTabIndexNotifier)
final mainTabIndexProvider = MainTabIndexNotifierProvider._();

/// Drives the `IndexedStack` in `MainShellScreen` (0 = Collect, 1 =
/// Transactions) — a plain int, per the routing guidance for tab sections
/// that don't need their own navigation stack.
final class MainTabIndexNotifierProvider
    extends $NotifierProvider<MainTabIndexNotifier, int> {
  /// Drives the `IndexedStack` in `MainShellScreen` (0 = Collect, 1 =
  /// Transactions) — a plain int, per the routing guidance for tab sections
  /// that don't need their own navigation stack.
  MainTabIndexNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mainTabIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mainTabIndexNotifierHash();

  @$internal
  @override
  MainTabIndexNotifier create() => MainTabIndexNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$mainTabIndexNotifierHash() =>
    r'9764da52786fd460061475c8384ce036774e1945';

/// Drives the `IndexedStack` in `MainShellScreen` (0 = Collect, 1 =
/// Transactions) — a plain int, per the routing guidance for tab sections
/// that don't need their own navigation stack.

abstract class _$MainTabIndexNotifier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
