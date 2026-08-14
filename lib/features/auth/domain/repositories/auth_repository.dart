import '../../../../core/utils/result.dart';
import '../entities/user.dart';

/// Abstraction the `presentation` layer depends on. `data/repositories/
/// auth_repository_impl.dart` is the only concrete implementation known to
/// the DI composition root — presentation code never imports it directly
/// (Dependency Inversion), and a fake implementation can be substituted
/// wholesale in tests (Liskov Substitution) via `mocktail`.
abstract class AuthRepository {
  Future<DataResult<User>> login({required String agentId, required String password});
  Future<DataResult<void>> logout();
  Future<DataResult<User?>> getCurrentUser();
}
