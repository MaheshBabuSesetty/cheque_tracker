import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';

/// Result of a successful `POST /auth/refresh` call.
class TokenRefreshResult {
  const TokenRefreshResult({
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAtUtc;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;
}

/// A minimal, `core`-only client for `POST /auth/refresh`, used exclusively
/// by [AuthInterceptor]. Kept separate from the auth feature's
/// `AuthRemoteDataSource` so `core/network` never has to depend on a
/// feature module — the auth feature depends on `core`, never the reverse.
/// Must be given the *unauthenticated* [Dio] (no [AuthInterceptor] attached)
/// so a refresh call can never itself recurse into refresh-on-401 logic.
class TokenRefreshClient {
  const TokenRefreshClient(this._dio);

  final Dio _dio;

  Future<TokenRefreshResult> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );
    final data = response.data!;
    return TokenRefreshResult(
      accessToken: data['accessToken'] as String,
      accessTokenExpiresAtUtc: DateTime.parse(data['accessTokenExpiresAtUtc'] as String),
      refreshToken: data['refreshToken'] as String,
      refreshTokenExpiresAtUtc: DateTime.parse(data['refreshTokenExpiresAtUtc'] as String),
    );
  }
}
