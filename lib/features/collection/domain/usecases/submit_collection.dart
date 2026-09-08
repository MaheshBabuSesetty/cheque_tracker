import '../entities/collection_draft.dart';
import '../entities/collection_record.dart';
import '../repositories/collection_repository.dart';

/// Submits a completed [CollectionDraft] as one atomic multipart request
/// (`POST /cheques/{chequeId}/collection`) — the server, not the client,
/// assigns the collection's id and transitions the cheque SIGNED → ISSUED.
/// Callers must check `draft.isComplete` first — screens use it to disable
/// the submit button, so reaching here with an incomplete draft is a
/// programmer error.
class SubmitCollection {
  const SubmitCollection(this._repository);

  final CollectionRepository _repository;

  Future<CollectionRecord> call(CollectionDraft draft) {
    assert(draft.isComplete, 'SubmitCollection called on an incomplete draft: ${draft.missingStepNames}');
    return _repository.submit(draft);
  }
}
