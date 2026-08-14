import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Lightweight request/response logger, active only in debug builds by the
/// caller choosing whether to attach it (see DioClient).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log('--> ${options.method} ${options.uri}', name: 'DioClient');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '<-- ${response.statusCode} ${response.requestOptions.uri}',
      name: 'DioClient',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}',
      name: 'DioClient',
    );
    handler.next(err);
  }
}
