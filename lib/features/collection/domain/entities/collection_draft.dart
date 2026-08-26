import 'package:equatable/equatable.dart';

import '../../../cheques/domain/entities/cheque.dart';
import 'cheque_scan.dart';
import 'emirates_id_scan.dart';
import 'vendor.dart';

enum ChequeOcrStatus { idle, scanning, done, rejected }

/// In-progress state for the 6-step "New collection" form. Immutable value
/// object (copied via [copyWith]) so the step-completion logic below is
/// pure and unit-testable without touching Riverpod or widgets — the
/// notifier that owns this just holds and replaces it.
class CollectionDraft extends Equatable {
  const CollectionDraft({
    this.vendor,
    this.repName = '',
    this.nameFromOcr = false,
    this.repMobile = '',
    this.repPhotoPath,
    this.idFrontPath,
    this.idBackPath,
    this.frontIdScan,
    this.backIdScan,
    this.isScanningId = false,
    this.cheque,
    this.chequeCopyPath,
    this.chequeOcrStatus = ChequeOcrStatus.idle,
    this.chequeScan,
    this.voucherPath,
    this.supportingDocPaths = const [],
    this.consent = false,
    this.signaturePath,
  });

  final Vendor? vendor;

  final String repName;

  /// True if [repName] was auto-filled from the Emirates ID OCR result
  /// because the agent hadn't typed one yet — drives the "Auto-filled from
  /// Emirates ID scan" note. Cleared the moment the agent edits the name.
  final bool nameFromOcr;
  final String repMobile;
  final String? repPhotoPath;

  final String? idFrontPath;
  final String? idBackPath;

  /// Raw per-side OCR results — kept separate rather than merged eagerly
  /// so [idScan] can always prefer the front's reading of a field over the
  /// back's, regardless of which side was captured/rescanned last.
  final EmiratesIdScan? frontIdScan;
  final EmiratesIdScan? backIdScan;
  final bool isScanningId;

  /// The real, currently-SIGNED cheque selected for this collection
  /// (`GET /cheques?status=SIGNED&search=<vendor name>`). Its number,
  /// amount and bank are server truth — they aren't retyped by the agent,
  /// and aren't even sent in the submit request (only the cheque's id is —
  /// the server already knows the rest).
  final Cheque? cheque;
  final String? chequeCopyPath;

  /// The on-device OCR read of [chequeCopyPath] is a non-blocking sanity
  /// check only (does the photographed cheque look like [cheque]?) — it
  /// never gates [stepsDone], unlike the old free-typed-entry flow.
  final ChequeOcrStatus chequeOcrStatus;
  final ChequeScan? chequeScan;

  /// Both fully optional — step 5 ("Voucher & documents") never appears in
  /// [stepsDone]/[missingStepNames], so neither field ever blocks Submit.
  final String? voucherPath;
  final List<String> supportingDocPaths;

  final bool consent;

  /// Populated as soon as the agent taps "Use signature" in the signature
  /// sheet (see `SignatureSheet`), not deferred to submit time — so step-6
  /// completion is judged directly on this being non-null.
  final String? signaturePath;

  static const stepNames = ['vendor', 'Emirates ID', 'representative details', 'a signed cheque', 'consent', 'signature'];

  bool get isMobileValid => RegExp(r'^\d{9}$').hasMatch(repMobile.replaceAll(RegExp(r'\D'), ''));

  /// Merges [frontIdScan] and [backIdScan] field-by-field, front winning
  /// whenever both sides read a value — the back scan only backfills
  /// whatever the front scan couldn't read. Null only if neither side has
  /// been scanned yet.
  EmiratesIdScan? get idScan {
    final front = frontIdScan;
    final back = backIdScan;
    if (front == null && back == null) return null;
    String pick(String? a, String? b) => (a != null && a.isNotEmpty) ? a : (b ?? '');
    final idNumber = pick(front?.idNumber, back?.idNumber);
    final name = pick(front?.name, back?.name);
    final nationality = pick(front?.nationality, back?.nationality);
    final expiry = pick(front?.expiry, back?.expiry);
    final fieldsFound = [idNumber, name, nationality, expiry].where((f) => f.isNotEmpty).length;
    return EmiratesIdScan(
      idNumber: idNumber,
      name: name,
      nationality: nationality,
      expiry: expiry,
      confidence: '${(fieldsFound / 4 * 100).round()}%',
    );
  }

