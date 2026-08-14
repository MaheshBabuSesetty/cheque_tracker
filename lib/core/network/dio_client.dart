import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Thin factory around [Dio] so the rest of the app depends on a single,
/// pre-configured client instead of constructing `Dio()` ad hoc.
class DioClient {
  DioClient(AuthInterceptor authInterceptor) : dio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            headers: const {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(authInterceptor);
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }
  }

  final Dio dio;
}
