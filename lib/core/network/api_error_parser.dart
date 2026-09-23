import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/exceptions.dart';

/// Turns a [DioException] into one of the typed exceptions in
/// `core/error/exceptions.dart`, per the API contract's two error shapes:
///
/// - Model validation (400, `ValidationProblemDetails`): read `errors`.
/// - Business rule (401/403/404/409 and some 400s): read `message`.
///
/// Every remote datasource should funnel its `catch (DioException e)`
/// through [ApiErrorParser.parse] rather than hand-rolling status checks, so
/// the mapping stays consistent across every endpoint.
class ApiErrorParser {
  const ApiErrorParser._();

  static Exception parse(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // "No internet connection" lumps together every connection-level
        // failure — actual offline, DNS failure, TLS/cert-pinning rejection,
        // a WAF/proxy reset, a slow backend past the timeout — with no way
        // to tell them apart afterwards. Not gated on kDebugMode: this is
        // exactly the kind of failure that shows up only in the field on a
        // release build, so it needs to be visible via `adb logcat` /
        // Xcode console there too. Logs the path and the underlying cause
        // only — never the request body/headers, which is where a bearer
        // token or an SSO idToken would be.
        debugPrint(
          'ApiErrorParser: ${error.type} on ${error.requestOptions.method} '
          '${error.requestOptions.path} — ${error.error ?? error.message}',
        );
        return const NetworkException();
      default:
        break;
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode == 429) {
      return const RateLimitException();
    }

    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map) {
        final fieldErrors = errors.map(
          (key, value) => MapEntry(
            key.toString(),
            value is List ? value.map((e) => e.toString()).toList() : <String>[value.toString()],
          ),
        );
        return ValidationException(Map<String, List<String>>.from(fieldErrors));
      }

      final message = data['message'];
      if (message is String) {
        switch (statusCode) {
          case 401:
            return AuthException(message);
          case 403:
            return ForbiddenException(message);
          default:
            return ServerException(message);
        }
      }
    }

    switch (statusCode) {
      case 401:
        return const AuthException();
      case 403:
        return const ForbiddenException();
      default:
        return const ServerException();
    }
  }
}
