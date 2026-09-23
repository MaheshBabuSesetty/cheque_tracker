import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_environment.dart';

/// Result of asking whether a newer app build is available than
/// [currentBuildNumber].
class AppVersionStatus extends Equatable {
  const AppVersionStatus({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.updateAvailable,
    this.releaseNotes,
    this.updateUrl,
  });

  final String currentVersion;
  final String currentBuildNumber;
  final String latestVersion;
  final String latestBuildNumber;
  final bool updateAvailable;
  final String? releaseNotes;

  /// Where "Update now" should send the user. Always set when
  /// [updateAvailable] is true for [LoadlyVersionCheckService] — there's no
  /// store listing to fall back to, this app is sideloaded.
  final String? updateUrl;

  @override
  List<Object?> get props => [
    currentVersion,
    currentBuildNumber,
    latestVersion,
    latestBuildNumber,
    updateAvailable,
    releaseNotes,
    updateUrl,
  ];
}

/// Checks the installed app version/build against whatever the update
/// source considers current. Modeled as its own service (not folded into
/// `AuthRepository`) since it's unrelated to the session — the splash
/// screen checks it independently of signing in.
abstract class VersionCheckService {
  Future<AppVersionStatus> checkForUpdate({required String currentVersion, required String currentBuildNumber});
}

/// Reads the public Loadly share page for this app's Android build and
/// compares its build number against the installed one. UAT and Prod are
/// built and distributed as separate Loadly uploads (each with its own
/// share link, see [shareUrl]), so there's no single URL that covers both —
/// Dev has no Loadly distribution at all and never reaches this class (see
/// the `kDebugMode` check in [checkForUpdate]). Android builds here are
/// distributed ad-hoc via Loadly, not the Play Store, so there's no store
/// API to poll — Loadly's actual developer API (`api.loadly.io`) needs an
/// account `_api_key` we don't have, so this scrapes the same public page a
/// human would open, looking for the "X.Y.Z (build N)" text every build
/// page renders.
///
/// The version string alone isn't enough to detect an update: consecutive
/// Loadly builds have shipped under the same version (e.g. "1.0.0" for
/// both build 1 and build 2), so [AppVersionStatus.updateAvailable] is
/// decided by build number, not version string.
///
/// This is inherently fragile — it breaks silently (falls back to "no
/// update available") if Loadly ever changes this page's markup — but it's
/// the only thing we can do with just a public share link and no API key.
/// A failure here must never block the app on its own; see
/// [showForceUpdateDialog] in `force_update_dialog.dart` for what actually
/// blocks usage once an update is detected.
class LoadlyVersionCheckService implements VersionCheckService {
  const LoadlyVersionCheckService(this._dio);

  /// The UAT build's Loadly share link — also the Dev fallback, since Dev
  /// has no separate Loadly distribution of its own.
  static const String _uatShareUrl = 'https://loadly.io/iMprNjeT';

  /// The Prod build's Loadly share link — a distinct upload from UAT's.
  static const String _prodShareUrl = 'https://loadly.io/HNV16LuC';

  static String get shareUrl => AppEnvironment.isProd ? _prodShareUrl : _uatShareUrl;

  static final RegExp _versionBuildPattern = RegExp(r'(\d+(?:\.\d+){1,3})\s*\(\s*[Bb]uild\s*(\d+)\s*\)');

  final Dio _dio;

  @override
  Future<AppVersionStatus> checkForUpdate({required String currentVersion, required String currentBuildNumber}) async {
    // Debug builds run off whatever's on the developer's machine, not a
    // Loadly-distributed build, so comparing build numbers against the
    // public share page is meaningless there and would just force-block
    // local development. Same fail-open shape as the jailbreak check in
    // SplashScreen._isDeviceCompromised.
    if (kDebugMode) {
      return AppVersionStatus(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: currentVersion,
        latestBuildNumber: currentBuildNumber,
        updateAvailable: false,
      );
    }

    // The Loadly page this scrapes is explicitly Android-only ("For Android
    // device"); iOS has no equivalent share link here, so never claim an
    // update is available on iOS.
    if (!Platform.isAndroid) {
      return AppVersionStatus(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: currentVersion,
        latestBuildNumber: currentBuildNumber,
        updateAvailable: false,
      );
    }

    try {
      final response = await _dio.get<String>(shareUrl, options: Options(responseType: ResponseType.plain));
      final match = _versionBuildPattern.firstMatch(response.data ?? '');
      if (match == null) {
        throw const FormatException('Loadly share page did not contain a recognizable version/build.');
      }

      final latestVersion = match.group(1)!;
      final latestBuildNumber = match.group(2)!;
      final updateAvailable = (int.tryParse(latestBuildNumber) ?? 0) > (int.tryParse(currentBuildNumber) ?? 0);

      return AppVersionStatus(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
        updateAvailable: updateAvailable,
        updateUrl: updateAvailable ? shareUrl : null,
      );
    } catch (_) {
      return AppVersionStatus(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: currentVersion,
        latestBuildNumber: currentBuildNumber,
        updateAvailable: false,
      );
    }
  }
}
