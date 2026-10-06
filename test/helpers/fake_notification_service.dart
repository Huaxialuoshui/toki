import 'package:toki/domain/services/notification_service.dart';

/// 记录调用的通知服务，用于断言"业务层要求系统做了什么"。
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionGranted = true, this.enabled = true});

  bool permissionGranted;
  bool enabled;

  final List<ScheduledNotification> scheduled = <ScheduledNotification>[];
  final List<int> cancelled = <int>[];
  int cancelAllCount = 0;
  int initializeCount = 0;
  int requestPermissionCount = 0;
  int requestExactAlarmCount = 0;
  bool exactAlarmGranted = true;

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    initializeCount++;
  }

  @override
  Future<bool> requestPermission() async {
    requestPermissionCount++;
    return permissionGranted;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    requestExactAlarmCount++;
    return exactAlarmGranted;
  }

  @override
  Future<bool> areNotificationsEnabled() async => enabled;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    scheduled.removeWhere((ScheduledNotification item) => item.id == id);
    scheduled.add(
      ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelled.add(id);
    scheduled.removeWhere((ScheduledNotification item) => item.id == id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }
}

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? payload;
}
