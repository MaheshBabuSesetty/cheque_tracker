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
  Future<DataResult<User>> login({required String username, required String password}) async {
    // Deliberately no `networkInfo.isConnected` gate here: the remote
    // datasource already surfaces its own connectivity failures as a
    // `ServerException`/`NetworkException` below, so an upfront check would
    // just duplicate that without changing the outcome.
    try {
      final session = await remoteDataSource.login(username: username, password: password);
      await localDataSource.cacheSession(
        accessToken: session.accessToken,
        accessTokenExpiresAtUtc: session.accessTokenExpiresAtUtc,
        refreshToken: session.refreshToken,
        refreshTokenExpiresAtUtc: session.refreshTokenExpiresAtUtc,
        user: session.user,
      );
      return ResultSuccess(session.user);
    } on AuthException catch (e) {
      return ResultError(AuthFailure(e.message));
    } on RateLimitException catch (e) {
      return ResultError(RateLimitFailure(e.message));
    } on ValidationException catch (e) {
      return ResultError(ValidationFailure(e.fieldErrors, e.message));
    } on NetworkException catch (e) {
      return ResultError(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return ResultError(ServerFailure(e.message));
    } catch (_) {
      return const ResultError(UnexpectedFailure());
    }
  }

  @override
  Future<DataResult<void>> logout() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (await networkInfo.isConnected && refreshToken != null) {
        await remoteDataSource.logout(refreshToken: refreshToken);
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

      if (!await networkInfo.isConnected) {
        // Offline: trust the cache so a field agent can keep working
        // without connectivity — this is the whole reason the cache exists.
        return ResultSuccess(cached);
      }

      // Online: re-validate against the server rather than trusting a
      // locally-cached session unconditionally. A tampered/forged local
      // cache (e.g. on a rooted device) no longer grants access on its
      // own — the server has to agree the session is still valid. See the
      // security audit's F-5.
      try {
        final remoteUser = await remoteDataSource.getCurrentUser();
        return ResultSuccess(remoteUser);
      } on AuthException {
        // Server explicitly rejected the session — it really is invalid.
        await localDataSource.clearSession();
        return const ResultSuccess(null);
      } on ServerException {
        // Backend unreachable/erroring rather than rejecting the session —
        // fail open to the cache instead of locking the agent out over a
        // transient/backend-side issue.
        return ResultSuccess(cached);
      } on NetworkException {
        return ResultSuccess(cached);
      }
    } on CacheException {
      return const ResultSuccess(null);
    } catch (_) {
      return const ResultError(UnexpectedFailure());
    }
  }
}
