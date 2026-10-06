import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/reminder.dart';
import 'notification_providers.dart';
import 'reminder_scheduler.dart';

/// 数据库里的全部提醒。
final remindersProvider = StreamProvider.autoDispose<List<Reminder>>(
  (ref) => ref.watch(reminderRepositoryProvider).watchAll(),
);

/// 通知相关的启动流程：初始化 → 请求权限 → 首次同步提醒排期。
final notificationStartupProvider = FutureProvider<void>((ref) async {
  final notifications = ref.watch(notificationServiceProvider);
  await notifications.initialize();
  await notifications.requestPermission();
  await ref.watch(reminderSchedulerProvider).sync();
});

/// 提醒变化时自动重新同步排期（新增 / 删除 / 改时间 / 启用开关）。
///
/// 由 `TokiApp` watch，生命周期与 App 一致。
final reminderAutoSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(reminderSchedulerProvider);
  ref.listen<AsyncValue<List<Reminder>>>(remindersProvider, (
    AsyncValue<List<Reminder>>? previous,
    AsyncValue<List<Reminder>> next,
  ) {
    if (next.hasValue) {
      unawaited(scheduler.sync());
    }
  });
});
