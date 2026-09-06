import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cheques/domain/entities/cheque.dart';
import '../../../cheques/presentation/providers/cheque_providers.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/phone_country_codes.dart';
import '../../domain/entities/cheque_scan.dart';
import '../../domain/entities/collection_draft.dart';
import '../../domain/entities/collection_record.dart';
import '../../domain/entities/vendor.dart';
import 'collection_providers.dart';
import 'collections_notifier.dart';

part 'collect_draft_notifier.g.dart';

/// State for the in-progress "New collection" form. One notifier per
/// active draft — [submit] resets it back to empty on success, ready for
/// "Record another". `keepAlive: true` because that lifecycle is explicit
/// (via [submit]/[reset]), not tied to widget listener count — the
/// multi-step capture flows below (e.g. [captureChequeCopy]) span camera
/// navigation and OCR calls, and must not have their in-flight state
/// evicted by autoDispose losing listeners mid-flow.
@Riverpod(keepAlive: true)
class CollectDraftNotifier extends _$CollectDraftNotifier {
  @override
  CollectionDraft build() => const CollectionDraft();

  /// Picking a different vendor invalidates whatever cheque/photo was
  /// selected for the previous one — a cheque only ever belongs to one
  /// vendor.
  void pickVendor(Vendor vendor) => state = state.copyWith(
        vendor: () => vendor,
        cheque: () => null,
        chequeCopyPath: () => null,
        chequeScan: () => null,
      );

  void clearVendor() => state = state.copyWith(
        vendor: () => null,
        cheque: () => null,
        chequeCopyPath: () => null,
        chequeScan: () => null,
      );

  void setRepName(String value) => state = state.copyWith(repName: value, nameFromOcr: false);

  /// If [value] is a full number with a country code already on it (e.g.
  /// pasted as "+91 98765 43210"), splits it into [CollectionDraft.repMobileCountryCode]
  /// and the local digits instead of storing the whole string as the local
  /// number. Plain local digits (the common case — typing after the fixed
  /// prefix chip) pass through unchanged.
  void setRepMobile(String value) {
    final detected = detectPhoneCountryCode(value);
    if (detected != null) {
      state = state.copyWith(repMobile: detected.localNumber, repMobileCountryCode: detected.countryCode);
      return;
    }
    state = state.copyWith(repMobile: value);
  }

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

  /// Captures a photo of the cheque and, if [number] matches one of
  /// [vendor]'s currently-SIGNED cheques, picks that cheque with the photo
  /// just taken already attached as its copy — [number] alone decides the
  /// match. Never fabricates a match — a number that isn't on file leaves
  /// [CollectionDraft.cheque] untouched so the caller can show an error.
  ///
  /// Once matched, the same photo is OCR'd as a non-blocking sanity check
  /// against the matched cheque's vendor name (see [_scanChequeCopy]).
  ///
  /// Returns `null` if the agent backed out of the camera (nothing to
  /// show), otherwise whether a match was found.
  Future<bool?> captureAndSelectCheque({required Vendor vendor, required String number}) async {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return false;

    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'cheque-scan-select');
    if (path == null) return null;

    final match = await _findSignedCheque(vendor: vendor, number: trimmed);
    if (match == null) return false;

    state = state.copyWith(cheque: () => match, chequeCopyPath: () => path);
    await _scanChequeCopy(path, match);
    return true;
  }

  /// Looks for one of [vendor]'s SIGNED cheques whose number matches
  /// [number], without touching draft state.
  Future<Cheque?> _findSignedCheque({required Vendor vendor, required String number}) async {
    final cheques = await ref.read(signedChequesForVendorProvider(vendor).future);
    for (final candidate in cheques) {
      if (candidate.chequeNumber.trim().toUpperCase() == number.toUpperCase()) {
        return candidate;
      }
    }
    // A cheque leaf's MICR line is zero-padded to a fixed width (e.g.
    // "079064"), but the number as stored on file often isn't (e.g.
    // "79064") — an exact match already tried above, so this only kicks
    // in once that's failed, and only strips *leading* zeros (never
    // touches interior/trailing digits) so it can't accidentally conflate
    // two genuinely different cheque numbers.
    final normalized = _stripLeadingZeros(number.toUpperCase());
    for (final candidate in cheques) {
      if (_stripLeadingZeros(candidate.chequeNumber.trim().toUpperCase()) == normalized) {
        return candidate;
      }
    }
    // Temporary diagnostic: run `flutter logs` (or check the IDE's debug
    // console) after a "No SIGNED cheque on file matches that number"
    // check to see exactly what was compared — tells you in one look
    // whether the typed number is fine but that vendor's SIGNED list
    // genuinely doesn't contain it (wrong vendor, not signed yet, etc).
    debugPrint(
      'Cheque select-by-number: no match for "$number" among '
      '${vendor.name}\'s ${cheques.length} SIGNED cheque(s): '
      '${cheques.map((c) => c.chequeNumber).join(', ')}',
    );
    return null;
  }

  /// "00445566" → "445566"; "0" → "0" (never strips down to empty for an
  /// all-zero string — see [MlKitChequeOcrService]'s equivalent
  /// placeholder guard for why an all-zero cheque number is never treated
  /// as meaningful in the first place, upstream of this comparison).
  static String _stripLeadingZeros(String digits) {
    final stripped = digits.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? '0' : stripped;
  }

  void clearCheque() => state = state.copyWith(
        cheque: () => null,
        chequeCopyPath: () => null,
        chequeScan: () => null,
      );

  /// Captures/replaces the cheque copy photo, then re-runs the OCR sanity
  /// check against the already-selected cheque (see [_scanChequeCopy]).
  Future<void> captureChequeCopy() async {
    final cheque = state.cheque;
    if (cheque == null) return;
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'cheque-copy');
    if (path == null) return;
    state = state.copyWith(chequeCopyPath: () => path);
    await _scanChequeCopy(path, cheque);
  }

  /// OCR's [path] and checks it against [cheque]'s vendor name — a
  /// non-blocking sanity check ("did you photograph the right cheque?"),
  /// surfaced via [CollectionDraft.chequeScanWarnings]. Never overwrites or
  /// fabricates [cheque] itself.
  ///
  /// A failed scan (any exception — a stalled ML Kit model download, a
  /// decode error, ...) must still clear [CollectionDraft.isScanningChequeCopy]:
  /// that flag alone blocks step 4's completion, so leaving it stuck at
  /// `true` would make an already-captured, already-selected cheque look
  /// like it reverted to incomplete.
  Future<void> _scanChequeCopy(String path, Cheque cheque) async {
    state = state.copyWith(isScanningChequeCopy: true, chequeScan: () => null);
    ChequeScan? scan;
    try {
      scan = await ref.read(scanChequeProvider)(path, expectedPayeeName: cheque.supplierName);
    } catch (e) {
      debugPrint('Cheque copy scan failed, treating as unscanned: $e');
    }
    state = state.copyWith(isScanningChequeCopy: false, chequeScan: () => scan);
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
