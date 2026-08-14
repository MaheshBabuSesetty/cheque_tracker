import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/collection_record.dart';

part 'collection_record_model.g.dart';

/// Data-layer representation of [CollectionRecord], with JSON
/// (de)serialization for local persistence. `CollectionStatus` and
/// `DateTime` round-trip via json_serializable's built-in enum-name and
/// ISO-8601 handling — no custom converters needed.
@JsonSerializable()
class CollectionRecordModel extends CollectionRecord {
  const CollectionRecordModel({
    required super.id,
    required super.ref,
    required super.vendorName,
    required super.repName,
    required super.repMobile,
    required super.emiratesId,
    required super.nationality,
    required super.expiry,
    required super.chequeNumber,
    required super.amount,
    required super.currency,
    required super.status,
    required super.timestamp,
    super.repPhotoPath,
    super.idFrontPath,
    super.idBackPath,
    super.chequeCopyPath,
    super.signaturePath,
    super.voucherPath,
    super.supportingDocPaths,
  });

  factory CollectionRecordModel.fromJson(Map<String, dynamic> json) => _$CollectionRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionRecordModelToJson(this);

  factory CollectionRecordModel.fromEntity(CollectionRecord record) => CollectionRecordModel(
        id: record.id,
        ref: record.ref,
        vendorName: record.vendorName,
        repName: record.repName,
        repMobile: record.repMobile,
        emiratesId: record.emiratesId,
        nationality: record.nationality,
        expiry: record.expiry,
        chequeNumber: record.chequeNumber,
        amount: record.amount,
        currency: record.currency,
        status: record.status,
        timestamp: record.timestamp,
        repPhotoPath: record.repPhotoPath,
        idFrontPath: record.idFrontPath,
        idBackPath: record.idBackPath,
        chequeCopyPath: record.chequeCopyPath,
        signaturePath: record.signaturePath,
        voucherPath: record.voucherPath,
        supportingDocPaths: record.supportingDocPaths,
      );
}
