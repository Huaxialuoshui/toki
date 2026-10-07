import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_category.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';

/// [day] 当天的全部日程（首页"今日事项"）。
///
/// 返回的是**展开后的一次次发生**：重复日程在这一天也会出现。
final eventsForDayProvider =
    StreamProvider.autoDispose.family<List<EventOccurrence>, DateTime>(
  (ref, day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return ref
        .watch(calendarRepositoryProvider)
        .watchRelevant(from: start, to: end)
        .map((List<CalendarEvent> events) =>
            occurrencesInRange(events, start, end));
  },
);

/// [range] 内的全部日程（日历月 / 周 / 日视图），同样已展开重复。
final eventsForRangeProvider =
    StreamProvider.autoDispose.family<List<EventOccurrence>, DateTimeRange>(
  (ref, range) => ref
      .watch(calendarRepositoryProvider)
      .watchRelevant(from: range.start, to: range.end)
      .map(
        (List<CalendarEvent> events) =>
            occurrencesInRange(events, range.start, range.end),
      ),
);

/// 当前时间之后的最近几条日程（首页"未来事件"）。
final upcomingEventsProvider =
    StreamProvider.autoDispose<List<EventOccurrence>>((ref) {
  final now = ref.watch(clockProvider).now();
  final horizon =
      DateTime(now.year, now.month, now.day).add(const Duration(days: 30));
  return ref
      .watch(calendarRepositoryProvider)
      .watchRelevant(from: now, to: horizon)
      .map((List<CalendarEvent> events) {
    final occurrences = occurrencesInRange(events, now, horizon)
        .where((EventOccurrence o) => o.end.isAfter(now))
        .toList()
      ..sort(
          (EventOccurrence a, EventOccurrence b) => a.start.compareTo(b.start));
    return occurrences.take(4).toList(growable: false);
  });
});

/// 把 [events] 展开成 `[from, to)` 内的一次次发生，按开始时间排序。
List<EventOccurrence> occurrencesInRange(
  List<CalendarEvent> events,
  DateTime from,
  DateTime to,
) {
  final occurrences = <EventOccurrence>[];
  for (final event in events) {
    if (event.isCancelled) continue;
    occurrences.addAll(expandOccurrences(event, from, to));
  }
  occurrences.sort(
    (EventOccurrence a, EventOccurrence b) => a.start.compareTo(b.start),
  );
  return occurrences;
}

/// 日历分类。
final calendarCategoriesProvider =
    StreamProvider.autoDispose<List<CalendarCategory>>(
  (ref) => ref.watch(calendarCategoryRepositoryProvider).watchAll(),
);
