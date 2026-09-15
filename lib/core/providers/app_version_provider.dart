import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/version_check_service.dart';
import '../di/dependency_injection.dart';

/// The installed app's version/build (read from the platform, not
/// hardcoded) plus whatever [VersionCheckService] says about a newer one.
class AppVersionInfo extends Equatable {
  const AppVersionInfo({required this.version, required this.buildNumber, required this.updateStatus});

  final String version;
  final String buildNumber;
  final AppVersionStatus updateStatus;

  @override
  List<Object?> get props => [version, buildNumber, updateStatus];
}

/// Plain `FutureProvider` rather than a `@riverpod`-generated one — this is
/// read-only, one-shot data with no methods to call on it, so the
/// generated boilerplate a full notifier needs would buy nothing here.
final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  final status = await ref
      .read(versionCheckServiceProvider)
      .checkForUpdate(currentVersion: packageInfo.version, currentBuildNumber: packageInfo.buildNumber);
  return AppVersionInfo(version: packageInfo.version, buildNumber: packageInfo.buildNumber, updateStatus: status);
});
