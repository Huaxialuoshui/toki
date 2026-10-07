import 'package:flutter/foundation.dart';

import '../entities/calendar_event.dart';

/// 日程重复规则（规格 §6）。
///
/// 存进数据库的是 [storageValue]（`none` / `daily` / `weekly` / `monthly` / `yearly`），
/// 这样以后要换成标准 RRULE 也只需要改这一层。
enum RepeatRule {
  none('none'),
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly');

  const RepeatRule(this.storageValue);

  final String storageValue;

  bool get repeats => this != RepeatRule.none;

  static RepeatRule parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return RepeatRule.none;
    final value = raw.trim().toLowerCase();
    for (final rule in RepeatRule.values) {
      if (rule.storageValue == value) return rule;
    }
    // 兼容早期可能写进去的 RRULE 片段（FREQ=WEEKLY）。
    if (value.contains('daily') || value.contains('freq=daily')) {
      return RepeatRule.daily;
    }
    if (value.contains('weekly') || value.contains('freq=weekly')) {
      return RepeatRule.weekly;
    }
    if (value.contains('monthly') || value.contains('freq=monthly')) {
      return RepeatRule.monthly;
    }
    if (value.contains('yearly') || value.contains('freq=yearly')) {
      return RepeatRule.yearly;
    }
    return RepeatRule.none;
  }
}

/// 一条日程在某个时间点上的一次发生。
@immutable
class EventOccurrence {
  const EventOccurrence({
    required this.event,
    required this.start,
    required this.end,
  });

  final CalendarEvent event;
  final DateTime start;
  final DateTime end;

  /// 展开出来的这一次是不是"原事件本身"（不是重复产生的）。
  bool get isSeriesStart => start == event.startTime;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventOccurrence &&
        other.event.id == event.id &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(event.id, start, end);
}

/// 把一条（可能重复的）日程展开成 `[from, to)` 区间内的所有发生。
///
/// * 不重复：只判断原事件是否与区间相交；
/// * 重复：从原事件开始时间起按规则步进，超过 [to] 或 `repeatUntil` 就停；
/// * `maxPerEvent` 是安全阀，避免"每天重复 + 查询窗口很大"时算出海量结果。
List<EventOccurrence> expandOccurrences(
  CalendarEvent event,
  DateTime from,
  DateTime to, {
  int maxPerEvent = 400,
}) {
  final rule = RepeatRule.parse(event.repeatRule);
  final duration = event.endTime.difference(event.startTime);
  final until = event.repeatUntil;

  if (!rule.repeats) {
    final overlaps =
        event.startTime.isBefore(to) && !event.endTime.isBefore(from);
    return overlaps
        ? <EventOccurrence>[
            EventOccurrence(
              event: event,
              start: event.startTime,
              end: event.endTime,
            ),
          ]
        : const <EventOccurrence>[];
  }

  return <EventOccurrence>[
    for (final start in expandRepeatTimes(
      origin: event.startTime,
      rule: rule,
      until: until,
      // 开始时间可能早于窗口起点但事件本身跨进窗口。
      from: from.subtract(duration),
      to: to,
      maxCount: maxPerEvent,
    ))
      EventOccurrence(event: event, start: start, end: start.add(duration)),
  ];
}

/// 展开重复序列，返回落在 `[from, to)` 里（且不晚于 [until]）的开始时间。
///
/// 日程和"独立重复提醒"共用这一份逻辑：提醒把 triggerTime 当成 origin、rule
/// 当成自己的重复规则即可。
List<DateTime> expandRepeatTimes({
  required DateTime origin,
  required RepeatRule rule,
  DateTime? until,
  required DateTime from,
  required DateTime to,
  int maxCount = 400,
}) {
  if (!rule.repeats) {
    final single = origin;
    if (single.isBefore(to) && !single.isBefore(from)) {
      if (until == null || !single.isAfter(_endOfDay(until))) {
        return <DateTime>[single];
      }
    }
    return const <DateTime>[];
  }

  final result = <DateTime>[];
  // 快速跳到窗口左边界附近：否则"十年前建好的每日重复"每次都要从第一天开始数。
  var index = _firstIndexAtOrAfter(origin, rule, from);
  while (result.length < maxCount) {
    final start = _nthOccurrence(origin, rule, index);
    index++;

    // 已经越过查询窗口右边界：后面的只会更晚，直接结束。
    if (!start.isBefore(to)) break;
    // 超出"重复截止"：包含截止当天。
    if (until != null && start.isAfter(_endOfDay(until))) break;
    if (start.isBefore(from)) continue;
    result.add(start);
  }
  return result;
}

int _firstIndexAtOrAfter(DateTime origin, RepeatRule rule, DateTime from) {
  if (!origin.isBefore(from)) return 0;
  final days = from.difference(origin).inDays;
  final months = (from.year - origin.year) * 12 + (from.month - origin.month);
  final index = switch (rule) {
    RepeatRule.none => 0,
    RepeatRule.daily => days - 1,
    RepeatRule.weekly => days ~/ 7 - 1,
    RepeatRule.monthly => months - 1,
    RepeatRule.yearly => months ~/ 12 - 1,
  };
  return index < 0 ? 0 : index;
}

/// 某条日程是否在 [day] 这一天出现（内部用展开，保证与视图一致）。
bool eventOccursOn(CalendarEvent event, DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  for (final occurrence in expandOccurrences(event, start, end)) {
    if (occurrence.start.isBefore(end) && !occurrence.end.isBefore(start)) {
      return true;
    }
  }
  return false;
}

DateTime _nthOccurrence(DateTime origin, RepeatRule rule, int index) {
  switch (rule) {
    case RepeatRule.none:
      return origin;
    case RepeatRule.daily:
      return origin.add(Duration(days: index));
    case RepeatRule.weekly:
      return origin.add(Duration(days: 7 * index));
    case RepeatRule.monthly:
      return _addMonths(origin, index);
    case RepeatRule.yearly:
      return _addMonths(origin, 12 * index);
  }
}

/// 加月份：保留"几号 + 时分秒"，遇到当月没有这一天时顺延到下个月（与多数日历一致）。
DateTime _addMonths(DateTime time, int months) {
  final targetMonth = time.month + months;
  final year = time.year + (targetMonth - 1) ~/ 12;
  final month = (targetMonth - 1) % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = time.day <= lastDay ? time.day : lastDay;
  return DateTime(
    year,
    month,
    day,
    time.hour,
    time.minute,
    time.second,
    time.millisecond,
    time.microsecond,
  );
}

DateTime _endOfDay(DateTime day) =>
    DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
