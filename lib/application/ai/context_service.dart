import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/entities/countdown_remaining.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/countdown_repository.dart';
import '../../infrastructure/clock_provider.dart';

/// 根据用户问题动态收集上下文（规格 §13）。
///
/// 设计原则：**绝不把整个数据库塞给模型**。
/// * 只在与问题相关的时间范围内取日程（今天 / 明天 / 本周 / 下周 / 具体日期…）；
/// * 倒计时只取最近的几条；
/// * 总长度有上限（按字符近似 token），超出就截断并注明。
class ContextService {
  ContextService({
    required CalendarRepository events,
    required CountdownRepository countdowns,
    required Clock clock,
    this.maxEvents = 12,
    this.maxCountdowns = 4,
    this.maxChars = 1600,
  })  : _events = events,
        _countdowns = countdowns,
        _clock = clock;

  final CalendarRepository _events;
  final CountdownRepository _countdowns;
  final Clock _clock;

  final int maxEvents;
  final int maxCountdowns;
  final int maxChars;

  /// 生成上下文文本；没有可用内容时返回 null。
  Future<String?> buildContext(String question) async {
    final now = _clock.now();
    final range = _rangeFromQuestion(question, now);
    final lines = <String>[];

    lines.add('当前时间：${_date(now)} ${_time(now)} ${_weekday(now)}'
        '（时区偏移 ${now.timeZoneOffset.inMinutes >= 0 ? '+' : ''}'
        '${now.timeZoneOffset.inMinutes} 分钟）');

    final all = await _events.getAll();
    final windowEvents = all
        .where((CalendarEvent event) =>
            event.startTime.isBefore(range.end) &&
            !event.endTime.isBefore(range.start))
        .toList()
      ..sort((CalendarEvent a, CalendarEvent b) =>
          a.startTime.compareTo(b.startTime));

    final label = _rangeLabel(question, range);
    if (windowEvents.isEmpty) {
      lines.add('$label：没有日程。');
    } else {
      final shown = windowEvents.take(maxEvents).toList(growable: false);
      lines.add('$label（共 ${windowEvents.length} 条，列出 ${shown.length} 条）：');
      for (final event in shown) {
        lines.add('  - ${_eventLine(event)}');
      }
      if (windowEvents.length > shown.length) {
        lines.add('  - （其余 ${windowEvents.length - shown.length} 条已省略）');
      }
    }

    final countdowns = await _countdowns.getAll();
    final relevant = _relevantCountdowns(countdowns, question, now);
    if (relevant.isNotEmpty) {
      lines.add('倒计时：');
      for (final item in relevant) {
        final remaining = CountdownRemaining.between(
          target: item.targetTime,
          now: now,
        );
        final when = remaining.isPast
            ? '已过去 ${remaining.days} 天'
            : '还有 ${remaining.days} 天 ${remaining.hours} 小时';
        lines.add(
          '  - ${item.title}（${_date(item.targetTime)}，$when）',
        );
      }
    }

    final text = lines.join('\n');
    if (text.length <= maxChars) return text;
    // 近似 token 控制：超出预算就截断并显式说明，避免模型以为没有更多数据。
    return '${text.substring(0, maxChars)}\n…（上下文过长，已截断）';
  }

  /// 倒计时只取"问题提到的"或最近的几条，且置顶优先。
  List<CountdownItem> _relevantCountdowns(
    List<CountdownItem> all,
    String question,
    DateTime now,
  ) {
    if (all.isEmpty) return const <CountdownItem>[];

    final text = question.toLowerCase();
    final mentioned = all.where((CountdownItem item) {
      final title = item.title.toLowerCase();
      return title.isNotEmpty && text.contains(title);
    }).toList();
    if (mentioned.isNotEmpty) return mentioned.take(maxCountdowns).toList();

    final pinned = all
        .where((CountdownItem item) =>
            item.isPinned && item.targetTime.isAfter(now))
        .toList(growable: false);
    final upcoming = all
        .where((CountdownItem item) =>
            !item.isPinned && item.targetTime.isAfter(now))
        .toList()
      ..sort((CountdownItem a, CountdownItem b) =>
          a.targetTime.compareTo(b.targetTime));
    return <CountdownItem>[...pinned, ...upcoming]
        .take(maxCountdowns)
        .toList(growable: false);
  }

