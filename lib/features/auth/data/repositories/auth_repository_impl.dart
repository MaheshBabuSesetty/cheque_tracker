import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// The only class allowed to know both "how auth data is fetched" (remote/
/// local datasources) and "what domain contract that satisfies"
/// ([AuthRepository]). Everything above this layer only ever sees the
/// abstraction.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<DataResult<User>> login({required String agentId, required String password}) async {
    // Deliberately no `networkInfo.isConnected` gate here: the datasource
    // wired in today (`MockAuthRemoteDataSource`) is local-only by design,
    // and a real remote implementation surfaces its own connectivity
    // failures as a `ServerException` below. Gating on connectivity here
    // would incorrectly block the mock's offline logins.
    try {
      final session = await remoteDataSource.login(agentId: agentId, password: password);
      await localDataSource.cacheSession(token: session.token, user: session.user);
      return ResultSuccess(session.user);
    } on AuthException catch (e) {
      return ResultError(AuthFailure(e.message));
    } on ServerException catch (e) {
      return ResultError(ServerFailure(e.message));
    } catch (_) {
      return const ResultError(UnexpectedFailure());
    }
  }

  @override
  Future<DataResult<void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }
      await localDataSource.clearSession();
      return const ResultSuccess(null);
    } catch (_) {
      return const ResultError(UnexpectedFailure());
    }
  }

  @override
  Future<DataResult<User?>> getCurrentUser() async {
    try {
      final cached = await localDataSource.getCachedUser();
      if (cached != null) return ResultSuccess(cached);

      if (!await networkInfo.isConnected) {
        return const ResultSuccess(null);
      }
      final remoteUser = await remoteDataSource.getCurrentUser();
      return ResultSuccess(remoteUser);
    } on CacheException {
      return const ResultSuccess(null);
    } on AuthException {
      return const ResultSuccess(null);
    } catch (_) {
      return const ResultError(UnexpectedFailure());
    }
  }
}
