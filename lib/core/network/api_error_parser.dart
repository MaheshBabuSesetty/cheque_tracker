import 'package:dio/dio.dart';

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
