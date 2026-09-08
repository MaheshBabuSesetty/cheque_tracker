/// Global, non-secret app-wide constants.
class AppConstants {
  const AppConstants._();

  /// OS-level app title (task switcher, browser tab) — on-screen branding
  /// uses [brandWordmark] + [appName] + [appTagline] separately, per design.
  static const String osTitle = 'Sobha Cheque Tracker';

  static const String brandWordmark = 'Sobha';
  static const String appName = 'Cheque Tracker';
  static const String appTagline = 'FIELD COLLECTION';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String prefsAuthTokenKey = 'auth_token';
  static const String prefsUserIdKey = 'auth_user_id';
  static const String prefsThemeModeKey = 'theme_mode';
}
