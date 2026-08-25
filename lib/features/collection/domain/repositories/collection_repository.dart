import '../entities/collection_draft.dart';
import '../entities/collection_record.dart';
import '../entities/collection_summary.dart';

abstract class CollectionRepository {
  /// `POST /cheques/{chequeId}/collection` — one atomic multipart
  /// submission covering collector details + every file. [draft] must be
  /// complete (`draft.isComplete`) and carry a selected [CollectionDraft.cheque].
  Future<CollectionRecord> submit(CollectionDraft draft);

  /// `GET /collections` — collection history, newest first.
  Future<List<CollectionSummary>> getAll();

  /// `GET /collections/{chequeId}` — full detail for one collection.
  Future<CollectionRecord> getByChequeId(String chequeId);
}
