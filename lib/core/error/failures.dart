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

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred.']);
}
