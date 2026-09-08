// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collect_draft_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another". `keepAlive: true` because that lifecycle is explicit
/// (via [submit]/[reset]), not tied to widget listener count — the
/// multi-step capture flows below (e.g. [captureChequeCopy]) span camera
/// navigation and OCR calls, and must not have their in-flight state
/// evicted by autoDispose losing listeners mid-flow.

@ProviderFor(CollectDraftNotifier)
final collectDraftProvider = CollectDraftNotifierProvider._();

/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another". `keepAlive: true` because that lifecycle is explicit
/// (via [submit]/[reset]), not tied to widget listener count — the
/// multi-step capture flows below (e.g. [captureChequeCopy]) span camera
/// navigation and OCR calls, and must not have their in-flight state
/// evicted by autoDispose losing listeners mid-flow.
final class CollectDraftNotifierProvider
    extends $NotifierProvider<CollectDraftNotifier, CollectionDraft> {
  /// State for the in-progress "New collection" form. One notifier per
  /// active draft — [submit] resets it back to empty on success, ready for
  /// "Record another". `keepAlive: true` because that lifecycle is explicit
  /// (via [submit]/[reset]), not tied to widget listener count — the
  /// multi-step capture flows below (e.g. [captureChequeCopy]) span camera
  /// navigation and OCR calls, and must not have their in-flight state
  /// evicted by autoDispose losing listeners mid-flow.
  CollectDraftNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectDraftProvider',
        isAutoDispose: false,
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
    r'2c077bf96a7d1fe1da8af9ec089bf5eb7f0814b3';

/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another". `keepAlive: true` because that lifecycle is explicit
/// (via [submit]/[reset]), not tied to widget listener count — the
/// multi-step capture flows below (e.g. [captureChequeCopy]) span camera
/// navigation and OCR calls, and must not have their in-flight state
/// evicted by autoDispose losing listeners mid-flow.

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
