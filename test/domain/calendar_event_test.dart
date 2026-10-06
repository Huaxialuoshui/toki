import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/calendar_event.dart';

void main() {
  CalendarEvent buildEvent(DateTime start, DateTime end) => CalendarEvent(
        id: 'e1',
        title: 'event',
        startTime: start,
        endTime: end,
        createdAt: start,
        updatedAt: start,
      );

  group('CalendarEvent.occursOn', () {
    test('当天事件匹配', () {
      final event = buildEvent(
        DateTime(2026, 10, 6, 15),
        DateTime(2026, 10, 6, 16, 30),
      );
      expect(event.occursOn(DateTime(2026, 10, 6, 3)), isTrue);
    });

    test('跨天事件在两天都算命中', () {
      final event = buildEvent(
        DateTime(2026, 10, 6, 23),
        DateTime(2026, 10, 7, 1),
      );
      expect(event.occursOn(DateTime(2026, 10, 6)), isTrue);
      expect(event.occursOn(DateTime(2026, 10, 7)), isTrue);
      expect(event.occursOn(DateTime(2026, 10, 8)), isFalse);
    });

    test('不在范围内的日期不命中', () {
      final event = buildEvent(
        DateTime(2026, 10, 20, 15),
        DateTime(2026, 10, 20, 16),
      );
      expect(event.occursOn(DateTime(2026, 10, 19)), isFalse);
      expect(event.occursOn(DateTime(2026, 10, 21)), isFalse);
    });
  });
}
