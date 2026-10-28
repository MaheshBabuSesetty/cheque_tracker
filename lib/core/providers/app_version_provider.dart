import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed app's version/build, read from the platform rather than
/// hardcoded.
class AppVersionInfo extends Equatable {
  const AppVersionInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  List<Object?> get props => [version, buildNumber];
}

/// Plain `FutureProvider` rather than a `@riverpod`-generated one — this is
/// read-only, one-shot data with no methods to call on it, so the
/// generated boilerplate a full notifier needs would buy nothing here.
final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return AppVersionInfo(version: packageInfo.version, buildNumber: packageInfo.buildNumber);
});
