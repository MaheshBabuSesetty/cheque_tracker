import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/collection_record.dart';

part 'last_submitted_record_notifier.g.dart';

/// Non-null while the Collect tab should show the "Collection recorded"
/// success view instead of the form; set by the collect screen right
/// after a successful submit (one record per cheque collected), cleared by
/// "Record another"/leaving the tab.
@riverpod
class LastSubmittedRecordNotifier extends _$LastSubmittedRecordNotifier {
  @override
  List<CollectionRecord>? build() => null;

  void set(List<CollectionRecord>? records) => state = records;
}
