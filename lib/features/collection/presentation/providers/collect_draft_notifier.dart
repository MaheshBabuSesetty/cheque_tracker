import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cheques/domain/entities/cheque.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../domain/entities/collection_draft.dart';
import '../../domain/entities/collection_record.dart';
import '../../domain/entities/vendor.dart';
import 'collection_providers.dart';
import 'collections_notifier.dart';

part 'collect_draft_notifier.g.dart';

/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another".
@riverpod
class CollectDraftNotifier extends _$CollectDraftNotifier {
  @override
  CollectionDraft build() => const CollectionDraft();

  /// Picking a different vendor invalidates whatever cheque/photo was
  /// selected for the previous one — a cheque only ever belongs to one
  /// vendor.
  void pickVendor(Vendor vendor) => state = state.copyWith(vendor: () => vendor, cheque: () => null, chequeCopyPath: () => null, chequeOcrStatus: ChequeOcrStatus.idle, chequeScan: () => null);

  void clearVendor() => state = state.copyWith(vendor: () => null, cheque: () => null, chequeCopyPath: () => null, chequeOcrStatus: ChequeOcrStatus.idle, chequeScan: () => null);

  void setRepName(String value) => state = state.copyWith(repName: value, nameFromOcr: false);

  void setRepMobile(String value) => state = state.copyWith(repMobile: value);

  Future<void> captureRepPhoto() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'rep-photo');
    if (path != null) state = state.copyWith(repPhotoPath: () => path);
  }

  Future<void> captureIdFront() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'id-front');
    if (path == null) return;
    state = state.copyWith(idFrontPath: () => path, frontIdScan: () => null, isScanningId: true);
    final scan = await ref.read(scanEmiratesIdProvider)(path);
    state = state.copyWith(isScanningId: false, frontIdScan: () => scan);
    _autoFillRepName();
  }

  Future<void> captureIdBack() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'id-back');
    if (path == null) return;
    state = state.copyWith(idBackPath: () => path, backIdScan: () => null, isScanningId: true);
    final scan = await ref.read(scanEmiratesIdProvider)(path);
    state = state.copyWith(isScanningId: false, backIdScan: () => scan);
    _autoFillRepName();
  }

  Future<void> rescanId() async {
    final frontPath = state.idFrontPath;
    final backPath = state.idBackPath;
    if (frontPath == null && backPath == null) return;
    state = state.copyWith(isScanningId: true);
    final frontScan = frontPath != null ? await ref.read(scanEmiratesIdProvider)(frontPath) : null;
    final backScan = backPath != null ? await ref.read(scanEmiratesIdProvider)(backPath) : null;
    state = state.copyWith(
      isScanningId: false,
      frontIdScan: frontPath != null ? () => frontScan : null,
      backIdScan: backPath != null ? () => backScan : null,
    );
  }

  /// Fills the representative name from whichever side's scan found one,
  /// but only the first time — once the agent has typed a name (or it's
  /// already been auto-filled once), neither side's scan overwrites it.
  void _autoFillRepName() {
    if (state.nameFromOcr || state.repName.trim().isNotEmpty) return;
    final name = state.idScan?.name ?? '';
    if (name.isNotEmpty) state = state.copyWith(repName: name, nameFromOcr: true);
  }

  /// Picks the real, currently-SIGNED cheque this collection is for.
  /// Clears any previously-captured cheque photo/scan — it would have been
  /// of a different cheque.
  void pickCheque(Cheque cheque) => state = state.copyWith(
        cheque: () => cheque,
        chequeCopyPath: () => null,
        chequeOcrStatus: ChequeOcrStatus.idle,
        chequeScan: () => null,
      );

  void clearCheque() => state = state.copyWith(
        cheque: () => null,
        chequeCopyPath: () => null,
        chequeOcrStatus: ChequeOcrStatus.idle,
        chequeScan: () => null,
      );

  Future<void> captureChequeCopy() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'cheque-copy');
    if (path == null) return;
    state = state.copyWith(chequeCopyPath: () => path, chequeScan: () => null, chequeOcrStatus: ChequeOcrStatus.scanning);
    await _runChequeScan(path);
  }

  Future<void> rescanCheque() async {
    final path = state.chequeCopyPath;
    if (path == null) return;
    state = state.copyWith(chequeOcrStatus: ChequeOcrStatus.scanning);
    await _runChequeScan(path);
  }

  /// The scan is a non-blocking sanity check against the already-selected
  /// [CollectionDraft.cheque] — it never overwrites/fabricates the cheque
  /// number or amount, and a rejected/mismatched read never blocks
  /// [CollectionDraft.stepsDone].
  Future<void> _runChequeScan(String path) async {
    final scan = await ref.read(scanChequeProvider)(path);
    state = state.copyWith(
      chequeOcrStatus: scan.accepted ? ChequeOcrStatus.done : ChequeOcrStatus.rejected,
      chequeScan: () => scan,
    );
  }

  /// Discards the captured cheque photo so the agent can retake it — the
  /// tile reverts to its empty state, but the selected cheque stays.
  void recaptureCheque() {
    state = state.copyWith(chequeCopyPath: () => null, chequeOcrStatus: ChequeOcrStatus.idle, chequeScan: () => null);
  }

  Future<void> captureVoucher() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'voucher');
    if (path != null) state = state.copyWith(voucherPath: () => path);
  }

  Future<void> addSupportingDocument() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'supporting-doc');
    if (path != null) state = state.copyWith(supportingDocPaths: [...state.supportingDocPaths, path]);
  }

  void removeSupportingDocument(String path) {
    state = state.copyWith(supportingDocPaths: state.supportingDocPaths.where((p) => p != path).toList());
  }

  void toggleConsent() => state = state.copyWith(consent: !state.consent);

  /// Called with the PNG bytes exported by `SignatureSheet` once the agent
  /// taps "Use signature" — persists them immediately rather than waiting
  /// for the final submit, since the sheet (and its strokes) is gone by
  /// then.
  Future<void> setSignature(Uint8List bytes) async {
    final path = await ref.read(imageCaptureServiceProvider).saveBytes(bytes, prefix: 'signature');
    state = state.copyWith(signaturePath: () => path);
  }

  /// Finalizes the draft and submits it if (and only if) every step is
  /// complete — returns `null` otherwise. Screens gate the submit button
  /// on `draft.isComplete` already; this is the safety net for that same
  /// check.
  Future<CollectionRecord?> submit() async {
    if (!state.isComplete) return null;

    final record = await ref.read(submitCollectionProvider)(state);
    state = const CollectionDraft();
    ref.invalidate(collectionsProvider);
    return record;
  }

  void reset() => state = const CollectionDraft();
}
