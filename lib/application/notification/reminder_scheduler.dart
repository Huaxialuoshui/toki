import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/services/notification_service.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'notification_providers.dart';

/// 把数据库里的提醒同步成系统通知。
///
/// 职责边界：业务层只面对 [NotificationService] 抽象；Android / Windows 的
/// 具体调度都在 infrastructure 里。
///
/// 同步策略（幂等）：
/// * 目标集合 = 已启用且触发时间在未来的提醒；
/// * 先取消"上次排期过、这次不在目标集合里"的通知（覆盖提醒被删除/停用的场景）；
/// * 再按当前设置重新排期。
class ReminderScheduler {
  ReminderScheduler({
    required NotificationService notifications,
    required ReminderRepository reminders,
    required CalendarRepository events,
    required AppSettingsStore settings,
    required Clock clock,
    required Locale Function() locale,
  })  : _notifications = notifications,
        _reminders = reminders,
        _events = events,
        _settings = settings,
        _clock = clock,
        _locale = locale;

  final NotificationService _notifications;
  final ReminderRepository _reminders;
  final CalendarRepository _events;
  final AppSettingsStore _settings;
  final Clock _clock;
  final Locale Function() _locale;

  /// 稳定、非负的通知 id：同一个提醒每次都是同一个 id。
  static int notificationIdFor(String reminderId) {
    // FNV-1a 32 位，跨运行稳定（Dart 的 String.hashCode 不保证稳定）。
    var hash = 0x811c9dc5;
    for (final int unit in reminderId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  Future<void> sync() async {
    await _notifications.initialize();

    final now = _clock.now();
    final all = await _reminders.getAll();
    final l10n = await _loadLocalizations();

    final desired = <int, Reminder>{};
    for (final reminder in all) {
      if (!reminder.enabled) continue;
      if (!reminder.triggerTime.isAfter(now)) continue;
      desired[notificationIdFor(reminder.id)] = reminder;
    }

    final previouslyScheduled = _settings.readScheduledNotificationIds();
    for (final id in previouslyScheduled) {
      if (!desired.containsKey(id)) {
        await _notifications.cancelNotification(id);
      }
    }

    for (final entry in desired.entries) {
      final reminder = entry.value;
      try {
        await _notifications.scheduleNotification(
          id: entry.key,
          title: reminder.title,
          body: await _bodyFor(reminder, l10n),
          scheduledTime: reminder.triggerTime,
          payload: reminder.eventId,
        );
      } catch (error) {
        // 单条排期失败不应该中断整个同步（例如系统拒绝某种排期模式）。
        debugPrint('排期通知失败 id=${entry.key}: $error');
      }
    }

    await _settings.writeScheduledNotificationIds(
      desired.keys.toList(growable: false),
    );
  }

  /// 通知正文：优先说"还有多久开始"，拿不到日程时用通用文案。
  Future<String> _bodyFor(Reminder reminder, AppLocalizations l10n) async {
    final eventId = reminder.eventId;
    if (eventId == null) return l10n.notificationDefaultBody;

    final CalendarEvent? event = await _events.findById(eventId);
    if (event == null) return l10n.notificationDefaultBody;

    final lead = event.startTime.difference(reminder.triggerTime);
    if (lead.inMinutes <= 0) return l10n.notificationLeadNow;
    if (lead.inMinutes < Duration.minutesPerHour) {
      return l10n.notificationLeadMinutes(lead.inMinutes);
    }
    if (lead.inMinutes < Duration.minutesPerDay) {
      return l10n.notificationLeadHours(lead.inMinutes ~/ Duration.minutesPerHour);
    }
    return l10n.notificationLeadDays(lead.inMinutes ~/ Duration.minutesPerDay);
  }

  Future<AppLocalizations> _loadLocalizations() async {
    final locale = _locale();
    return AppLocalizations.delegate.load(locale);
  }
}

/// 当前用于通知文案的语言：手动选择的语言优先，否则跟随系统（不支持的回退中文）。
Locale effectiveNotificationLocale({
  required Locale? selected,
  required Locale systemLocale,
}) {
  final candidate = selected ?? systemLocale;
  for (final supported in supportedLocales) {
    if (supported.languageCode == candidate.languageCode) return supported;
  }
  return const Locale('zh');
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(
    notifications: ref.watch(notificationServiceProvider),
    reminders: ref.watch(reminderRepositoryProvider),
    events: ref.watch(calendarRepositoryProvider),
    settings: ref.watch(appSettingsStoreProvider),
    clock: ref.watch(clockProvider),
    locale: () {
      final selected = ref.read(localeControllerProvider);
      final system = WidgetsBinding.instance.platformDispatcher.locale;
      return effectiveNotificationLocale(
        selected: selected,
        systemLocale: system,
      );
    },
  );
});
