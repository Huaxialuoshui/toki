import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/notification_service.dart';
import '../../infrastructure/notification/noop_notification_service.dart';

/// 通知服务。
///
/// `main()` 会 override 成真实实现（Android / Windows 走
/// flutter_local_notifications），测试里替换成 fake 或空实现。
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NoopNotificationService(),
);
