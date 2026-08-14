import 'package:shared_preferences/shared_preferences.dart';

/// Abstract key-value persistence contract. Kept here (rather than in a
/// feature's `domain`) because storage is used across features — auth
/// token, theme mode, onboarding flags, etc.
///
/// Depending on this interface (never [SharedPreferencesStorageService]
/// directly) is what lets it be swapped for a `hive`-backed implementation,
/// or a fake, without touching a single call site.
abstract class StorageService {
  Future<String?> getAuthToken();
  Future<void> saveAuthToken(String token);
  Future<void> clearAuthToken();

  Future<String?> getThemeMode();
  Future<void> saveThemeMode(String mode);

  Future<String?> getCachedUserJson();
  Future<void> saveCachedUserJson(String json);
  Future<void> clearCachedUserJson();
}

class SharedPreferencesStorageService implements StorageService {
  const SharedPreferencesStorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _authTokenKey = 'auth_token';
  static const _themeModeKey = 'theme_mode';
  static const _cachedUserKey = 'cached_user';

  @override
  Future<String?> getAuthToken() async => _prefs.getString(_authTokenKey);

  @override
  Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_authTokenKey, token);
  }

  @override
  Future<void> clearAuthToken() async {
    await _prefs.remove(_authTokenKey);
  }

  @override
  Future<String?> getThemeMode() async => _prefs.getString(_themeModeKey);

  @override
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  @override
  Future<String?> getCachedUserJson() async => _prefs.getString(_cachedUserKey);

  @override
  Future<void> saveCachedUserJson(String json) async {
    await _prefs.setString(_cachedUserKey, json);
  }

  @override
  Future<void> clearCachedUserJson() async {
    await _prefs.remove(_cachedUserKey);
  }
}
