import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/services/recurrence.dart';

/// 重复日程展开（规格 §6）。
void main() {
  CalendarEvent event({
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    String? repeatRule,
    DateTime? repeatUntil,
  }) =>
      CalendarEvent(
        id: 'e1',
        title: '周会',
        startTime: start,
        endTime: start.add(duration),
        repeatRule: repeatRule,
        repeatUntil: repeatUntil,
        createdAt: start,
        updatedAt: start,
      );

  List<DateTime> starts(
    CalendarEvent e,
    DateTime from,
    DateTime to,
  ) =>
      expandOccurrences(e, from, to)
          .map((EventOccurrence o) => o.start)
          .toList(growable: false);

  group('规则解析', () {
    test('识别内置规则，未知值当作不重复', () {
      expect(RepeatRule.parse(null), RepeatRule.none);
      expect(RepeatRule.parse(''), RepeatRule.none);
      expect(RepeatRule.parse('none'), RepeatRule.none);
      expect(RepeatRule.parse('daily'), RepeatRule.daily);
      expect(RepeatRule.parse('WEEKLY'), RepeatRule.weekly);
      expect(RepeatRule.parse('FREQ=MONTHLY'), RepeatRule.monthly);
      expect(RepeatRule.parse('乱写的'), RepeatRule.none);
      expect(RepeatRule.daily.repeats, isTrue);
      expect(RepeatRule.none.repeats, isFalse);
    });
  });

  group('不重复', () {
    test('区间相交才有结果，用事件自身的时间', () {
      final e = event(start: DateTime(2026, 10, 7, 9));

      final hit =
          expandOccurrences(e, DateTime(2026, 10, 7), DateTime(2026, 10, 8));
      expect(hit, hasLength(1));
      expect(hit.single.start, DateTime(2026, 10, 7, 9));
      expect(hit.single.isSeriesStart, isTrue);

      expect(
        expandOccurrences(e, DateTime(2026, 10, 8), DateTime(2026, 10, 9)),
        isEmpty,
      );
    });
  });

  group('每天', () {
    test('窗口内每天一次，窗口外不出现', () {
      final e = event(
        start: DateTime(2026, 10, 5, 9),
        repeatRule: 'daily',
      );

      expect(
        starts(e, DateTime(2026, 10, 6), DateTime(2026, 10, 9)),
        <DateTime>[
          DateTime(2026, 10, 6, 9),
          DateTime(2026, 10, 7, 9),
          DateTime(2026, 10, 8, 9),
        ],
      );
    });

    test('重复截止当天仍然生效，之后停止', () {
      final e = event(
        start: DateTime(2026, 10, 5, 9),
        repeatRule: 'daily',
        repeatUntil: DateTime(2026, 10, 7),
      );

      expect(
        starts(e, DateTime(2026, 10, 1), DateTime(2026, 10, 12)),
        <DateTime>[
          DateTime(2026, 10, 5, 9),
          DateTime(2026, 10, 6, 9),
          DateTime(2026, 10, 7, 9),
        ],
      );
    });

    test('很久以前开始的每日重复也能正确落到今天（快速跳过）', () {
      final e = event(
        start: DateTime(2000, 1, 1, 8),
        repeatRule: 'daily',
      );

      final result = starts(e, DateTime(2026, 10, 6), DateTime(2026, 10, 8));
      expect(result, <DateTime>[
        DateTime(2026, 10, 6, 8),
        DateTime(2026, 10, 7, 8),
      ]);
    });
  });

  group('每周 / 每月 / 每年', () {
    test('每周按 7 天步进', () {
      final e = event(start: DateTime(2026, 10, 5, 9), repeatRule: 'weekly');

      expect(
        starts(e, DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
        <DateTime>[
          DateTime(2026, 10, 5, 9),
          DateTime(2026, 10, 12, 9),
          DateTime(2026, 10, 19, 9),
          DateTime(2026, 10, 26, 9),
        ],
      );
    });

    test('每月保留日期；当月没有 31 号时落到月末', () {
      final e = event(start: DateTime(2026, 1, 31, 9), repeatRule: 'monthly');

      expect(
        starts(e, DateTime(2026, 2, 1), DateTime(2026, 4, 1)),
        <DateTime>[
          DateTime(2026, 2, 28, 9), // 2026 不是闰年
          DateTime(2026, 3, 31, 9),
        ],
      );
    });

    test('闰年 2 月 29 日每年重复会落到 2 月 28 日', () {
      final e = event(start: DateTime(2024, 2, 29, 12), repeatRule: 'yearly');

      expect(
        starts(e, DateTime(2025, 2, 1), DateTime(2026, 3, 1)),
        <DateTime>[
          DateTime(2025, 2, 28, 12),
          DateTime(2026, 2, 28, 12),
        ],
      );
    });
  });

  test('跨天的长事件按相交判断', () {
    final e = event(
      start: DateTime(2026, 10, 6, 22),
      duration: const Duration(hours: 4),
    );

    expect(eventOccursOn(e, DateTime(2026, 10, 7)), isTrue);
    expect(eventOccursOn(e, DateTime(2026, 10, 6)), isTrue);
    expect(eventOccursOn(e, DateTime(2026, 10, 8)), isFalse);
  });

  test('每天重复的事件在任意一天都命中', () {
    final e = event(start: DateTime(2026, 10, 5, 9), repeatRule: 'daily');

    expect(eventOccursOn(e, DateTime(2026, 10, 6)), isTrue);
    expect(eventOccursOn(e, DateTime(2026, 12, 31)), isTrue);
    expect(
      eventOccursOn(
        event(
          start: DateTime(2026, 10, 5, 9),
          repeatRule: 'daily',
          repeatUntil: DateTime(2026, 10, 6),
        ),
        DateTime(2026, 10, 7),
      ),
      isFalse,
    );
  });
}
