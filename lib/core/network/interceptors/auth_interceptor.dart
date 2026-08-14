import 'package:dio/dio.dart';

import '../../../services/storage_service.dart';

/// Attaches the persisted bearer token (if any) to every outgoing request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storageService);

  final StorageService _storageService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
