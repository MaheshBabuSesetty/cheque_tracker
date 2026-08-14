import '../error/failures.dart';

/// Lightweight `Either`-style result so usecases/repositories can return
/// success-or-[Failure] without pulling in a functional-programming
/// package. Exhaustive `switch` (Dart 3 sealed classes) keeps callers
/// honest about handling both branches.
sealed class DataResult<T> {
  const DataResult();
}

class ResultSuccess<T> extends DataResult<T> {
  const ResultSuccess(this.data);
  final T data;
}

class ResultError<T> extends DataResult<T> {
  const ResultError(this.failure);
  final Failure failure;
}
