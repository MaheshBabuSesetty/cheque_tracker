import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/collection_record.dart';
import 'collection_providers.dart';

part 'collection_detail_provider.g.dart';

/// Full detail for one collection (`GET /collections/{chequeId}`) — the
/// history list only carries the slim `CollectionSummary` shape, so the
/// detail screen fetches this on demand rather than searching an
/// already-loaded list.
@riverpod
Future<CollectionRecord> collectionDetail(Ref ref, String chequeId) {
  return ref.watch(getCollectionDetailProvider)(chequeId);
}
