import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../core/constants/api_endpoints.dart';

/// Result of asking whether a newer app version is available than
/// [currentVersion].
class AppVersionStatus extends Equatable {
  const AppVersionStatus({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    this.releaseNotes,
  });

  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final String? releaseNotes;

  @override
  List<Object?> get props => [currentVersion, latestVersion, updateAvailable, releaseNotes];
}

/// Checks the installed app version against whatever the update backend
/// considers current. Modeled as its own service (not folded into
/// `AuthRepository`) since it's unrelated to the session — the login
/// screen checks it independently of signing in.
abstract class VersionCheckService {
  Future<AppVersionStatus> checkForUpdate(String currentVersion);
}

/// `GET /app/version` — AllowAnonymous, so this must run on the
/// unauthenticated Dio client (no bearer token, no refresh-on-401 logic).
/// A failure here (offline, DEV unreachable) should never block the app —
/// it just means no update banner is shown, so any error is swallowed into
/// `updateAvailable: false` rather than thrown.
class HttpVersionCheckService implements VersionCheckService {
  const HttpVersionCheckService(this._dio);

  final Dio _dio;

  @override
  Future<AppVersionStatus> checkForUpdate(String currentVersion) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.appVersion,
        queryParameters: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'current': currentVersion,
        },
      );
      final data = response.data!;
      return AppVersionStatus(
        currentVersion: currentVersion,
        latestVersion: data['latestVersion'] as String,
        updateAvailable: data['updateAvailable'] as bool,
        releaseNotes: data['releaseNotes'] as String?,
      );
    } catch (_) {
      return AppVersionStatus(currentVersion: currentVersion, latestVersion: currentVersion, updateAvailable: false);
    }
  }
}
