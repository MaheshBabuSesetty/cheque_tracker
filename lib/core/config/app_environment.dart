/// Build-time environment configuration. All three environments' config
/// lives in the repo-root `.env` (one file, prefixed keys); which one is
/// active is picked by a single `APP_ENV` define, e.g.:
///
///   flutter run   --dart-define-from-file=.env --dart-define=APP_ENV=dev
///   flutter build apk --dart-define-from-file=.env --dart-define=APP_ENV=uat
///   flutter build ipa --dart-define-from-file=.env --dart-define=APP_ENV=prod
///
/// Omitting both flags (a quick local `flutter run`) falls back to the dev
/// defaults hardcoded below — fine for local iteration, but a UAT/Prod
/// build must always pass both flags explicitly. `main()` logs a warning
/// if a release build ends up on `dev` so that mistake doesn't ship
/// silently.
///
/// DEV's URL is confirmed live. **UAT/Prod are placeholder hostnames**
/// (`dev` swapped for `uat`/`prod` on the same domain — unverified) — fix
/// the root `.env` once the real hosts are known; nothing here needs to change.
class AppEnvironment {
  const AppEnvironment._();

  static const String name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static const String _devApiBaseUrl = String.fromEnvironment(
    'DEV_API_BASE_URL',
    defaultValue: 'https://chqtrk-api-dev.sobhaapps.com/api',
  );
  static const String _uatApiBaseUrl = String.fromEnvironment(
    'UAT_API_BASE_URL',
    defaultValue: 'https://chqtrk-api-uat.sobhaapps.com/api',
  );
  static const String _prodApiBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://chqtrk-api-prod.sobhaapps.com/api',
  );

  static const String apiBaseUrl = name == 'prod' ? _prodApiBaseUrl : (name == 'uat' ? _uatApiBaseUrl : _devApiBaseUrl);

  static bool get isDev => name == 'dev';
  static bool get isUat => name == 'uat';
  static bool get isProd => name == 'prod';
}
