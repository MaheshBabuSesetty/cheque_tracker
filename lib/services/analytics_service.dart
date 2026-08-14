import 'dart:developer' as developer;

/// Analytics contract. Swapping [ConsoleAnalyticsService] for a Firebase/
/// Mixpanel/Amplitude-backed implementation is a one-provider-override
/// change (see core/di/dependency_injection.dart) — no call site changes.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object?> parameters});
  Future<void> setUserId(String? userId);
}

class ConsoleAnalyticsService implements AnalyticsService {
  const ConsoleAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, Object?> parameters = const {}}) async {
    developer.log('event: $name $parameters', name: 'Analytics');
  }

  @override
  Future<void> setUserId(String? userId) async {
    developer.log('setUserId: $userId', name: 'Analytics');
  }
}
