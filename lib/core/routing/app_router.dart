import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/collection/presentation/screens/collection_detail_screen.dart';
import '../../features/collection/presentation/screens/main_shell_screen.dart';
import 'page_transitions.dart';
import 'route_names.dart';

/// Lets code outside the widget tree (a Riverpod notifier reacting to a
/// 401, a push-notification handler, etc.) trigger navigation via
/// `navigatorKey.currentState!.pushNamed(...)`.
final navigatorKey = GlobalKey<NavigatorState>();

/// Single source of truth for turning a route name into a page. Session/
/// auth-guard redirects are resolved by [SplashScreen] before it hands off
/// to [RouteNames.login] or [RouteNames.home], rather than here — that
/// keeps this function a plain, ref-free `RouteFactory`.
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RouteNames.splash:
      return AppPageRoute(
        page: const SplashScreen(),
        transitionType: TransitionType.fade,
        settings: settings,
      );

    case RouteNames.login:
      return AppPageRoute(
        page: const LoginScreen(),
        transitionType: TransitionType.slide,
        settings: settings,
      );

    case RouteNames.home:
      return AppPageRoute(
        page: const MainShellScreen(),
        transitionType: TransitionType.scale,
        settings: settings,
      );

    case RouteNames.profile:
      return AppPageRoute(
        page: const ProfileScreen(),
        transitionType: TransitionType.slide,
        settings: settings,
      );

    case RouteNames.collectionDetail:
      return AppPageRoute(
        page: CollectionDetailScreen(recordId: settings.arguments! as String),
        transitionType: TransitionType.slide,
        settings: settings,
      );

    default:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      );
  }
}
