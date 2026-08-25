import '../../domain/entities/cheque.dart';

/// Data-layer representation of [Cheque]. Hand-written `fromJson` (no
/// `json_serializable` codegen) — the shape is flat and only ever
/// deserialized, never sent back to the server.
class ChequeModel extends Cheque {
  const ChequeModel({
    required super.id,
    required super.serialNumber,
    required super.vendorId,
    required super.supplierName,
    required super.chequeType,
    required super.paymentType,
    required super.bank,
    required super.chequeNumber,
    required super.chequeDate,
    required super.amount,
    required super.signedBy,
    required super.status,
    super.reference,
    super.poNumber,
    super.issuedDate,
    super.prepDate,
    super.receivedDate,
    super.siteTeamApprovalReceived,
    super.accountsTeamApprovalReceived,
    super.collectedBy,
    super.collectorMobile,
    super.canMarkSigned,
    super.canMarkIssued,
    super.canCancel,
    super.createdAt,
    super.createdByName,
    super.updatedAt,
    super.updatedByName,
  });

  /// Covers both the list-item shape (`GET /cheques`) and the richer
  /// detail shape (`GET /cheques/{id}`) — fields absent from the list
  /// response simply aren't in [json], so they fall back to `null`.
  factory ChequeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) => value is String ? DateTime.tryParse(value) : null;

    return ChequeModel(
      id: json['id'] as String,
      serialNumber: json['serialNumber'] as int,
      vendorId: json['vendorId'] as String,
      supplierName: json['supplierName'] as String,
      chequeType: json['chequeType'] as String,
      paymentType: json['paymentType'] as String,
      bank: json['bank'] as String,
      chequeNumber: json['chequeNumber'] as String,
      chequeDate: DateTime.parse(json['chequeDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      signedBy: json['signedBy'] as String,
      status: json['status'] as String,
      reference: json['reference'] as String?,
      poNumber: json['poNumber'] as String?,
      issuedDate: parseDate(json['issuedDate']),
      prepDate: parseDate(json['prepDate']),
      receivedDate: parseDate(json['receivedDate']),
      siteTeamApprovalReceived: json['siteTeamApprovalReceived'] as bool?,
      accountsTeamApprovalReceived: json['accountsTeamApprovalReceived'] as bool?,
      collectedBy: json['collectedBy'] as String?,
      collectorMobile: json['collectorMobile'] as String?,
      canMarkSigned: json['canMarkSigned'] as bool? ?? false,
      canMarkIssued: json['canMarkIssued'] as bool? ?? false,
      canCancel: json['canCancel'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      createdByName: json['createdByName'] as String?,
      updatedAt: parseDate(json['updatedAt']),
      updatedByName: json['updatedByName'] as String?,
    );
  }
}
