import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/entities/countdown_remaining.dart';
import '../../domain/entities/widget_config.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/device/device_channel.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../ai/daily_digest_service.dart' show systemLocaleProvider;
import '../settings/settings_controller.dart';
import '../device/device_providers.dart';

/// 小组件配置（外观 + 显示内容），保存在 shared_preferences。
class WidgetConfigController extends Notifier<WidgetConfig> {
  @override
  WidgetConfig build() {
    final raw = ref.watch(appSettingsStoreProvider).readWidgetConfig();
    if (raw == null || raw.isEmpty) return const WidgetConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const WidgetConfig();
      return WidgetConfig.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return const WidgetConfig();
    }
  }

  Future<void> update(WidgetConfig config) async {
    state = config;
    await ref
        .read(appSettingsStoreProvider)
        .writeWidgetConfig(jsonEncode(config.toJson()));
    await ref.read(widgetPublisherProvider).publish();
  }
}

final widgetConfigProvider =
    NotifierProvider<WidgetConfigController, WidgetConfig>(
  WidgetConfigController.new,
);

/// 把当前状态推给原生小组件。
class WidgetPublisher {
  WidgetPublisher(this._ref);

  final Ref _ref;

  Future<void> publish() async {
    final DeviceChannel channel = _ref.read(deviceChannelProvider);
    if (!channel.isSupported) return;
    final config = _ref.read(widgetConfigProvider);
    final now = _ref.read(clockProvider).now();
    final l10n = await _localizations();

    final List<CountdownItem> countdowns = config.showCountdown
        ? await _upcomingCountdowns(now)
        : const <CountdownItem>[];
    final List<EventOccurrence> events = config.showEvent
        ? await _upcomingEvents(now)
        : const <EventOccurrence>[];
    final CountdownItem? countdown =
        countdowns.isEmpty ? null : countdowns.first;
    final EventOccurrence? event = events.isEmpty ? null : events.first;

    final hasCountdown = countdown != null;
    final hasEvent = event != null;

    final String title;
    final String subtitle;
    final String extra;
    if (hasCountdown) {
      final remaining =
          CountdownRemaining.between(target: countdown.targetTime, now: now);
      title = countdown.title;
      subtitle = _remainingLabel(l10n, remaining);
      extra = hasEvent
          ? l10n.widgetNextEvent(event.event.title, _shortTime(event.start))
          : '';
    } else if (hasEvent) {
      title = l10n.widgetNextEventTitle;
      subtitle = event.event.title;
      extra = _shortTime(event.start);
    } else {
      title = l10n.appName;
      subtitle = l10n.widgetNoUpcoming;
      extra = '';
    }

    final payload = <String, Object?>{
      'hasData': hasCountdown || hasEvent,
      'kind': hasCountdown ? 'countdown' : (hasEvent ? 'event' : 'empty'),
      'title': title,
      'subtitle': subtitle,
      'extra': extra,
      'updatedLabel': l10n.widgetUpdatedAt(_shortTime(now)),
      'locale': l10n.localeName,
      'targetEpochMillis':
          hasCountdown ? countdown.targetTime.millisecondsSinceEpoch : 0,
      'eventEpochMillis': hasEvent ? event.start.millisecondsSinceEpoch : 0,
      // 多带几条未来条目：原生定时重绘时可以自行推进到下一条，
      // 不需要先打开应用把状态重新算一遍。
      'countdowns': countdowns
          .map(
            (CountdownItem item) => <String, Object?>{
              'title': item.title,
              'targetEpochMillis': item.targetTime.millisecondsSinceEpoch,
            },
          )
          .toList(growable: false),
      'events': events
          .map(
            (EventOccurrence item) => <String, Object?>{
              'title': item.event.title,
              'startEpochMillis': item.start.millisecondsSinceEpoch,
              'endEpochMillis': item.end.millisecondsSinceEpoch,
              'timeLabel': _shortTime(item.start),
            },
          )
          .toList(growable: false),
      'appearance': config.toJson(),
    };
    await channel.pushWidgetState(jsonEncode(payload));
  }

  Future<List<CountdownItem>> _upcomingCountdowns(DateTime now) async {
    final items = await _ref.read(countdownRepositoryProvider).getAll();
    final upcoming = items
        .where((CountdownItem item) => item.targetTime.isAfter(now))
        .toList()
      ..sort((CountdownItem a, CountdownItem b) =>
          a.targetTime.compareTo(b.targetTime));
    return upcoming.take(8).toList(growable: false);
  }

  Future<List<EventOccurrence>> _upcomingEvents(DateTime now) async {
    final horizon = now.add(const Duration(days: 30));
    final events = await _ref
        .read(calendarRepositoryProvider)
        .watchRelevant(from: now, to: horizon)
        .first;
    final occurrences = <EventOccurrence>[];
    for (final event in events) {
      if (event.isCancelled) continue;
      occurrences.addAll(expandOccurrences(event, now, horizon));
    }
    occurrences.removeWhere((EventOccurrence o) => !o.end.isAfter(now));
    occurrences.sort(
      (EventOccurrence a, EventOccurrence b) => a.start.compareTo(b.start),
    );
    return occurrences.take(8).toList(growable: false);
  }

  Future<AppLocalizations> _localizations() {
    final Locale locale =
        _ref.read(localeControllerProvider) ?? _ref.read(systemLocaleProvider);
    return AppLocalizations.delegate.load(locale);
  }

  String _remainingLabel(AppLocalizations l10n, CountdownRemaining remaining) {
    if (remaining.isPast) return l10n.widgetCountdownPast;
    if (remaining.days > 0) {
      return l10n.widgetRemainingDays(remaining.days, remaining.hours);
    }
    if (remaining.hours > 0) {
      return l10n.widgetRemainingHours(remaining.hours, remaining.minutes);
    }
    return l10n.widgetRemainingMinutes(remaining.minutes);
  }

  static String _shortTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.month}/${time.day} ${two(time.hour)}:${two(time.minute)}';
  }
}

final widgetPublisherProvider =
    Provider<WidgetPublisher>((ref) => WidgetPublisher(ref));

/// 应用级同步：日程 / 倒计时 / 小组件外观一变，就重绘小组件。
///
/// 由 `TokiApp` 在启动时 watch 一次（见 app.dart）。
final widgetAutoSyncProvider = Provider<void>((ref) {
  Timer? debounce;

  // 数据流可能连续触发多次，这里做 400ms 防抖，避免每次都写文件。
  void schedule() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      try {
        ref.read(widgetPublisherProvider).publish();
      } on Object catch (error) {
        // 小组件推送失败不应该影响应用本身。
        debugPrint('更新桌面小组件失败：$error');
      }
    });
  }

  final now = ref.watch(clockProvider).now();
  final countdowns = ref.watch(countdownRepositoryProvider).watchAll();
  final events = ref.watch(calendarRepositoryProvider).watchRelevant(
        from: now,
        to: now.add(const Duration(days: 30)),
      );
  final configSubscription =
      ref.listen(widgetConfigProvider, (_, __) => schedule());
  final countdownSubscription = countdowns.listen((_) => schedule());
  final eventSubscription = events.listen((_) => schedule());

  ref.onDispose(() {
    debounce?.cancel();
    configSubscription.close();
    countdownSubscription.cancel();
    eventSubscription.cancel();
  });
});
