import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/vendor.dart';
import '../models/vendor_model.dart';

/// Caches the vendor master list on-device so the vendor picker (step 1 of
/// a collection) still works offline after the first sync, rather than
/// requiring a live `GET /vendors/available-for-collection` every time it's
/// opened — mirrors the JSON-in-`SharedPreferences` convention used
/// elsewhere in this app (see `AuthLocalDataSource`), just at the list
/// level instead of a single object.
abstract class VendorLocalDataSource {
  /// Empty list if nothing has been cached yet — never `null`, since "no
  /// vendors cached" isn't an error state, just an unsynced one.
  Future<List<VendorModel>> getCachedVendors();

  Future<void> cacheVendors(List<Vendor> vendors);
}

class VendorLocalDataSourceImpl implements VendorLocalDataSource {
  const VendorLocalDataSourceImpl(this._prefs);

  static const _storageKey = 'vendor_master_v1';

  final SharedPreferences _prefs;

  @override
  Future<List<VendorModel>> getCachedVendors() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((json) => VendorModel.fromJson(json as Map<String, dynamic>)).toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> cacheVendors(List<Vendor> vendors) async {
    final encoded = jsonEncode(
      vendors.map((v) => VendorModel(id: v.id, name: v.name, code: v.code, trn: v.trn).toJson()).toList(),
    );
    await _prefs.setString(_storageKey, encoded);
  }
}
