import '../../../../core/utils/result.dart';
import '../entities/user.dart';

/// Abstraction the `presentation` layer depends on. `data/repositories/
/// auth_repository_impl.dart` is the only concrete implementation known to
/// the DI composition root — presentation code never imports it directly
/// (Dependency Inversion), and a fake implementation can be substituted
/// wholesale in tests (Liskov Substitution) via `mocktail`.
abstract class AuthRepository {
  /// [rememberDevice] controls whether the session survives a full app
  /// restart: `false` still caches it for the remainder of this run (every
  /// authenticated request reads the token from storage), but
  /// [getCurrentUser] wipes it the next time the app cold-starts.
  Future<DataResult<User>> login({
    required String username,
    required String password,
    required bool rememberDevice,
  });

  /// Runs the Microsoft Entra ID sign-in flow and exchanges the result for
  /// a session, same as [login] but via SSO. Returns a `null`-data success
  /// (not an error) if the agent cancelled the provider's sign-in UI —
  /// callers distinguish "cancelled" from "failed" the same way they'd
  /// distinguish an empty form submit from a rejected one.
  Future<DataResult<User?>> loginWithSso({required bool rememberDevice});
  Future<DataResult<void>> logout();
  Future<DataResult<User?>> getCurrentUser();
}
