import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import 'certificate_pinning.dart';
import 'interceptors/logging_interceptor.dart';

/// A [Dio] instance with no [AuthInterceptor] attached, for the four routes
/// that never carry (or need) a bearer token and must never trigger a
/// refresh-on-401 loop: login, refresh, logout, and the app version check.
/// Kept as a separate client rather than a per-request header override so
/// there's no risk of the auth interceptor's refresh logic ever firing for
/// these calls.
class UnauthenticatedDioClient {
  UnauthenticatedDioClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    configureCertificatePinning(dio);
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
  }

  final Dio dio;
}
