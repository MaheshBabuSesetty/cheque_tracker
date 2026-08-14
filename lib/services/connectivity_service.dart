import 'package:connectivity_plus/connectivity_plus.dart';

/// App-wide connectivity stream, consumed by UI (e.g. an offline banner).
///
/// This is deliberately a separate contract from `core/network/network_info.dart`'s
/// [NetworkInfo]: that one answers "am I online right now?" for a single
/// repository call, this one is a long-lived stream for reactive UI.
abstract class ConnectivityService {
  Stream<bool> get onConnectivityChanged;
  Future<bool> get isConnected;
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService(this._connectivity);

  final Connectivity _connectivity;

  @override
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
