import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../services/storage_service.dart';
import '../models/user_model.dart';

/// Wraps the generic [StorageService] with auth-specific semantics: a
/// "session" is the access/refresh token pair (plus expiries) and the user
/// it belongs to, cached together so `getCurrentUser()` can work offline
/// once a user has logged in.
abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheSession({
    required String accessToken,
    required DateTime accessTokenExpiresAtUtc,
    required String refreshToken,
    required DateTime refreshTokenExpiresAtUtc,
    required UserModel user,
  });
  Future<String?> getRefreshToken();
  Future<void> clearSession();

  Future<bool?> getRememberDevice();
  Future<void> saveRememberDevice(bool remember);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storageService);

  final StorageService _storageService;

  @override
  Future<UserModel?> getCachedUser() async {
    final json = await _storageService.getCachedUserJson();
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on FormatException {
      throw const CacheException();
    }
  }

  @override
  Future<void> cacheSession({
    required String accessToken,
    required DateTime accessTokenExpiresAtUtc,
    required String refreshToken,
    required DateTime refreshTokenExpiresAtUtc,
    required UserModel user,
  }) async {
    await _storageService.saveAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAtUtc: accessTokenExpiresAtUtc,
      refreshTokenExpiresAtUtc: refreshTokenExpiresAtUtc,
    );
    await _storageService.saveCachedUserJson(jsonEncode(user.toJson()));
  }

  @override
  Future<String?> getRefreshToken() => _storageService.getRefreshToken();

  @override
  Future<void> clearSession() async {
    await _storageService.clearAuthSession();
    await _storageService.clearCachedUserJson();
  }

  @override
  Future<bool?> getRememberDevice() => _storageService.getRememberDevice();

  @override
  Future<void> saveRememberDevice(bool remember) => _storageService.saveRememberDevice(remember);
}
