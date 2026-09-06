import 'package:equatable/equatable.dart';

import 'collection_attachment.dart';

/// A recorded cheque collection, in the full shape returned by
/// `POST /cheques/{chequeId}/collection` (on success) and
/// `GET /collections/{chequeId}` — every instance that exists client-side
/// came from a real server round trip (there is no offline queue yet, see
/// the API integration plan's "known gaps"), so unlike the old mock-era
/// model there's no separate synced/pending status to track.
///
/// Every `*Url` field is a **relative** API path, not a local file path —
/// fetch it with the authenticated Dio client (see
/// `AuthenticatedNetworkImage`), never `Image.file`.
class CollectionRecord extends Equatable {
  const CollectionRecord({
    required this.id,
    required this.chequeId,
    required this.chequeNumber,
    required this.vendorName,
    required this.amount,
    required this.repName,
    required this.timestamp,
    this.currency = 'AED',
    this.repMobile = '',
    this.emiratesId = '',
    this.collectorPhotoUrl,
    this.idFrontUrl,
    this.idBackUrl,
    this.chequePhotoUrl,
    this.signatureUrl,
    this.voucherUrl,
    this.supportingDocuments = const [],
    this.newChequeStatus,
  });

  final String id;
  final String chequeId;
  final String chequeNumber;
  final String vendorName;
  final double amount;

  /// Every cheque is implicitly AED — there is no `currency` field on the
  /// wire, so this is always `'AED'`.
  final String currency;

  final String repName;
  final String repMobile;
  final String emiratesId;
  final String? collectorPhotoUrl;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? chequePhotoUrl;
  final String? signatureUrl;
  final String? voucherUrl;
  final List<CollectionAttachment> supportingDocuments;

  final DateTime timestamp;

  /// The cheque's status right after this submission — `'ISSUED'` on a
  /// normal successful collection.
  final String? newChequeStatus;

  @override
  List<Object?> get props => [
        id,
        chequeId,
        chequeNumber,
        vendorName,
        amount,
        currency,
        repName,
        repMobile,
        emiratesId,
        collectorPhotoUrl,
        idFrontUrl,
        idBackUrl,
        chequePhotoUrl,
        signatureUrl,
        voucherUrl,
        supportingDocuments,
        timestamp,
        newChequeStatus,
      ];
}
