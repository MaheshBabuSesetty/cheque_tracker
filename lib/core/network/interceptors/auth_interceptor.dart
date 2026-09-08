import 'package:dio/dio.dart';

import '../../session/session_events.dart';
import '../../../services/storage_service.dart';
import '../token_refresh_client.dart';

/// Attaches the persisted bearer access token to every outgoing request on
/// the authenticated [Dio] client, refreshing it first (proactively, or
/// reactively on a 401) via [TokenRefreshClient].
///
/// Never attached to login/refresh/logout/version-check — those run on a
/// separate [Dio] with no interceptor (see `UnauthenticatedDioClient`), so
/// there is no risk of this class's refresh logic ever recursing into
/// itself. Holds a reference to the very [Dio] instance it's attached to,
/// purely so a 401 retry can be re-issued through the same client (base
/// URL, timeouts, other interceptors) rather than a bare one.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._storageService, this._tokenRefreshClient, this._sessionEvents);

  final Dio _dio;
  final StorageService _storageService;
  final TokenRefreshClient _tokenRefreshClient;
  final SessionEvents _sessionEvents;

  /// Single-flight lock: concurrent requests that all discover an
  /// expired/rejected token await the same in-flight refresh instead of
  /// each calling `/auth/refresh` themselves — the API contract explicitly
  /// warns that reusing an already-consumed refresh token revokes every
  /// other active session.
  Future<bool>? _refreshInFlight;

  static const _proactiveRefreshWindow = Duration(seconds: 30);
  static const _retriedFlag = 'retriedAfterRefresh';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final expiresAt = await _storageService.getAccessTokenExpiresAtUtc();
    if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt.subtract(_proactiveRefreshWindow))) {
      await _refresh();
    }

    final token = await _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    if (err.response?.statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refreshed = await _refresh();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    try {
      final token = await _storageService.getAuthToken();
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $token';
      retryOptions.extra[_retriedFlag] = true;
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  /// Returns `true` if the session now has a valid access token (either it
  /// didn't need refreshing, or refresh succeeded); `false` if refresh was
  /// attempted and failed, in which case the session has already been
  /// cleared and [SessionEvents] notified.
  Future<bool> _refresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final result = await _tokenRefreshClient.refresh(refreshToken);
      // Overwrite atomically — never keep the old refresh token around
      // once a new one has been issued.
      await _storageService.saveAuthSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        accessTokenExpiresAtUtc: result.accessTokenExpiresAtUtc,
        refreshTokenExpiresAtUtc: result.refreshTokenExpiresAtUtc,
      );
      return true;
    } catch (_) {
      await _storageService.clearAuthSession();
      await _storageService.clearCachedUserJson();
      _sessionEvents.notifySessionExpired();
      return false;
    }
  }
}
