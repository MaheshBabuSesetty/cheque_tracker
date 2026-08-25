/// Build-time environment configuration. Only a DEV backend exists today —
/// UAT/Prod base URLs aren't provisioned yet.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://your-host/api
///
/// The default below is the DEV host requested in the API contract but not
/// yet confirmed by infra, and it is currently unreachable from any device:
/// the App Service's direct `azurewebsites.net` URL is network-blocked, and
/// traffic must route via a Cloudflare-fronted custom domain that isn't live
/// yet. Until that ships, real network calls against this default will fail
/// to connect — that's an infra gap, not a bug in this client.
class AppEnvironment {
  const AppEnvironment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://chqtrk-api-dev.sobhaapps.com/api',
  );
}
