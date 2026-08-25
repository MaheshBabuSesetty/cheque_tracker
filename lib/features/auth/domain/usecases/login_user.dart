import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Single-responsibility usecase: authenticate with the field agent's
/// username and password. Kept separate from [GetCurrentUser]/[LogoutUser]
/// so each has one reason to change and can be unit-tested in isolation.
class LoginUser {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  Future<DataResult<User>> call({required String username, required String password}) {
    return _repository.login(username: username, password: password);
  }
}
