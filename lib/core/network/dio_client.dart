import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../session/session_events.dart';
import '../../services/storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'token_refresh_client.dart';

/// Thin factory around [Dio] so the rest of the app depends on a single,
/// pre-configured, authenticated client instead of constructing `Dio()` ad
/// hoc. [AuthInterceptor] is constructed after `dio` so it can hold a
/// reference back to this exact instance (needed to re-issue a request
/// after a 401 refresh).
class DioClient {
  DioClient(StorageService storageService, TokenRefreshClient tokenRefreshClient, SessionEvents sessionEvents)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.add(AuthInterceptor(dio, storageService, tokenRefreshClient, sessionEvents));
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
  }

  final Dio dio;
}
