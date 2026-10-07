import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/recurrence.dart';
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
/// * 目标集合 = 已启用、且在未来 [horizon] 内会触发的提醒（重复日程按次展开）；
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

  /// 只把未来这段时间内的提醒排进系统（重复日程按次展开）。
  static const Duration horizon = Duration(days: 30);

  /// 单个提醒最多排多少条：防止"每天重复 + 长视野"把系统通知排爆。
  static const int maxOccurrencesPerReminder = 30;

  /// 稳定、非负的通知 id：同一个提醒（同一次发生）每次都是同一个 id。
  ///
  /// [slot] 用来区分重复日程的不同次；不传表示这条提醒只有一次。
  static int notificationIdFor(String reminderId, {int slot = 0}) {
    // FNV-1a 32 位，跨运行稳定（Dart 的 String.hashCode 不保证稳定）。
    final key = slot == 0 ? reminderId : '$reminderId#$slot';
    var hash = 0x811c9dc5;
    for (final int unit in key.codeUnits) {
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

    final desired = <int, _PlannedNotification>{};
    for (final reminder in all) {
      if (!reminder.enabled) continue;
      for (final planned in await _plan(reminder, now, l10n)) {
        desired[planned.id] = planned;
      }
    }

    final previouslyScheduled = _settings.readScheduledNotificationIds();
    for (final id in previouslyScheduled) {
      if (!desired.containsKey(id)) {
        await _notifications.cancelNotification(id);
      }
    }

    for (final entry in desired.entries) {
      final planned = entry.value;
      try {
        await _notifications.scheduleNotification(
          id: planned.id,
          title: planned.title,
          body: planned.body,
          scheduledTime: planned.trigger,
          payload: planned.payload,
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

  /// 把一条提醒摊平成未来会触发的若干条通知。
  ///
  /// * 关联日程：按日程的重复规则展开，每条发生的提醒时间 = 这次开始 - 提前量；
  /// * 独立提醒：按提醒自己的重复规则展开；
  /// * 都不重复：就一条（触发时间在未来才要）。
  Future<List<_PlannedNotification>> _plan(
    Reminder reminder,
    DateTime now,
    AppLocalizations l10n,
  ) async {
    final until = now.add(horizon);
    final eventId = reminder.eventId;

    if (eventId != null) {
      final event = await _events.findById(eventId);
      if (event != null) {
        final rule = RepeatRule.parse(event.repeatRule);
        // 提前量：事件开始 - 提醒触发（改过时间的旧数据也能算出正确偏移）。
        final lead = event.startTime.difference(reminder.triggerTime);
        final starts = expandRepeatTimes(
          origin: event.startTime,
          rule: rule,
          until: event.repeatUntil,
          from: now.subtract(lead),
          to: until.add(lead).add(const Duration(days: 1)),
          maxCount: maxOccurrencesPerReminder,
        );
        final planned = <_PlannedNotification>[];
        for (final start in starts) {
          final trigger = start.subtract(lead);
          if (!trigger.isAfter(now) || trigger.isAfter(until)) continue;
          planned.add(
            _PlannedNotification(
              id: notificationIdFor(
                reminder.id,
                // 不重复时沿用原来的 id，避免升级后把已有排期当成"新的"。
                slot: rule.repeats ? start.millisecondsSinceEpoch ~/ 1000 : 0,
              ),
              title: reminder.title,
              body: _bodyForLead(lead, l10n),
              trigger: trigger,
              payload: eventId,
            ),
          );
          if (planned.length >= maxOccurrencesPerReminder) break;
        }
        return planned;
      }
    }

    final rule = RepeatRule.parse(reminder.repeatRule);
    if (rule.repeats) {
      final times = expandRepeatTimes(
        origin: reminder.triggerTime,
        rule: rule,
        from: now,
        to: until,
        maxCount: maxOccurrencesPerReminder,
      );
      return <_PlannedNotification>[
        for (final time in times)
          _PlannedNotification(
            id: notificationIdFor(
              reminder.id,
              slot: time.millisecondsSinceEpoch ~/ 1000,
            ),
            title: reminder.title,
            body: l10n.notificationDefaultBody,
            trigger: time,
          ),
      ];
    }

    if (!reminder.triggerTime.isAfter(now)) {
      return const <_PlannedNotification>[];
    }
    return <_PlannedNotification>[
      _PlannedNotification(
        id: notificationIdFor(reminder.id),
        title: reminder.title,
        body: l10n.notificationDefaultBody,
        trigger: reminder.triggerTime,
        payload: eventId,
      ),
    ];
  }

  /// 按"提前多久"生成正文。
  String _bodyForLead(Duration lead, AppLocalizations l10n) {
    if (lead.inMinutes <= 0) return l10n.notificationLeadNow;
    if (lead.inMinutes < Duration.minutesPerHour) {
      return l10n.notificationLeadMinutes(lead.inMinutes);
    }
    if (lead.inMinutes < Duration.minutesPerDay) {
      return l10n
          .notificationLeadHours(lead.inMinutes ~/ Duration.minutesPerHour);
    }
    return l10n.notificationLeadDays(lead.inMinutes ~/ Duration.minutesPerDay);
  }

  Future<AppLocalizations> _loadLocalizations() async {
    final locale = _locale();
    return AppLocalizations.delegate.load(locale);
  }
}

/// 一条待排期的通知。
class _PlannedNotification {
  const _PlannedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.trigger,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime trigger;
  final String? payload;
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
