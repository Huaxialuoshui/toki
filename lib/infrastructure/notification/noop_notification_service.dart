import '../../domain/services/notification_service.dart';

/// 空实现：用于测试，以及不支持通知的平台。
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<bool> areNotificationsEnabled() async => false;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> requestExactAlarmPermission() async => false;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {}
}
