import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/countdown_remaining.dart';

/// 规格 §4 要求重点测试：跨天 / 跨月 / 跨年 / 时区 / 夏令时 / 目标时间已过去。
///
/// 跨天、跨月、跨年、已过去见 `countdown_remaining_test.dart`；
/// 这里补时区与夏令时：倒计时始终按 **绝对时刻**（epoch）相减，
/// 而不是按"墙上时间"相减，因此夏令时切换不会让剩余时间多/少一小时。
void main() {
  group('时区', () {
    test('同一绝对时刻用 UTC 或本地时间表达，剩余时间一致', () {
      final utcNow = DateTime.utc(2026, 10, 6, 2);
      final utcTarget = DateTime.utc(2026, 10, 7, 5, 30);

      final fromUtc = CountdownRemaining.between(
        target: utcTarget,
        now: utcNow,
      );
      final fromLocal = CountdownRemaining.between(
        target: utcTarget.toLocal(),
        now: utcNow.toLocal(),
      );

      expect(fromUtc, fromLocal);
      expect(fromUtc.days, 1);
      expect(fromUtc.hours, 3);
      expect(fromUtc.minutes, 30);
    });

    test('本地时间与 UTC 混用也能算出正确的绝对差值', () {
      final localNow = DateTime(2026, 10, 6, 10);
      final utcTarget = DateTime.utc(2026, 10, 6, 4); // 本地 12:00（+8）

      final remaining = CountdownRemaining.between(
        target: utcTarget,
        now: localNow,
      );

      expect(remaining.isPast, isFalse);
      expect(remaining.hours, 2);
      expect(remaining.minutes, 0);
    });
  });

  group('夏令时', () {
    // 美国东部 2026-03-08：02:00 EST 跳到 03:00 EDT。
    // 05:00Z = 00:00 EST，08:00Z = 04:00 EDT —— 墙上时间差 4 小时，实际只有 3 小时。
    final dstStartUtc = DateTime.utc(2026, 3, 8, 5);
    final afterSpringForwardUtc = DateTime.utc(2026, 3, 8, 8);

    test('春季拨快一小时：按绝对时刻计算，不会多算一小时', () {
      final remaining = CountdownRemaining.between(
        target: afterSpringForwardUtc,
        now: dstStartUtc,
      );

      expect(remaining.days, 0);
      expect(remaining.hours, 3, reason: '墙上时间看似 4 小时，绝对时长是 3 小时');
      expect(remaining.minutes, 0);
    });

    test('夏令时当天只有 23 小时', () {
      // 2026-03-08 00:00 EST → 2026-03-09 00:00 EDT
      final dayStartUtc = DateTime.utc(2026, 3, 8, 5);
      final nextDayStartUtc = DateTime.utc(2026, 3, 9, 4);

      final remaining = CountdownRemaining.between(
        target: nextDayStartUtc,
        now: dayStartUtc,
      );

      expect(remaining.days, 0);
      expect(remaining.hours, 23);
    });

    test('秋季拨回一小时：当天有 25 小时', () {
      // 美国东部 2026-11-01：02:00 EDT 回到 01:00 EST
      final dayStartUtc = DateTime.utc(2026, 11, 1, 4); // 00:00 EDT
      final nextDayStartUtc = DateTime.utc(2026, 11, 2, 5); // 次日 00:00 EST

      final remaining = CountdownRemaining.between(
        target: nextDayStartUtc,
        now: dayStartUtc,
      );

      expect(remaining.days, 1);
      expect(remaining.hours, 1);
    });
  });

  test('目标时间正好是现在：不算已过去，且全部归零', () {
    final now = DateTime.utc(2026, 10, 6, 10);
    final remaining = CountdownRemaining.between(target: now, now: now);

    expect(remaining.isPast, isFalse);
    expect(remaining.days, 0);
    expect(remaining.hours, 0);
    expect(remaining.minutes, 0);
    expect(remaining.seconds, 0);
  });

  test('目标时间过去一整天：数值为 1 天且标记为已过去', () {
    final now = DateTime(2026, 10, 6, 10);
    final remaining = CountdownRemaining.between(
      target: now.subtract(const Duration(days: 1)),
      now: now,
    );

    expect(remaining.isPast, isTrue);
    expect(remaining.days, 1);
    expect(remaining.hours, 0);
  });
}
