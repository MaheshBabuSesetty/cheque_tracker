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
