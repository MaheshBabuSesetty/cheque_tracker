import 'dart:async';

/// In-app notification contract, decoupled from any specific delivery
/// mechanism (local notifications, push, in-app banners). The default
/// implementation broadcasts on a stream that UI can subscribe to; a
/// production implementation could instead wrap `flutter_local_notifications`
/// behind the same interface.
abstract class NotificationService {
  Stream<AppNotification> get notifications;
  void show(AppNotification notification);
  void dispose();
}

class AppNotification {
  const AppNotification({required this.title, this.body, this.isError = false});

  final String title;
  final String? body;
  final bool isError;
}

class InAppNotificationService implements NotificationService {
  final _controller = StreamController<AppNotification>.broadcast();

  @override
  Stream<AppNotification> get notifications => _controller.stream;

  @override
  void show(AppNotification notification) => _controller.add(notification);

  @override
  void dispose() => _controller.close();
}
