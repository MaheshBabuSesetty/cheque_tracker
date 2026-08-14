import 'package:connectivity_plus/connectivity_plus.dart';

/// Point-in-time connectivity check used by repositories to decide whether
/// to hit a remote datasource or fall back to the local/cached one.
///
/// This is intentionally a narrower contract than [ConnectivityService]
/// (services/connectivity_service.dart), which exposes a stream for
/// app-wide UI such as an offline banner.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
