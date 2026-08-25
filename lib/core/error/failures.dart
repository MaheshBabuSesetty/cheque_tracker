import 'package:equatable/equatable.dart';

/// Domain/presentation-facing error type. Repositories translate the
/// [Exception]s thrown by data sources into a [Failure] so that the domain
/// layer never depends on `dio`, platform channels, or any other package.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No cached data was found.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid credentials.']);
}

/// A role-gated endpoint rejected the request (403) — distinct from
/// [AuthFailure] so the UI can say "not authorized" rather than "bad
/// credentials".
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = "You don't have permission to do that."]);
}

/// The per-IP rate limit on login/refresh was hit (429). Must never be
/// shown as an auth failure.
class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Too many attempts. Please wait a moment and try again.']);
}

/// A 400 model-validation response, field name to error messages.
class ValidationFailure extends Failure {
  const ValidationFailure(this.fieldErrors, [super.message = 'Some fields need attention.']);

  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
