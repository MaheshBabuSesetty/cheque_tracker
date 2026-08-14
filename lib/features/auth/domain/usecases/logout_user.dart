import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class LogoutUser {
  const LogoutUser(this._repository);

  final AuthRepository _repository;

  Future<DataResult<void>> call() => _repository.logout();
}
