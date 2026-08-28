import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_environment.dart';
import 'core/constants/app_constants.dart';
import 'core/di/dependency_injection.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';

// Screenshot/app-switcher redaction (security audit F-6) is implemented
// natively per platform rather than via a plugin — see MainActivity.kt
// (Android FLAG_SECURE) and AppDelegate.swift (iOS app-switcher blur).
// Two different screenshot-protection plugins tried here broke the release
// build against this project's current Android Gradle Plugin version, so
// this stays a first-party, few-line native change instead.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // A release build that silently fell back to the dev API (no
  // --dart-define-from-file=.env --dart-define=APP_ENV=... passed) is
  // almost certainly a mistake — surface it instead of quietly shipping
  // against dev.
  if (kReleaseMode && AppEnvironment.isDev) {
    debugPrint('⚠️ Release build is using the DEV API — pass --dart-define-from-file=.env --dart-define=APP_ENV=<uat|prod>.');
  }

  runApp(
    ProviderScope(
      overrides: [
        // The only provider that *must* be overridden before runApp(): every
        // other dependency in dependency_injection.dart derives from this.
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ChequeTrackerApp(),
    ),
  );
}

class ChequeTrackerApp extends ConsumerStatefulWidget {
  const ChequeTrackerApp({super.key});

  @override
  ConsumerState<ChequeTrackerApp> createState() => _ChequeTrackerAppState();
}

class _ChequeTrackerAppState extends ConsumerState<ChequeTrackerApp> {
  StreamSubscription<void>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    // An unrecoverable 401 (refresh itself was rejected) is detected deep
    // in `AuthInterceptor`, outside the widget tree — this is the one place
    // that reacts to it by clearing local auth state and kicking the user
    // back to login, rather than leaving them stuck on a screen that will
    // silently keep failing.
    _sessionExpiredSubscription = ref.read(sessionEventsProvider).onSessionExpired.listen((_) {
      ref.invalidate(authProvider);
      navigatorKey.currentState?.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
    });
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: AppConstants.osTitle,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 320),
      themeAnimationCurve: Curves.easeInOutCubic,
      initialRoute: RouteNames.splash,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
