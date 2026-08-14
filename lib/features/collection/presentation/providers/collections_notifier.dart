import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/collection_record.dart';
import 'collection_providers.dart';

part 'collections_notifier.g.dart';

/// All submitted collections, newest first (the local datasource already
/// orders them that way). [CollectDraftNotifier.submit] invalidates this
/// provider so the transactions list picks up a new record immediately.
@riverpod
class Collections extends _$Collections {
  @override
  FutureOr<List<CollectionRecord>> build() => ref.watch(getCollectionsProvider)();
}
