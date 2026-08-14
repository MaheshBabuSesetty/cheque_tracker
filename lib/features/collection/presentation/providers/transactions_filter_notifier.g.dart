// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_filter_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The transactions search box's current text — filtering is search-only
/// (no status chips); the per-row `StatusBadge` still shows Synced/Pending.

@ProviderFor(TransactionsSearchNotifier)
final transactionsSearchProvider = TransactionsSearchNotifierProvider._();

/// The transactions search box's current text — filtering is search-only
/// (no status chips); the per-row `StatusBadge` still shows Synced/Pending.
final class TransactionsSearchNotifierProvider
    extends $NotifierProvider<TransactionsSearchNotifier, String> {
  /// The transactions search box's current text — filtering is search-only
  /// (no status chips); the per-row `StatusBadge` still shows Synced/Pending.
  TransactionsSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionsSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionsSearchNotifierHash();

  @$internal
  @override
  TransactionsSearchNotifier create() => TransactionsSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$transactionsSearchNotifierHash() =>
    r'6e5af72e9e3454b0230dbba5d671207215caaa41';

/// The transactions search box's current text — filtering is search-only
/// (no status chips); the per-row `StatusBadge` still shows Synced/Pending.

abstract class _$TransactionsSearchNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The transactions list after applying the current search text. Derives
/// from [collectionsProvider] rather than duplicating its data, so a new
/// submission (which invalidates that provider) flows through
/// automatically.

@ProviderFor(filteredCollections)
final filteredCollectionsProvider = FilteredCollectionsProvider._();

/// The transactions list after applying the current search text. Derives
/// from [collectionsProvider] rather than duplicating its data, so a new
/// submission (which invalidates that provider) flows through
/// automatically.

final class FilteredCollectionsProvider
    extends
        $FunctionalProvider<
          List<CollectionRecord>,
          List<CollectionRecord>,
          List<CollectionRecord>
        >
    with $Provider<List<CollectionRecord>> {
  /// The transactions list after applying the current search text. Derives
  /// from [collectionsProvider] rather than duplicating its data, so a new
  /// submission (which invalidates that provider) flows through
  /// automatically.
  FilteredCollectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredCollectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredCollectionsHash();

  @$internal
  @override
  $ProviderElement<List<CollectionRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CollectionRecord> create(Ref ref) {
    return filteredCollections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CollectionRecord> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CollectionRecord>>(value),
    );
  }
}

String _$filteredCollectionsHash() =>
    r'b70bc6eb8c8fddf9f3435ed0ae29d58c89ae39f1';
