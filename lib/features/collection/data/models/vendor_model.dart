import '../../domain/entities/vendor.dart';

/// Data-layer representation of [Vendor] for `GET
/// /vendors/available-for-collection`. Hand-written `fromJson` (no
/// `json_serializable` codegen) since the shape is a flat 4 fields with no
/// nesting.
class VendorModel extends Vendor {
  const VendorModel({required super.id, required super.name, super.code, super.trn});

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String?,
    trn: json['trn'] as String?,
  );

  /// For the local vendor-master cache (`VendorLocalDataSource`) — this
  /// app never sends a vendor back to the server, so this exists purely
  /// for round-tripping through `SharedPreferences`.
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'code': code, 'trn': trn};
}
