// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionRecordModel _$CollectionRecordModelFromJson(
  Map<String, dynamic> json,
) => CollectionRecordModel(
  id: json['id'] as String,
  ref: json['ref'] as String,
  vendorName: json['vendorName'] as String,
  repName: json['repName'] as String,
  repMobile: json['repMobile'] as String,
  emiratesId: json['emiratesId'] as String,
  nationality: json['nationality'] as String,
  expiry: json['expiry'] as String,
  chequeNumber: json['chequeNumber'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  status: $enumDecode(_$CollectionStatusEnumMap, json['status']),
  timestamp: DateTime.parse(json['timestamp'] as String),
  repPhotoPath: json['repPhotoPath'] as String?,
  idFrontPath: json['idFrontPath'] as String?,
  idBackPath: json['idBackPath'] as String?,
  chequeCopyPath: json['chequeCopyPath'] as String?,
  signaturePath: json['signaturePath'] as String?,
  voucherPath: json['voucherPath'] as String?,
  supportingDocPaths:
      (json['supportingDocPaths'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$CollectionRecordModelToJson(
  CollectionRecordModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'ref': instance.ref,
  'vendorName': instance.vendorName,
  'repName': instance.repName,
  'repMobile': instance.repMobile,
  'emiratesId': instance.emiratesId,
  'nationality': instance.nationality,
  'expiry': instance.expiry,
  'chequeNumber': instance.chequeNumber,
  'amount': instance.amount,
  'currency': instance.currency,
  'status': _$CollectionStatusEnumMap[instance.status]!,
  'timestamp': instance.timestamp.toIso8601String(),
  'repPhotoPath': instance.repPhotoPath,
  'idFrontPath': instance.idFrontPath,
  'idBackPath': instance.idBackPath,
  'chequeCopyPath': instance.chequeCopyPath,
  'signaturePath': instance.signaturePath,
  'voucherPath': instance.voucherPath,
  'supportingDocPaths': instance.supportingDocPaths,
};

const _$CollectionStatusEnumMap = {
  CollectionStatus.synced: 'synced',
  CollectionStatus.pending: 'pending',
};
