import 'package:flutter/foundation.dart';

/// 倒计时剩余时间（值对象）。
///
/// 永远由 `targetTime - now` 实时计算，**不持久化**（规格 §5）。
@immutable
class CountdownRemaining {
  const CountdownRemaining({
    required this.isPast,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  /// 计算 [target] 相对 [now] 的剩余时间；目标时间已过时 [isPast] 为 true。
  factory CountdownRemaining.between({
    required DateTime target,
    required DateTime now,
  }) {
    final difference = target.difference(now);
    final absolute = difference.abs();
    return CountdownRemaining(
      isPast: difference.isNegative,
      days: absolute.inDays,
      hours: absolute.inHours % Duration.hoursPerDay,
      minutes: absolute.inMinutes % Duration.minutesPerHour,
      seconds: absolute.inSeconds % Duration.secondsPerMinute,
    );
  }

  final bool isPast;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  /// 只到分钟粒度的摘要，供不需要秒级刷新的组件订阅。
  CountdownSummary get summary => CountdownSummary(
        isPast: isPast,
        days: days,
        hours: hours,
        minutes: minutes,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountdownRemaining &&
        other.isPast == isPast &&
        other.days == days &&
        other.hours == hours &&
        other.minutes == minutes &&
        other.seconds == seconds;
  }

  @override
  int get hashCode => Object.hash(isPast, days, hours, minutes, seconds);

  @override
  String toString() =>
      'CountdownRemaining(past: $isPast, ${days}d ${hours}h ${minutes}m ${seconds}s)';
}

/// 分钟粒度的倒计时摘要。
@immutable
class CountdownSummary {
  const CountdownSummary({
    required this.isPast,
    required this.days,
    required this.hours,
    required this.minutes,
  });

  final bool isPast;
  final int days;
  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountdownSummary &&
        other.isPast == isPast &&
        other.days == days &&
        other.hours == hours &&
        other.minutes == minutes;
  }

  @override
  int get hashCode => Object.hash(isPast, days, hours, minutes);

  @override
  String toString() =>
      'CountdownSummary(past: $isPast, ${days}d ${hours}h ${minutes}m)';
}
