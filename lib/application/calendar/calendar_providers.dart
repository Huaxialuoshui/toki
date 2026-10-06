import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_category.dart';
import '../../domain/entities/calendar_event.dart';
import '../../infrastructure/clock_provider.dart';

/// [day] 当天的全部日程（首页"今日事项"）。
final eventsForDayProvider =
    StreamProvider.autoDispose.family<List<CalendarEvent>, DateTime>(
  (ref, day) {
    final start = DateTime(day.year, day.month, day.day);
    return ref.watch(calendarRepositoryProvider).watchRange(
          from: start,
          to: start.add(const Duration(days: 1)),
        );
  },
);

/// [range] 内的全部日程（日历月视图）。
final eventsForRangeProvider =
    StreamProvider.autoDispose.family<List<CalendarEvent>, DateTimeRange>(
  (ref, range) => ref.watch(calendarRepositoryProvider).watchRange(
        from: range.start,
        to: range.end,
      ),
);

/// 当前时间之后的最近几条日程（首页"未来事件"）。
final upcomingEventsProvider =
    StreamProvider.autoDispose<List<CalendarEvent>>((ref) {
  return ref.watch(calendarRepositoryProvider).watchUpcoming(
        after: ref.watch(clockProvider).now(),
        limit: 4,
      );
});

/// 日历分类。
final calendarCategoriesProvider =
    StreamProvider.autoDispose<List<CalendarCategory>>(
  (ref) => ref.watch(calendarCategoryRepositoryProvider).watchAll(),
);
