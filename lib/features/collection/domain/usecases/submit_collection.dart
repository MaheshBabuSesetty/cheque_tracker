import '../entities/collection_draft.dart';
import '../entities/collection_record.dart';
import '../repositories/collection_repository.dart';

/// Turns a completed [CollectionDraft] into a [CollectionRecord] (assigning
/// id/ref/timestamp/status) and persists it. Callers must check
/// `draft.isComplete` first — screens use it to disable the submit button,
/// so reaching here with an incomplete draft is a programmer error.
class SubmitCollection {
  const SubmitCollection(this._repository);

  final CollectionRepository _repository;

  Future<CollectionRecord> call(CollectionDraft draft) async {
    assert(draft.isComplete, 'SubmitCollection called on an incomplete draft: ${draft.missingStepNames}');

    final existing = await _repository.getAll();
    final now = DateTime.now();
    final record = CollectionRecord(
      id: 'col-${now.microsecondsSinceEpoch}',
      ref: 'COL-${now.year}-${(342 + existing.length).toString().padLeft(4, '0')}',
      vendorName: draft.vendor!.name,
      repName: draft.repName.trim(),
      repMobile: '+971 ${draft.repMobile.replaceAll(RegExp(r'\D'), '')}',
      emiratesId: draft.idScan!.idNumber,
      nationality: draft.idScan!.nationality,
      expiry: draft.idScan!.expiry,
      chequeNumber: draft.chequeNumber.trim(),
      amount: draft.amountValue,
      currency: draft.chequeCurrency,
      status: CollectionStatus.synced,
      timestamp: now,
      repPhotoPath: draft.repPhotoPath,
      idFrontPath: draft.idFrontPath,
      idBackPath: draft.idBackPath,
      chequeCopyPath: draft.chequeCopyPath,
      signaturePath: draft.signaturePath,
      voucherPath: draft.voucherPath,
      supportingDocPaths: draft.supportingDocPaths,
    );
    return _repository.submit(record);
  }
}
