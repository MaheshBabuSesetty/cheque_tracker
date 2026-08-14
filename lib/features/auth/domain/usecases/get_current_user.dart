import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Used by the splash screen to decide whether to route to login or home.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<DataResult<User?>> call() => _repository.getCurrentUser();
}
