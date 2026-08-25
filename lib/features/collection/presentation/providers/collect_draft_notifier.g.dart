// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collect_draft_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another".

@ProviderFor(CollectDraftNotifier)
final collectDraftProvider = CollectDraftNotifierProvider._();

/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another".
final class CollectDraftNotifierProvider
    extends $NotifierProvider<CollectDraftNotifier, CollectionDraft> {
  /// State for the in-progress "New collection" form. One notifier per
  /// active draft — [submit] resets it back to empty on success, ready for
  /// "Record another".
  CollectDraftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectDraftNotifierHash();

  @$internal
  @override
  CollectDraftNotifier create() => CollectDraftNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CollectionDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CollectionDraft>(value),
    );
  }
}

String _$collectDraftNotifierHash() =>
    r'8714f42994c04d80067622b475eb0b19533d76ac';

/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another".

abstract class _$CollectDraftNotifier extends $Notifier<CollectionDraft> {
  CollectionDraft build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CollectionDraft, CollectionDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CollectionDraft, CollectionDraft>,
              CollectionDraft,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
