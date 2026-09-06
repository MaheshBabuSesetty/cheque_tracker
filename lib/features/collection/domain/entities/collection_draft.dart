import 'package:equatable/equatable.dart';

import '../../../../core/utils/phone_country_codes.dart';
import '../../../cheques/domain/entities/cheque.dart';
import 'cheque_scan.dart';
import 'emirates_id_scan.dart';
import 'vendor.dart';

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
    this.repMobileCountryCode = defaultPhoneCountryCode,
    this.repPhotoPath,
    this.idFrontPath,
    this.idBackPath,
    this.frontIdScan,
    this.backIdScan,
    this.isScanningId = false,
    this.cheque,
    this.chequeCopyPath,
    this.isScanningChequeCopy = false,
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

  /// E.164 calling code, e.g. "+971" — defaults to UAE but changes when
  /// [CollectDraftNotifier.setRepMobile] detects one on a pasted/typed
  /// full number (see [detectPhoneCountryCode]).
  final String repMobileCountryCode;
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

  /// True only while the just-captured/recaptured [chequeCopyPath] photo is
  /// being OCR'd — used only to block [stepsDone] mid-scan, never surfaced
  /// as a rejection.
  final bool isScanningChequeCopy;

  /// The on-device OCR read of [chequeCopyPath], checked against [cheque]'s
  /// payee name — a non-blocking sanity check ("did you photograph the
  /// right cheque?"), never [stepsDone]-gating. See [chequeScanWarnings].
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

  bool get isMobileValid {
    final expectedLength = phoneCountryCodes[repMobileCountryCode] ?? 9;
    final digits = repMobile.replaceAll(RegExp(r'\D'), '');
    return digits.length == expectedLength;
  }

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
    final nationality = front?.nationality ?? back?.nationality;
    final fieldsFound = [idNumber, name].where((f) => f.isNotEmpty).length;
    return EmiratesIdScan(
      idNumber: idNumber,
      name: name,
      nationality: nationality,
      confidence: '${(fieldsFound / 2 * 100).round()}%',
    );
  }

  /// True once the front has been scanned but no ID number could be read
  /// off it — the image likely isn't a readable Emirates ID front (glare,
  /// crop, wrong side). Drives the "Emirates ID not detected" retry card;
  /// never true while a scan is still in flight.
  bool get idFrontOcrFailed => frontIdScan != null && frontIdScan!.idNumber.isEmpty;

  double get amountValue => cheque?.amount ?? 0;

  /// Non-blocking sanity warning from [chequeScan] against the actually
  /// selected [cheque]'s vendor — [cheque] (not the scan) is what gets
  /// submitted, so this never gates [stepsDone]; it's surfaced only so the
  /// agent can catch photographing the wrong cheque.
  List<String> get chequeScanWarnings {
    final scan = chequeScan;
    if (scan == null || cheque == null) return [];
    return [
      if (scan.nameMatched == false)
        "Couldn't find this vendor's name on the photographed cheque.",
    ];
  }

  /// One flag per numbered step on the collect screen, in display order.
  /// Step 4 ("Cheque") requires both picking a real SIGNED cheque and
  /// capturing its photo — the OCR check behind [chequeScanWarnings] is a
  /// non-blocking sanity check only, unlike [isScanningChequeCopy].
  List<bool> get stepsDone => [
        vendor != null,
        idFrontPath != null &&
            idBackPath != null &&
            idScan != null &&
            idScan!.idNumber.isNotEmpty &&
            idScan!.name.isNotEmpty &&
            !isScanningId,
        repName.trim().isNotEmpty && isMobileValid && repPhotoPath != null,
        cheque != null && chequeCopyPath != null && !isScanningChequeCopy,
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
    String? repMobileCountryCode,
    String? Function()? repPhotoPath,
    String? Function()? idFrontPath,
    String? Function()? idBackPath,
    EmiratesIdScan? Function()? frontIdScan,
    EmiratesIdScan? Function()? backIdScan,
    bool? isScanningId,
    Cheque? Function()? cheque,
    String? Function()? chequeCopyPath,
    bool? isScanningChequeCopy,
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
      repMobileCountryCode: repMobileCountryCode ?? this.repMobileCountryCode,
      repPhotoPath: repPhotoPath != null ? repPhotoPath() : this.repPhotoPath,
      idFrontPath: idFrontPath != null ? idFrontPath() : this.idFrontPath,
      idBackPath: idBackPath != null ? idBackPath() : this.idBackPath,
      frontIdScan: frontIdScan != null ? frontIdScan() : this.frontIdScan,
      backIdScan: backIdScan != null ? backIdScan() : this.backIdScan,
      isScanningId: isScanningId ?? this.isScanningId,
      cheque: cheque != null ? cheque() : this.cheque,
      chequeCopyPath: chequeCopyPath != null ? chequeCopyPath() : this.chequeCopyPath,
      isScanningChequeCopy: isScanningChequeCopy ?? this.isScanningChequeCopy,
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
        repMobileCountryCode,
        repPhotoPath,
        idFrontPath,
        idBackPath,
        frontIdScan,
        backIdScan,
        isScanningId,
        cheque,
        chequeCopyPath,
        isScanningChequeCopy,
        chequeScan,
        voucherPath,
        supportingDocPaths,
        consent,
        signaturePath,
      ];
}
