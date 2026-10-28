import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';

/// Whether the server has multi-cheque collection switched on
/// (`GET /app/version` → `features.bulkCollection`). The switch is
/// server-wide, not per account.
///
/// Anything short of a clear `true` — flag false, missing, or the request
/// failing — reads as "off", so the app falls back to collecting one cheque
/// at a time, which works on every server. A failed lookup isn't cached, so
/// the next submit asks again.
class BulkCollectionFlag {
  BulkCollectionFlag(this._dio);

  final Dio _dio;
  bool? _enabled;

  Future<bool> isEnabled() async {
    final cached = _enabled;
    if (cached != null) return cached;
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.appVersion);
      final features = response.data?['features'];
      return _enabled = features is Map && features['bulkCollection'] == true;
    } catch (_) {
      return false;
    }
  }

  /// The server answered `BULK_COLLECTION_DISABLED`: the switch was turned
  /// off after the flag was read.
  void markDisabled() => _enabled = false;
}
