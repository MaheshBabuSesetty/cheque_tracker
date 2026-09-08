// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Full detail for one collection (`GET /collections/{chequeId}`) — the
/// history list only carries the slim `CollectionSummary` shape, so the
/// detail screen fetches this on demand rather than searching an
/// already-loaded list.

@ProviderFor(collectionDetail)
final collectionDetailProvider = CollectionDetailFamily._();

/// Full detail for one collection (`GET /collections/{chequeId}`) — the
/// history list only carries the slim `CollectionSummary` shape, so the
/// detail screen fetches this on demand rather than searching an
/// already-loaded list.

final class CollectionDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CollectionRecord>,
          CollectionRecord,
          FutureOr<CollectionRecord>
        >
    with $FutureModifier<CollectionRecord>, $FutureProvider<CollectionRecord> {
  /// Full detail for one collection (`GET /collections/{chequeId}`) — the
  /// history list only carries the slim `CollectionSummary` shape, so the
  /// detail screen fetches this on demand rather than searching an
  /// already-loaded list.
  CollectionDetailProvider._({
    required CollectionDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'collectionDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collectionDetailHash();

  @override
  String toString() {
    return r'collectionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CollectionRecord> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CollectionRecord> create(Ref ref) {
    final argument = this.argument as String;
    return collectionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CollectionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collectionDetailHash() => r'8da9e97d5d7962d373c73c9d46adf136d443466a';

/// Full detail for one collection (`GET /collections/{chequeId}`) — the
/// history list only carries the slim `CollectionSummary` shape, so the
/// detail screen fetches this on demand rather than searching an
/// already-loaded list.

final class CollectionDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CollectionRecord>, String> {
  CollectionDetailFamily._()
    : super(
        retry: null,
        name: r'collectionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Full detail for one collection (`GET /collections/{chequeId}`) — the
  /// history list only carries the slim `CollectionSummary` shape, so the
  /// detail screen fetches this on demand rather than searching an
  /// already-loaded list.

  CollectionDetailProvider call(String chequeId) =>
      CollectionDetailProvider._(argument: chequeId, from: this);

  @override
  String toString() => r'collectionDetailProvider';
}
