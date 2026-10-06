import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/countdown_remaining.dart';

void main() {
  group('CountdownRemaining.between', () {
    test('拆分为天/时/分/秒', () {
      final remaining = CountdownRemaining.between(
        target: DateTime(2026, 10, 6, 12, 30, 45),
        now: DateTime(2026, 10, 5, 10, 9, 41),
      );

      expect(remaining.isPast, isFalse);
      expect(remaining.days, 1);
      expect(remaining.hours, 2);
      expect(remaining.minutes, 21);
      expect(remaining.seconds, 4);
    });

    test('跨月与跨年计算正确', () {
      final crossMonth = CountdownRemaining.between(
        target: DateTime(2026, 11, 3, 0),
        now: DateTime(2026, 10, 30, 22),
      );
      expect(crossMonth.days, 3);
      expect(crossMonth.hours, 2);

      final crossYear = CountdownRemaining.between(
        target: DateTime(2027, 1, 2, 6),
        now: DateTime(2026, 12, 31, 20),
      );
      expect(crossYear.days, 1);
      expect(crossYear.hours, 10);
    });

    test('目标时间已经过去时 isPast 为 true 且数值为绝对值', () {
      final remaining = CountdownRemaining.between(
        target: DateTime(2026, 10, 6, 8),
        now: DateTime(2026, 10, 6, 10, 30),
      );

      expect(remaining.isPast, isTrue);
      expect(remaining.hours, 2);
      expect(remaining.minutes, 30);
      expect(remaining.seconds, 0);
    });

    test('summary 只保留到分钟，用于避免秒级重建', () {
      final remaining = CountdownRemaining.between(
        target: DateTime(2026, 10, 6, 12, 30, 45),
        now: DateTime(2026, 10, 6, 12, 30, 40),
      );
      final summary = remaining.summary;

      expect(summary.days, 0);
      expect(summary.hours, 0);
      expect(summary.minutes, 0);
      expect(summary.isPast, isFalse);
    });
  });
}
