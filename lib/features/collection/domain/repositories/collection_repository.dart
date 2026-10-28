import '../entities/collection_draft.dart';
import '../entities/collection_record.dart';
import '../entities/collection_summary.dart';

abstract class CollectionRepository {
  /// `POST /cheques/bulk/collection` — one atomic multipart submission covering the
  /// collector details, their shared files and every cheque with its own
  /// photo. [draft] must be complete (`draft.isComplete`). Returns one record
  /// per cheque, in the order they were added.
  Future<List<CollectionRecord>> submit(CollectionDraft draft);

  /// `GET /collections` — collection history, newest first.
  Future<List<CollectionSummary>> getAll();

  /// `GET /collections/{chequeId}` — full detail for one collection.
  Future<CollectionRecord> getByChequeId(String chequeId);
}
