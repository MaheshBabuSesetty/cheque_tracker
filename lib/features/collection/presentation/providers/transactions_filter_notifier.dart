import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/collection_record.dart';
import 'collections_notifier.dart';

part 'transactions_filter_notifier.g.dart';

/// The transactions search box's current text — filtering is search-only
/// (no status chips); the per-row `StatusBadge` still shows Synced/Pending.
@riverpod
class TransactionsSearchNotifier extends _$TransactionsSearchNotifier {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// The transactions list after applying the current search text. Derives
/// from [collectionsProvider] rather than duplicating its data, so a new
/// submission (which invalidates that provider) flows through
/// automatically.
@riverpod
List<CollectionRecord> filteredCollections(Ref ref) {
  final query = ref.watch(transactionsSearchProvider).trim().toLowerCase();
  final all = ref.watch(collectionsProvider).value ?? const <CollectionRecord>[];
  if (query.isEmpty) return all;

  return all
      .where((record) =>
          '${record.vendorName} ${record.repName} ${record.chequeNumber} ${record.ref}'.toLowerCase().contains(query))
      .toList();
}
