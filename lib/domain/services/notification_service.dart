/// 统一的本地通知接口（规格 §5 Phase 5 / §8）。
///
/// 业务层只依赖这个抽象；Android 与 Windows 的具体实现放在
/// `infrastructure/notification`，平台 API 不会泄漏到上层。
abstract interface class NotificationService {
  /// 初始化底层插件（幂等，可重复调用）。
  Future<void> initialize({void Function(String? payload)? onNotificationTap});

  /// 请求通知权限；返回是否已获得授权。
  ///
  /// * Android 13+：弹出 POST_NOTIFICATIONS 授权框
  /// * Windows：系统没有运行时授权概念，直接返回 true
  Future<bool> requestPermission();

  /// 当前是否允许发通知（用于设置页展示状态）。
  Future<bool> areNotificationsEnabled();

  /// 额外能力：Android 12+ 的"精确闹钟"权限（可选）。
  ///
  /// 不授予时提醒仍会送达，但可能被系统推迟几分钟（实现里会退回非精确排期）。
  /// Windows 没有这个概念，直接返回 true。
  Future<bool> requestExactAlarmPermission();

  /// 在 [scheduledTime] 触发一条通知。
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  });

  /// 取消某条已排期 / 已显示的通知。
  Future<void> cancelNotification(int id);

  /// 取消本应用的全部通知。
  Future<void> cancelAll();
}
