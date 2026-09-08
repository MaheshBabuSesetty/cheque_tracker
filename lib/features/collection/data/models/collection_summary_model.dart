import '../../domain/entities/collection_summary.dart';

class CollectionSummaryModel extends CollectionSummary {
  const CollectionSummaryModel({
    required super.chequeId,
    required super.vendorName,
    required super.chequeNumber,
    required super.repName,
    required super.repMobile,
    required super.timestamp,
  });

  factory CollectionSummaryModel.fromJson(Map<String, dynamic> json) => CollectionSummaryModel(
    chequeId: json['chequeId'] as String,
    vendorName: json['supplierName'] as String,
    chequeNumber: json['chequeNumber'] as String,
    repName: json['collectorName'] as String,
    repMobile: json['collectorMobile'] as String? ?? '',
    timestamp: DateTime.parse(json['collectedAt'] as String),
  );
}
