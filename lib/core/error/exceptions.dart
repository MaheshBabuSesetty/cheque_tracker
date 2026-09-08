/// Exceptions thrown by the `data` layer (datasources). Repositories catch
/// these and map them to a [Failure] before returning to `domain`.
class ServerException implements Exception {
  const ServerException([this.message = 'Something went wrong on the server.']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'No cached data was found.']);

  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Invalid credentials.']);

  final String message;
}

/// A 401/network-unreachable case distinct from [ServerException] so
/// repositories can surface "no internet" rather than a generic server
/// error. Thrown by [ApiErrorParser] for connection/timeout `DioException`s.
class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection.']);

  final String message;
}

/// A role-gated endpoint (e.g. a VRM-only route hit by a non-VRM account)
/// rejected the request with 403 — distinct from [AuthException] so the UI
/// can say "not authorized" rather than "bad credentials".
class ForbiddenException implements Exception {
  const ForbiddenException([this.message = "You don't have permission to do that."]);

  final String message;
}

/// The per-IP rate limit on login/refresh was hit (429, empty body). Must
/// never be surfaced as an auth failure — the UI shows a "please wait" copy
/// with backoff instead.
class RateLimitException implements Exception {
  const RateLimitException([this.message = 'Too many attempts. Please wait a moment and try again.']);

  final String message;
}

/// A 400 `ValidationProblemDetails` response — field name to error messages.
class ValidationException implements Exception {
  const ValidationException(this.fieldErrors);

  final Map<String, List<String>> fieldErrors;

  String get message {
    final messages = fieldErrors.values.expand((v) => v);
    return messages.isEmpty ? 'Some fields need attention.' : messages.first;
  }
}
