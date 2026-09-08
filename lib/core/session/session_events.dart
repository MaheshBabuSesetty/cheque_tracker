import 'dart:async';

/// Broadcasts a single event whenever the current session becomes
/// unrecoverable (refresh itself was rejected — the refresh token is
/// invalid/revoked/expired, or the account is inactive). [AuthInterceptor]
/// pushes to this; the app root listens once and routes to the login screen,
/// so a 401 mid-navigation doesn't just fail silently until the next app
/// resume.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}
