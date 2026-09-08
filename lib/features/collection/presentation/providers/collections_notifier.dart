import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/collection_summary.dart';
import 'collection_providers.dart';

part 'collections_notifier.g.dart';

/// All submitted collections (`GET /collections`), newest first.
/// [CollectDraftNotifier.submit] invalidates this provider so the
/// transactions list picks up a new record immediately.
@riverpod
class Collections extends _$Collections {
  @override
  FutureOr<List<CollectionSummary>> build() => ref.watch(getCollectionsProvider)();
}
