import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/di/dependency_injection.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

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

class ChequeTrackerApp extends ConsumerWidget {
  const ChequeTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: AppConstants.osTitle,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      //darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 320),
      themeAnimationCurve: Curves.easeInOutCubic,
      initialRoute: RouteNames.splash,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
