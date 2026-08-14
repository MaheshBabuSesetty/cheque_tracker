/// Central registry of route name constants. Add a new entry here whenever
/// a screen is added, and switch on it in `app_router.dart`.
class RouteNames {
  const RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';

  /// Pushed with the record id as `settings.arguments`.
  static const String collectionDetail = '/collection-detail';
}
