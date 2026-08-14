import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../services/storage_service.dart';
import '../models/user_model.dart';

/// Wraps the generic [StorageService] with auth-specific semantics: a
/// "session" is a token plus the user it belongs to, cached together so
/// `getCurrentUser()` can work offline once a user has logged in.
abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheSession({required String token, required UserModel user});
  Future<void> clearSession();
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
  Future<void> cacheSession({required String token, required UserModel user}) async {
    await _storageService.saveAuthToken(token);
    await _storageService.saveCachedUserJson(jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearSession() async {
    await _storageService.clearAuthToken();
    await _storageService.clearCachedUserJson();
  }
}
