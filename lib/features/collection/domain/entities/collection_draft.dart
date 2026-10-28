import 'package:equatable/equatable.dart';

import '../../../../core/utils/phone_country_codes.dart';
import 'collected_cheque.dart';
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
    this.idFrontPath,
    this.idBackPath,
    this.frontIdScan,
    this.backIdScan,
    this.isScanningId = false,
    this.cheques = const [],
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

  final String? idFrontPath;
  final String? idBackPath;

  /// Raw per-side OCR results — kept separate rather than merged eagerly
  /// so [idScan] can always prefer the front's reading of a field over the
  /// back's, regardless of which side was captured/rescanned last.
  final EmiratesIdScan? frontIdScan;
  final EmiratesIdScan? backIdScan;
  final bool isScanningId;

  /// Every cheque being collected in this visit, each with its own photo
  /// (see [CollectedCheque]). A cheque only enters this list once its photo
  /// has been captured, so "one photo per cheque" holds by construction.
  final List<CollectedCheque> cheques;

  /// Both fully optional — step 5 ("Voucher & documents") never appears in
  /// [stepsDone]/[missingStepNames], so neither field ever blocks Submit.
  final String? voucherPath;
  final List<String> supportingDocPaths;

  final bool consent;

  /// Populated as soon as the agent taps "Use signature" in the signature
  /// sheet (see `SignatureSheet`), not deferred to submit time — so step-6
  /// completion is judged directly on this being non-null.
  final String? signaturePath;

  /// Server limit on cheques per request.
  static const maxCheques = 25;

  static const stepNames = ['vendor', 'Emirates ID', 'representative details', 'a signed cheque with its photo', 'consent', 'signature'];

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

  /// Sum of every selected cheque's amount.
  double get amountValue => cheques.fold(0, (sum, c) => sum + c.cheque.amount);

  /// One flag per numbered step on the collect screen, in display order.
  /// Step 4 ("Cheques") requires at least one real SIGNED cheque, and for
  /// every one its own photo plus either a MICR read confirming its number
  /// or the agent's manual confirmation ([CollectedCheque.isDone]). The
  /// vendor-name check behind [CollectedCheque.scanWarnings] stays
  /// non-blocking.
  List<bool> get stepsDone => [
        vendor != null,
        idFrontPath != null &&
            idBackPath != null &&
            idScan != null &&
            idScan!.idNumber.isNotEmpty &&
            idScan!.name.isNotEmpty &&
            !isScanningId,
        repName.trim().isNotEmpty && isMobileValid,
        cheques.isNotEmpty && cheques.every((c) => c.isDone),
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
    String? Function()? idFrontPath,
    String? Function()? idBackPath,
    EmiratesIdScan? Function()? frontIdScan,
    EmiratesIdScan? Function()? backIdScan,
    bool? isScanningId,
    List<CollectedCheque>? cheques,
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
      idFrontPath: idFrontPath != null ? idFrontPath() : this.idFrontPath,
      idBackPath: idBackPath != null ? idBackPath() : this.idBackPath,
      frontIdScan: frontIdScan != null ? frontIdScan() : this.frontIdScan,
      backIdScan: backIdScan != null ? backIdScan() : this.backIdScan,
      isScanningId: isScanningId ?? this.isScanningId,
      cheques: cheques ?? this.cheques,
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
        idFrontPath,
        idBackPath,
        frontIdScan,
        backIdScan,
        isScanningId,
        cheques,
        voucherPath,
        supportingDocPaths,
        consent,
        signaturePath,
      ];
}
