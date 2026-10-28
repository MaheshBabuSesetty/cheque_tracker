import 'package:equatable/equatable.dart';

import '../../../cheques/domain/entities/cheque.dart';
import 'cheque_scan.dart';

/// Outcome of comparing the photographed leaf's MICR band against the
/// selected [Cheque]'s number — see [CollectedCheque.micrCheck].
enum ChequeMicrCheck {
  /// No photo yet, or it's still being scanned.
  pending,

  /// The MICR band was read and carries the selected cheque's number.
  matched,

  /// The MICR band was read but carries a different number.
  mismatched,

  /// No MICR band could be read off the photo at all.
  notDetected,
}

/// One cheque being handed over in a collection, together with its own
/// photo and the checks run on that photo. A vendor's representative can
/// collect several cheques in one visit, and every one needs its own photo,
/// so each lives in [CollectionDraft.cheques] as one of these.
class CollectedCheque extends Equatable {
  const CollectedCheque({
    required this.cheque,
    required this.photoPath,
    this.isScanning = false,
    this.scan,
    this.numberManuallyVerified = false,
    this.submitError,
    this.voucherPath,
  });

  /// The real, currently-SIGNED cheque (`GET /cheques?status=SIGNED`). Its
  /// number, amount and bank are server truth — only its id is submitted.
  final Cheque cheque;
  final String photoPath;

  /// True only while [photoPath] is being OCR'd — blocks [isDone] mid-scan,
  /// never surfaced as a rejection.
  final bool isScanning;

  /// The on-device OCR read of [photoPath], checked against [cheque]'s
  /// payee name — a non-blocking sanity check, see [scanWarnings].
  final ChequeScan? scan;

  /// The agent's own confirmation that the number printed on the leaf is
  /// [cheque]'s — the fallback when OCR couldn't confirm it from the MICR
  /// band (see [needsManualNumberCheck]). Reset whenever the photo changes,
  /// so a confirmation never carries over to a leaf the agent didn't check.
  final bool numberManuallyVerified;

  /// Why the server refused *this* cheque on the last submit (e.g. it is on
  /// hold), shown on its card until the agent removes or retakes it.
  final String? submitError;

  /// Optional acknowledgement voucher for this cheque alone. When null the
  /// cheque gets the draft's shared [CollectionDraft.voucherPath], if any.
  final String? voucherPath;

  /// Non-blocking sanity warning from [scan] against [cheque]'s vendor —
  /// [cheque] (not the scan) is what gets submitted, so this never gates
  /// [isDone].
  List<String> get scanWarnings => [
        if (scan?.nameMatched == false) "Couldn't find this vendor's name on the photographed cheque.",
      ];

  /// Whether the photographed leaf's MICR band confirms [cheque]'s number.
  /// Leading zeros are ignored on both sides: the band is zero-padded to six
  /// digits, the number on file often isn't.
  ChequeMicrCheck get micrCheck {
    if (isScanning) return ChequeMicrCheck.pending;
    // A scan that threw (null) is treated the same as a band that wasn't
    // read — either way nothing machine-confirmed the number.
    final micr = scan?.micrChequeNumber;
    if (micr == null || micr.isEmpty) return ChequeMicrCheck.notDetected;
    String normalize(String n) => n.trim().toUpperCase().replaceFirst(RegExp(r'^0+'), '');
    return normalize(micr) == normalize(cheque.chequeNumber) ? ChequeMicrCheck.matched : ChequeMicrCheck.mismatched;
  }

  /// True when OCR couldn't confirm the cheque number from the MICR band,
  /// so the agent has to check it by eye before this cheque counts as done.
  bool get needsManualNumberCheck =>
      micrCheck == ChequeMicrCheck.notDetected || micrCheck == ChequeMicrCheck.mismatched;

  /// Photo taken, scan finished, and the number confirmed (by MICR or by eye).
  bool get isDone => !isScanning && (!needsManualNumberCheck || numberManuallyVerified);

  CollectedCheque copyWith({
    String? photoPath,
    bool? isScanning,
    ChequeScan? Function()? scan,
    bool? numberManuallyVerified,
    String? Function()? submitError,
    String? Function()? voucherPath,
  }) {
    return CollectedCheque(
      cheque: cheque,
      photoPath: photoPath ?? this.photoPath,
      isScanning: isScanning ?? this.isScanning,
      scan: scan != null ? scan() : this.scan,
      numberManuallyVerified: numberManuallyVerified ?? this.numberManuallyVerified,
      submitError: submitError != null ? submitError() : this.submitError,
      voucherPath: voucherPath != null ? voucherPath() : this.voucherPath,
    );
  }

  @override
  List<Object?> get props => [cheque, photoPath, isScanning, scan, numberManuallyVerified, submitError, voucherPath];
}
