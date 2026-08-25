import '../../domain/entities/collection_attachment.dart';
import '../../domain/entities/collection_record.dart';

/// Data-layer representation of [CollectionRecord]. Hand-written `fromJson`
/// (no `json_serializable` codegen) matching the exact shape returned by
/// both `POST /cheques/{chequeId}/collection` (201) and
/// `GET /collections/{chequeId}` — same fields either way.
class CollectionRecordModel extends CollectionRecord {
  const CollectionRecordModel({
    required super.id,
    required super.chequeId,
    required super.chequeNumber,
    required super.vendorName,
    required super.amount,
    required super.repName,
    required super.timestamp,
    super.repMobile,
    super.emiratesId,
    super.nationality,
    super.expiry,
    super.collectorPhotoUrl,
    super.idFrontUrl,
    super.idBackUrl,
    super.chequePhotoUrl,
    super.signatureUrl,
    super.voucherUrl,
    super.supportingDocuments,
    super.newChequeStatus,
  });

  factory CollectionRecordModel.fromJson(Map<String, dynamic> json) => CollectionRecordModel(
    id: json['id'] as String,
    chequeId: json['chequeId'] as String,
    chequeNumber: json['chequeNumber'] as String,
    vendorName: json['supplierName'] as String,
    amount: (json['amount'] as num).toDouble(),
    repName: json['collectorName'] as String,
    repMobile: json['collectorMobile'] as String? ?? '',
    emiratesId: json['collectorEmiratesId'] as String? ?? '',
    nationality: json['collectorNationality'] as String? ?? '',
    expiry: json['collectorEidExpiryDate'] as String? ?? '',
    collectorPhotoUrl: json['collectorPhotoUrl'] as String?,
    idFrontUrl: json['emiratesIdFrontUrl'] as String?,
    idBackUrl: json['emiratesIdBackUrl'] as String?,
    chequePhotoUrl: json['chequePhotoUrl'] as String?,
    signatureUrl: json['signatureUrl'] as String?,
    voucherUrl: json['acknowledgementVoucherUrl'] as String?,
    supportingDocuments: (json['supportingDocuments'] as List<dynamic>? ?? [])
        .map(
          (doc) => CollectionAttachment(
            id: (doc as Map<String, dynamic>)['id'] as String,
            fileName: doc['fileName'] as String,
            url: doc['url'] as String,
          ),
        )
        .toList(),
    timestamp: DateTime.parse(json['collectedAt'] as String),
    newChequeStatus: json['newChequeStatus'] as String?,
  );
}
