// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collections_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All submitted collections (`GET /collections`), newest first.
/// [CollectDraftNotifier.submit] invalidates this provider so the
/// transactions list picks up a new record immediately.

@ProviderFor(Collections)
final collectionsProvider = CollectionsProvider._();

/// All submitted collections (`GET /collections`), newest first.
/// [CollectDraftNotifier.submit] invalidates this provider so the
/// transactions list picks up a new record immediately.
final class CollectionsProvider
    extends $AsyncNotifierProvider<Collections, List<CollectionSummary>> {
  /// All submitted collections (`GET /collections`), newest first.
  /// [CollectDraftNotifier.submit] invalidates this provider so the
  /// transactions list picks up a new record immediately.
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

String _$collectionsHash() => r'45cb76fd9ef4a9b9cacd092b5114934630847f80';

/// All submitted collections (`GET /collections`), newest first.
/// [CollectDraftNotifier.submit] invalidates this provider so the
/// transactions list picks up a new record immediately.

abstract class _$Collections extends $AsyncNotifier<List<CollectionSummary>> {
  FutureOr<List<CollectionSummary>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<CollectionSummary>>,
              List<CollectionSummary>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CollectionSummary>>,
                List<CollectionSummary>
              >,
              AsyncValue<List<CollectionSummary>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
