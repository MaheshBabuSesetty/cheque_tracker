import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../cheques/domain/entities/cheque.dart';
import '../../../cheques/presentation/providers/cheque_providers.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/phone_country_codes.dart';
import '../../domain/entities/cheque_scan.dart';
import '../../domain/entities/collected_cheque.dart';
import '../../domain/entities/collection_draft.dart';
import '../../domain/entities/collection_record.dart';
import '../../domain/entities/vendor.dart';
import 'collection_providers.dart';
import 'collections_notifier.dart';

part 'collect_draft_notifier.g.dart';

/// What [CollectDraftNotifier.submit] came to: the recorded collections
/// (one per cheque), or the message to show the agent.
class SubmitOutcome {
  const SubmitOutcome.succeeded(List<CollectionRecord> this.records) : error = null;
  const SubmitOutcome.failed(String this.error) : records = null;

  final List<CollectionRecord>? records;
  final String? error;
}

/// Result of [CollectDraftNotifier.captureAndAddCheque].
enum ChequeAddResult { added, notFound, alreadyAdded, limitReached }

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
  CollectionDraft build() {
    // Read the server's multi-cheque switch up front so the first submit
    // doesn't wait on it (a failed read just means one-by-one collection).
    unawaited(ref.read(bulkCollectionFlagProvider).isEnabled());
    return const CollectionDraft();
  }

  /// Best-effort delete of a captured file that's just been replaced or
  /// discarded — never blocks the caller (found during a security review:
  /// captured Emirates ID / cheque / signature images had no cleanup path
  /// at all before this, and accumulated on-device indefinitely).
  void _forgetFile(String? path) {
    if (path != null) unawaited(ref.read(imageCaptureServiceProvider).deleteFile(path));
  }

  void _forgetDraftFiles(CollectionDraft draft) {
    _forgetFile(draft.idFrontPath);
    _forgetFile(draft.idBackPath);
    for (final c in draft.cheques) {
      _forgetChequeFiles(c);
    }
    _forgetFile(draft.voucherPath);
    _forgetFile(draft.signaturePath);
    for (final path in draft.supportingDocPaths) {
      _forgetFile(path);
    }
  }

  /// Picking a different vendor invalidates every cheque/photo selected for
  /// the previous one — a cheque only ever belongs to one vendor.
  void pickVendor(Vendor vendor) {
    _forgetChequePhotos();
    state = state.copyWith(vendor: () => vendor, cheques: const []);
  }

  void clearVendor() {
    _forgetChequePhotos();
    state = state.copyWith(vendor: () => null, cheques: const []);
  }

  void _forgetChequePhotos() {
    for (final c in state.cheques) {
      _forgetChequeFiles(c);
    }
  }

  void _forgetChequeFiles(CollectedCheque cheque) {
    _forgetFile(cheque.photoPath);
    _forgetFile(cheque.voucherPath);
  }

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

  Future<void> captureIdFront() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'id-front');
    if (path == null) return;
    _forgetFile(state.idFrontPath);
    state = state.copyWith(idFrontPath: () => path, frontIdScan: () => null, isScanningId: true);
    final scan = await ref.read(scanEmiratesIdProvider)(path);
    state = state.copyWith(isScanningId: false, frontIdScan: () => scan);
    _autoFillRepName();
  }

  Future<void> captureIdBack() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'id-back');
    if (path == null) return;
    _forgetFile(state.idBackPath);
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
  /// [vendor]'s currently-SIGNED cheques, adds that cheque to the draft with
  /// the photo just taken attached — [number] alone decides the match. Can
  /// be called repeatedly to collect several cheques; every one gets its own
  /// photo. Never fabricates a match — a number that isn't on file leaves
  /// [CollectionDraft.cheques] untouched so the caller can show an error.
  ///
  /// Once added, the same photo is OCR'd as a non-blocking sanity check
  /// against the cheque's vendor name (see [_scanChequeCopy]).
  ///
  /// Returns `null` if the agent backed out of the camera (nothing to
  /// show), otherwise a [ChequeAddResult].
  Future<ChequeAddResult?> captureAndAddCheque({required Vendor vendor, required String number}) async {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return ChequeAddResult.notFound;
    if (state.cheques.length >= CollectionDraft.maxCheques) return ChequeAddResult.limitReached;

    // Checked before the camera opens, so a duplicate never costs a photo.
    final existing = await _findSignedCheque(vendor: vendor, number: trimmed);
    if (existing == null) return ChequeAddResult.notFound;
    if (state.cheques.any((c) => c.cheque.id == existing.id)) return ChequeAddResult.alreadyAdded;

    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'cheque-scan-select');
    if (path == null) return null;

    state = state.copyWith(
      cheques: [...state.cheques, CollectedCheque(cheque: existing, photoPath: path)],
    );
    await _scanChequeCopy(existing.id, path);
    return ChequeAddResult.added;
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
    // kDebugMode-gated — cheque numbers are financial data and must not
    // reach a release build's platform log (found during a security review).
    if (kDebugMode) {
      debugPrint(
        'Cheque select-by-number: no match for "$number" among '
        '${vendor.name}\'s ${cheques.length} SIGNED cheque(s): '
        '${cheques.map((c) => c.chequeNumber).join(', ')}',
      );
    }
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

  void removeCheque(String chequeId) {
    final removed = state.cheques.where((c) => c.cheque.id == chequeId);
    for (final c in removed) {
      _forgetChequeFiles(c);
    }
    state = state.copyWith(cheques: state.cheques.where((c) => c.cheque.id != chequeId).toList());
  }

  /// The agent's by-eye confirmation of one cheque's number — only offered
  /// when the MICR band couldn't confirm it (see
  /// [CollectedCheque.needsManualNumberCheck]).
  void toggleChequeNumberVerified(String chequeId) => _updateCheque(
        chequeId,
        (c) => c.copyWith(numberManuallyVerified: !c.numberManuallyVerified),
      );

  /// Replaces one cheque's photo, then re-runs the OCR sanity check on it
  /// (see [_scanChequeCopy]).
  Future<void> recaptureChequePhoto(String chequeId) async {
    final current = state.cheques.where((c) => c.cheque.id == chequeId).firstOrNull;
    if (current == null) return;
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'cheque-copy');
    if (path == null) return;
    _forgetFile(current.photoPath);
    _updateCheque(chequeId, (c) => c.copyWith(photoPath: path, submitError: () => null));
    await _scanChequeCopy(chequeId, path);
  }

  void _updateCheque(String chequeId, CollectedCheque Function(CollectedCheque) update) {
    state = state.copyWith(
      cheques: [for (final c in state.cheques) c.cheque.id == chequeId ? update(c) : c],
    );
  }

  /// OCR's [path] and checks it against the cheque's vendor name — a
  /// non-blocking sanity check ("did you photograph the right cheque?"),
  /// surfaced via [CollectedCheque.scanWarnings]. Never overwrites or
  /// fabricates the cheque itself.
  ///
  /// A failed scan (any exception — a stalled ML Kit model download, a
  /// decode error, ...) must still clear [CollectedCheque.isScanning]: that
  /// flag alone blocks step 4's completion, so leaving it stuck at `true`
  /// would make an already-captured cheque look like it reverted to
  /// incomplete.
  Future<void> _scanChequeCopy(String chequeId, String path) async {
    final entry = state.cheques.where((c) => c.cheque.id == chequeId).firstOrNull;
    if (entry == null) return;
    _updateCheque(
      chequeId,
      (c) => c.copyWith(isScanning: true, scan: () => null, numberManuallyVerified: false),
    );
    ChequeScan? scan;
    try {
      scan = await ref.read(scanChequeProvider)(path, expectedPayeeName: entry.cheque.supplierName);
    } catch (e) {
      debugPrint('Cheque copy scan failed, treating as unscanned: $e');
    }
    // The cheque may have been removed, or its photo replaced, while the
    // scan ran — a stale result must not land on the newer photo.
    final latest = state.cheques.where((c) => c.cheque.id == chequeId).firstOrNull;
    if (latest == null || latest.photoPath != path) return;
    _updateCheque(chequeId, (c) => c.copyWith(isScanning: false, scan: () => scan));
  }

  Future<void> captureVoucher() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'voucher');
    if (path == null) return;
    _forgetFile(state.voucherPath);
    state = state.copyWith(voucherPath: () => path);
  }

  /// Captures a voucher for one cheque only, replacing any it already has.
  /// It takes the place of the shared voucher for that cheque.
  Future<void> captureChequeVoucher(String chequeId) async {
    if (!state.cheques.any((c) => c.cheque.id == chequeId)) return;
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'voucher');
    if (path == null) return;
    // The cheque may have been removed while the camera was open.
    final current = state.cheques.where((c) => c.cheque.id == chequeId).firstOrNull;
    if (current == null) {
      _forgetFile(path);
      return;
    }
    _forgetFile(current.voucherPath);
    _updateCheque(chequeId, (c) => c.copyWith(voucherPath: () => path));
  }

  /// Drops one cheque's own voucher, so it falls back to the shared one.
  void removeChequeVoucher(String chequeId) {
    final current = state.cheques.where((c) => c.cheque.id == chequeId).firstOrNull;
    if (current?.voucherPath == null) return;
    _forgetFile(current!.voucherPath);
    _updateCheque(chequeId, (c) => c.copyWith(voucherPath: () => null));
  }

  Future<void> addSupportingDocument() async {
    final path = await ref.read(imageCaptureServiceProvider).captureFromCamera(prefix: 'supporting-doc');
    if (path != null) state = state.copyWith(supportingDocPaths: [...state.supportingDocPaths, path]);
  }

  void removeSupportingDocument(String path) {
    _forgetFile(path);
    state = state.copyWith(supportingDocPaths: state.supportingDocPaths.where((p) => p != path).toList());
  }

  void toggleConsent() => state = state.copyWith(consent: !state.consent);

  /// Called with the PNG bytes exported by `SignatureSheet` once the agent
  /// taps "Use signature" — persists them immediately rather than waiting
  /// for the final submit, since the sheet (and its strokes) is gone by
  /// then.
  Future<void> setSignature(Uint8List bytes) async {
    final path = await ref.read(imageCaptureServiceProvider).saveBytes(bytes, prefix: 'signature');
    _forgetFile(state.signaturePath);
    state = state.copyWith(signaturePath: () => path);
  }

  /// Finalizes the draft and submits it if (and only if) every step is
  /// complete — returns `null` otherwise. Screens gate the submit button
  /// on `draft.isComplete` already; this is the safety net for that same
  /// check.
  ///
  /// Never throws: a failure comes back as a [SubmitOutcome] carrying the
  /// message to show, and the draft is kept so the agent can fix it and
  /// resubmit. An error about one cheque is also marked on that cheque's
  /// card.
  Future<SubmitOutcome?> submit() async {
    if (!state.isComplete) return null;

    final draft = state;
    state = draft.copyWith(cheques: [for (final c in draft.cheques) c.copyWith(submitError: () => null)]);
    try {
      final records = await ref.read(submitCollectionProvider)(draft);
      return _finish(draft, records);
    } on ApiException catch (e) {
      // A cheque that's already collected (a retry after a half-finished
      // earlier attempt) or a server failure leaves the real outcome
      // unknown — find out rather than guess.
      if (e.code == 'CHEQUE_ALREADY_COLLECTED' || e.isServerFailure) return _reconcile(draft, e.message);
      _markCheque(e);
      return SubmitOutcome.failed(e.message);
    } on NetworkException catch (e) {
      // A dropped connection or timeout can happen after the server saved
      // everything.
      return _reconcile(draft, e.message);
    } on ValidationException catch (e) {
      return SubmitOutcome.failed(e.message);
    } on AuthException catch (e) {
      return SubmitOutcome.failed(e.message);
    } on ForbiddenException catch (e) {
      return SubmitOutcome.failed(e.message);
    } on RateLimitException catch (e) {
      return SubmitOutcome.failed(e.message);
    } on ServerException catch (e) {
      return _reconcile(draft, e.message);
    }
  }

  SubmitOutcome _finish(CollectionDraft draft, List<CollectionRecord> records) {
    // Uploaded successfully — the local copies have served their purpose.
    _forgetDraftFiles(draft);
    state = const CollectionDraft();
    ref.invalidate(collectionsProvider);
    return SubmitOutcome.succeeded(records);
  }

  /// Puts an error about one cheque (the API names it via `chequeId`) on
  /// that cheque's card. A missing or unknown id leaves just the message.
  void _markCheque(ApiException e) {
    final id = e.chequeId;
    if (id == null) return;
    _updateCheque(id, (c) => c.copyWith(submitError: () => e.message));
  }

  /// After a timeout, a 5xx or `CHEQUE_ALREADY_COLLECTED`, the cheques may
  /// have been collected even though the request "failed": the server marks
  /// them Issued as soon as the database saves them. Looks each cheque up
  /// and sorts the draft out accordingly — all collected is a success, some
  /// collected are dropped from the draft, none leaves it as it was.
  Future<SubmitOutcome> _reconcile(CollectionDraft draft, String originalMessage) async {
    final chequeRepository = ref.read(chequeRepositoryProvider);
    final collectedIds = <String>{};
    var lookupFailed = false;
    for (final c in draft.cheques) {
      try {
        final latest = await chequeRepository.getChequeById(c.cheque.id);
        if (latest.status.toUpperCase() == 'ISSUED') collectedIds.add(c.cheque.id);
      } catch (_) {
        lookupFailed = true;
      }
    }

    if (collectedIds.isEmpty) {
      return SubmitOutcome.failed(
        lookupFailed ? "$originalMessage Couldn't confirm whether it went through — check Transactions before retrying." : originalMessage,
      );
    }

    if (collectedIds.length == draft.cheques.length) {
      final records = <CollectionRecord>[];
      for (final id in collectedIds) {
        try {
          records.add(await ref.read(getCollectionDetailProvider)(id));
        } catch (_) {
          // The record can't be fetched right now; it's still collected.
        }
      }
      if (records.isNotEmpty) return _finish(draft, records);
      _forgetDraftFiles(draft);
      state = const CollectionDraft();
      ref.invalidate(collectionsProvider);
      return const SubmitOutcome.failed('Your collection was recorded. Check Transactions to see it.');
    }

    final collected = draft.cheques.where((c) => collectedIds.contains(c.cheque.id)).toList();
    for (final c in collected) {
      _forgetChequeFiles(c);
    }
    state = state.copyWith(cheques: state.cheques.where((c) => !collectedIds.contains(c.cheque.id)).toList());
    ref.invalidate(collectionsProvider);
    final numbers = collected.map((c) => c.cheque.chequeNumber).join(', ');
    return SubmitOutcome.failed(
      '${collected.length == 1 ? 'Cheque' : 'Cheques'} $numbers ${collected.length == 1 ? 'was' : 'were'} '
      'already collected and removed from this list. Review the rest and submit again.',
    );
  }

  void reset() {
    _forgetDraftFiles(state);
    state = const CollectionDraft();
  }
}
