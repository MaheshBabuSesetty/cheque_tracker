import '../../../../core/utils/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Single-responsibility usecase: authenticate via the Microsoft Entra ID
/// SSO flow instead of a username/password. Kept separate from [LoginUser]
/// so each credential path can change independently.
class LoginWithSso {
  const LoginWithSso(this._repository);

  final AuthRepository _repository;

  Future<DataResult<User?>> call({required bool rememberDevice}) =>
      _repository.loginWithSso(rememberDevice: rememberDevice);
}
