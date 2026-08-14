import 'package:equatable/equatable.dart';

enum CollectionStatus {
  synced,
  pending;

  String get label => switch (this) { CollectionStatus.synced => 'Synced', CollectionStatus.pending => 'Pending' };
}

/// A submitted cheque collection — the record shown in the transactions
/// list/detail and, eventually, pushed to the web application tracker.
///
/// Image fields are on-device file paths (populated by `ImageCaptureService`
/// and the signature pad), not raw bytes — keeps records small to persist
/// and mirrors how a real mobile app would reference captured media.
class CollectionRecord extends Equatable {
  const CollectionRecord({
    required this.id,
    required this.ref,
    required this.vendorName,
    required this.repName,
    required this.repMobile,
    required this.emiratesId,
    required this.nationality,
    required this.expiry,
    required this.chequeNumber,
    required this.amount,
    this.currency = 'AED',
    required this.status,
    required this.timestamp,
    this.repPhotoPath,
    this.idFrontPath,
    this.idBackPath,
    this.chequeCopyPath,
    this.signaturePath,
    this.voucherPath,
    this.supportingDocPaths = const [],
  });

  final String id;
  final String ref;
  final String vendorName;
  final String repName;
  final String repMobile;
  final String emiratesId;
  final String nationality;
  final String expiry;
  final String chequeNumber;
  final double amount;

  /// Only 'AED' or 'USD' — anything else is rejected before submission
  /// (see `ChequeScan.accepted`).
  final String currency;
  final CollectionStatus status;
  final DateTime timestamp;

  final String? repPhotoPath;
  final String? idFrontPath;
  final String? idBackPath;
  final String? chequeCopyPath;
  final String? signaturePath;

  /// Optional payment voucher photo and any extra supporting documents
  /// (invoices, delivery notes, …) attached from the optional step 5 —
  /// both may be absent since neither is required to submit.
  final String? voucherPath;
  final List<String> supportingDocPaths;

  @override
  List<Object?> get props => [
        id,
        ref,
        vendorName,
        repName,
        repMobile,
        emiratesId,
        nationality,
        expiry,
        chequeNumber,
        amount,
        currency,
        status,
        timestamp,
        repPhotoPath,
        idFrontPath,
        idBackPath,
        chequeCopyPath,
        signaturePath,
        voucherPath,
        supportingDocPaths,
      ];
}