  static String _eventLine(CalendarEvent event) {
    final time = event.allDay
        ? '全天'
        : '${_time(event.startTime)}-${_time(event.endTime)}';
    final parts = <String>[
      _date(event.startTime),
      time,
      event.title,
      if (event.location != null && event.location!.isNotEmpty)
        '@${event.location}',
    ];
    return '${parts.join(' ')}（id=${event.id}）';
  }

  /// 从问题里解析出时间范围；识别不了就用"今天到未来 7 天"。
  static DateTimeRange _rangeFromQuestion(String question, DateTime now) {
    final text = question.toLowerCase();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange day(int offset) => DateTimeRange(
          start: today.add(Duration(days: offset)),
          end: today.add(Duration(days: offset + 1)),
        );

    if (text.contains('今天') || text.contains('today')) return day(0);
    if (text.contains('明天') || text.contains('tomorrow')) return day(1);
    if (text.contains('后天')) return day(2);
    if (text.contains('昨天')) return day(-1);

    if (text.contains('下周') || text.contains('next week')) {
      final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
      return DateTimeRange(
        start: monday.add(const Duration(days: 7)),
        end: monday.add(const Duration(days: 14)),
      );
    }
    if (text.contains('这周') ||
        text.contains('本周') ||
        text.contains('this week')) {
      final monday = today.subtract(Duration(days: today.weekday - DateTime.monday));
      return DateTimeRange(
        start: monday,
        end: monday.add(const Duration(days: 7)),
      );
    }
    if (text.contains('下个月') || text.contains('next month')) {
      return DateTimeRange(
        start: DateTime(now.year, now.month + 1),
        end: DateTime(now.year, now.month + 2),
      );
    }
    if (text.contains('本月') || text.contains('这个月')) {
      return DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      );
    }

    // 具体日期：2026-10-20 / 10月20日 / 10/20
    final iso = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(text);
    if (iso != null) {
      final date = DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
      return DateTimeRange(start: date, end: date.add(const Duration(days: 1)));
    }
    final cn = RegExp(r'(\d{1,2})月(\d{1,2})日?').firstMatch(text);
    if (cn != null) {
      final date = DateTime(
        now.year,
        int.parse(cn.group(1)!),
        int.parse(cn.group(2)!),
      );
      return DateTimeRange(start: date, end: date.add(const Duration(days: 1)));
    }
    final slash = RegExp(r'(\d{1,2})/(\d{1,2})').firstMatch(text);
    if (slash != null) {
      final date = DateTime(
        now.year,
        int.parse(slash.group(1)!),
        int.parse(slash.group(2)!),
      );
      return DateTimeRange(start: date, end: date.add(const Duration(days: 1)));
    }

    // 默认：今天到未来 7 天（有界）。
    return DateTimeRange(start: today, end: today.add(const Duration(days: 7)));
  }

  static String _rangeLabel(String question, DateTimeRange range) {
    final text = question.toLowerCase();
    if (text.contains('今天') || text.contains('today')) return '今天的日程';
    if (text.contains('明天') || text.contains('tomorrow')) return '明天的日程';
    if (text.contains('后天')) return '后天的日程';
    if (text.contains('昨天')) return '昨天的日程';
    if (text.contains('下周') || text.contains('next week')) return '下周的日程';
    if (text.contains('这周') ||
        text.contains('本周') ||
        text.contains('this week')) {
      return '本周的日程';
    }
    if (text.contains('下个月') || text.contains('next month')) return '下个月的日程';
    if (text.contains('本月') || text.contains('这个月')) return '本月的日程';
    return '${_date(range.start)} 起的日程';
  }

  // 刻意不用 intl 的 DateFormat：上下文服务运行在 widget 树之外，
  // 那时 zh 的 locale 数据未必已初始化（会抛 LocaleDataException）。
  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _date(DateTime time) =>
      '${time.year}-${_two(time.month)}-${_two(time.day)}';

  static String _time(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

  static String _weekday(DateTime time) {
    const names = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[time.weekday - 1];
  }
}

final contextServiceProvider = Provider<ContextService>(
  (ref) => ContextService(
    events: ref.watch(calendarRepositoryProvider),
    countdowns: ref.watch(countdownRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
