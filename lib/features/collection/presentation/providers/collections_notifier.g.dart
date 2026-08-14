// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collections_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All submitted collections, newest first (the local datasource already
/// orders them that way). [CollectDraftNotifier.submit] invalidates this
/// provider so the transactions list picks up a new record immediately.

@ProviderFor(Collections)
final collectionsProvider = CollectionsProvider._();

/// All submitted collections, newest first (the local datasource already
/// orders them that way). [CollectDraftNotifier.submit] invalidates this
/// provider so the transactions list picks up a new record immediately.
final class CollectionsProvider
    extends $AsyncNotifierProvider<Collections, List<CollectionRecord>> {
  /// All submitted collections, newest first (the local datasource already
  /// orders them that way). [CollectDraftNotifier.submit] invalidates this
  /// provider so the transactions list picks up a new record immediately.
  CollectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionsHash();

  @$internal
  @override
  Collections create() => Collections();
}

String _$collectionsHash() => r'59b0f29e059f8785e237df5296978f85d5517c6d';

/// All submitted collections, newest first (the local datasource already
/// orders them that way). [CollectDraftNotifier.submit] invalidates this
/// provider so the transactions list picks up a new record immediately.

abstract class _$Collections extends $AsyncNotifier<List<CollectionRecord>> {
  FutureOr<List<CollectionRecord>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<CollectionRecord>>, List<CollectionRecord>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CollectionRecord>>,
                List<CollectionRecord>
              >,
              AsyncValue<List<CollectionRecord>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
