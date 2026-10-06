import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/services/notification_service.dart';

/// 基于 flutter_local_notifications 的实现：Android 用系统本地通知，
/// Windows 用系统 Toast（同一个包的两个平台实现）。
///
/// 时间处理：把本地时间转成"绝对时刻"再交给系统（`toUtc()` + UTC 时区），
/// 因此夏令时/时区变化都不会让提醒偏移。
class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  void Function(String? payload)? _onTap;

  static const String _appName = 'Toki';
  static const String _appUserModelId = 'com.toki.toki';
  static const String _windowsGuid = 'd2b7f0d4-3f4a-4a9f-9f2c-1a7d6f5c8b31';
  static const String _channelId = 'toki_reminders';
  static const String _channelName = '日程提醒';
  static const String _channelDescription = '日程与倒计时提醒';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    windows: WindowsNotificationDetails(),
  );

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    _onTap = onNotificationTap ?? _onTap;
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: WindowsInitializationSettings(
        appName: _appName,
        appUserModelId: _appUserModelId,
        guid: _windowsGuid,
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) =>
          _onTap?.call(response.payload),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // 只在启动/设置页请求通知权限本身；"精确闹钟"权限单独提供入口，
      // 避免一进应用就跳到系统设置页。
      return await android.requestNotificationsPermission() ?? false;
    }

    // Windows 没有运行时通知授权（由系统"通知和操作"设置控制）。
    return Platform.isWindows;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return Platform.isWindows;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    // Windows 端插件没有查询接口，返回"未被系统阻止"。
    return Platform.isWindows;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await initialize();

    // 以绝对时刻排期：本地时间 → UTC 的 TZDateTime。
    final tz.TZDateTime scheduled =
        tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } on PlatformException catch (error) {
      // Android 12+ 默认不授予 SCHEDULE_EXACT_ALARM（Android 14 起对
      // targetSdk 34+ 更是默认拒绝）。此时退回非精确排期：
      // 提醒仍会送达，只是可能被系统推迟几分钟，而不是直接失败。
      if (error.code != 'exact_alarms_not_permitted') rethrow;
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