  /// The on-device cheque-photo scan found a different cheque number than
  /// the one actually selected — surfaced as a non-blocking warning, since
  /// [cheque] (not the scan) is what gets submitted.
  bool get chequeNumberMismatch {
    final scanned = chequeScan?.chequeNumber;
    return cheque != null && scanned != null && scanned.isNotEmpty && scanned != cheque!.chequeNumber;
  }

  double get amountValue => cheque?.amount ?? 0;

  /// One flag per numbered step on the collect screen, in display order.
  /// Step 4 ("Cheque") requires both picking a real SIGNED cheque and
  /// capturing its photo — the on-device OCR read is a non-blocking sanity
  /// check only (see [chequeNumberMismatch]), unlike the old free-typed-
  /// entry flow where a rejected scan blocked this step.
  List<bool> get stepsDone => [
        vendor != null,
        idFrontPath != null && idBackPath != null && idScan != null,
        repName.trim().isNotEmpty && isMobileValid && repPhotoPath != null,
        cheque != null && chequeCopyPath != null && chequeOcrStatus != ChequeOcrStatus.scanning,
        consent,
        signaturePath != null,
      ];

  List<String> get missingStepNames {
    final done = stepsDone;
    return [for (var i = 0; i < stepNames.length; i++) if (!done[i]) stepNames[i]];
  }

  bool get isComplete => missingStepNames.isEmpty;

  CollectionDraft copyWith({
    Vendor? Function()? vendor,
    String? repName,
    bool? nameFromOcr,
    String? repMobile,
    String? Function()? repPhotoPath,
    String? Function()? idFrontPath,
    String? Function()? idBackPath,
    EmiratesIdScan? Function()? frontIdScan,
    EmiratesIdScan? Function()? backIdScan,
    bool? isScanningId,
    Cheque? Function()? cheque,
    String? Function()? chequeCopyPath,
    ChequeOcrStatus? chequeOcrStatus,
    ChequeScan? Function()? chequeScan,
    String? Function()? voucherPath,
    List<String>? supportingDocPaths,
    bool? consent,
    String? Function()? signaturePath,
  }) {
    return CollectionDraft(
      vendor: vendor != null ? vendor() : this.vendor,
      repName: repName ?? this.repName,
      nameFromOcr: nameFromOcr ?? this.nameFromOcr,
      repMobile: repMobile ?? this.repMobile,
      repPhotoPath: repPhotoPath != null ? repPhotoPath() : this.repPhotoPath,
      idFrontPath: idFrontPath != null ? idFrontPath() : this.idFrontPath,
      idBackPath: idBackPath != null ? idBackPath() : this.idBackPath,
      frontIdScan: frontIdScan != null ? frontIdScan() : this.frontIdScan,
      backIdScan: backIdScan != null ? backIdScan() : this.backIdScan,
      isScanningId: isScanningId ?? this.isScanningId,
      cheque: cheque != null ? cheque() : this.cheque,
      chequeCopyPath: chequeCopyPath != null ? chequeCopyPath() : this.chequeCopyPath,
      chequeOcrStatus: chequeOcrStatus ?? this.chequeOcrStatus,
      chequeScan: chequeScan != null ? chequeScan() : this.chequeScan,
      voucherPath: voucherPath != null ? voucherPath() : this.voucherPath,
      supportingDocPaths: supportingDocPaths ?? this.supportingDocPaths,
      consent: consent ?? this.consent,
      signaturePath: signaturePath != null ? signaturePath() : this.signaturePath,
    );
  }

  @override
  List<Object?> get props => [
        vendor,
        repName,
        nameFromOcr,
        repMobile,
        repPhotoPath,
        idFrontPath,
        idBackPath,
        frontIdScan,
        backIdScan,
        isScanningId,
        cheque,
        chequeCopyPath,
        chequeOcrStatus,
        chequeScan,
        voucherPath,
        supportingDocPaths,
        consent,
        signaturePath,
      ];
}
