import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract key-value persistence contract. Kept here (rather than in a
/// feature's `domain`) because storage is used across features — auth
/// token, theme mode, onboarding flags, etc.
///
/// Depending on this interface (never a concrete implementation directly)
/// is what lets it be swapped for a different backing store, or a fake,
/// without touching a single call site.
abstract class StorageService {
  Future<String?> getAuthToken();
  Future<void> saveAuthToken(String token);
  Future<void> clearAuthToken();

  /// Persists the access token, refresh token, and both expiries as one
  /// atomic write — the API contract calls out that keeping two copies of
  /// "the current refresh token" anywhere on the device is a hazard (reuse
  /// of a stale one revokes every other active session), so every write of
  /// the pair must go through here rather than through separate calls.
  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAtUtc,
    required DateTime refreshTokenExpiresAtUtc,
  });
  Future<String?> getRefreshToken();
  Future<DateTime?> getAccessTokenExpiresAtUtc();
  Future<DateTime?> getRefreshTokenExpiresAtUtc();
  Future<void> clearAuthSession();

  Future<String?> getThemeMode();
  Future<void> saveThemeMode(String mode);

  /// Whether the agent opted in to "Remember this device" at their last
  /// login — `null` if they've never logged in on this install (or logged
  /// in before this preference existed). Read back once at app cold start
  /// ([AuthRepositoryImpl.getCurrentUser]) to decide whether the persisted
  /// session should still be honored or wiped, forcing a fresh sign-in.
  Future<bool?> getRememberDevice();
  Future<void> saveRememberDevice(bool remember);

  Future<String?> getCachedUserJson();
  Future<void> saveCachedUserJson(String json);
  Future<void> clearCachedUserJson();
}

/// The auth token and cached user carry the session and, once collections
/// sync, personal data derived from it — both go through [FlutterSecureStorage]
/// (Keystore-backed on Android, Keychain-backed on iOS) rather than plaintext
/// prefs. Theme mode has no confidentiality requirement, so it stays in
/// [SharedPreferences].
class SecureStorageService implements StorageService {
  const SecureStorageService(this._secureStorage, this._prefs);

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _accessTokenExpiryKey = 'access_token_expires_at_utc';
  static const _refreshTokenExpiryKey = 'refresh_token_expires_at_utc';
  static const _themeModeKey = 'theme_mode';
  static const _cachedUserKey = 'cached_user';
  static const _rememberDeviceKey = 'remember_device';

  @override
  Future<String?> getAuthToken() => _secureStorage.read(key: _authTokenKey);

  @override
  Future<void> saveAuthToken(String token) => _secureStorage.write(key: _authTokenKey, value: token);

  @override
  Future<void> clearAuthToken() => _secureStorage.delete(key: _authTokenKey);

  @override
  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAtUtc,
    required DateTime refreshTokenExpiresAtUtc,
  }) => Future.wait([
    _secureStorage.write(key: _authTokenKey, value: accessToken),
    _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    _secureStorage.write(key: _accessTokenExpiryKey, value: accessTokenExpiresAtUtc.toIso8601String()),
    _secureStorage.write(key: _refreshTokenExpiryKey, value: refreshTokenExpiresAtUtc.toIso8601String()),
  ]);

  @override
  Future<String?> getRefreshToken() => _secureStorage.read(key: _refreshTokenKey);

  @override
  Future<DateTime?> getAccessTokenExpiresAtUtc() async {
    final value = await _secureStorage.read(key: _accessTokenExpiryKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<DateTime?> getRefreshTokenExpiresAtUtc() async {
    final value = await _secureStorage.read(key: _refreshTokenExpiryKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> clearAuthSession() => Future.wait([
    _secureStorage.delete(key: _authTokenKey),
    _secureStorage.delete(key: _refreshTokenKey),
    _secureStorage.delete(key: _accessTokenExpiryKey),
    _secureStorage.delete(key: _refreshTokenExpiryKey),
  ]);

  @override
  Future<String?> getThemeMode() async => _prefs.getString(_themeModeKey);

  @override
  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  @override
  Future<bool?> getRememberDevice() async => _prefs.getBool(_rememberDeviceKey);

  @override
  Future<void> saveRememberDevice(bool remember) async {
    await _prefs.setBool(_rememberDeviceKey, remember);
  }

  @override
  Future<String?> getCachedUserJson() => _secureStorage.read(key: _cachedUserKey);

  @override
  Future<void> saveCachedUserJson(String json) => _secureStorage.write(key: _cachedUserKey, value: json);

  @override
  Future<void> clearCachedUserJson() => _secureStorage.delete(key: _cachedUserKey);
}
