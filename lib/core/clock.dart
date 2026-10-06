/// 时钟抽象。
///
/// 所有与"当前时间"相关的计算都必须经过 [Clock]，这样单元测试与 Widget
/// 测试可以注入 [FixedClock]，避免依赖真实时间导致测试不稳定。
abstract class Clock {
  const Clock();

  DateTime now();
}

/// 生产环境使用的系统时钟。
class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// 测试用固定时钟：时间只会在显式调用 [advance] / [setTime] 时变化。
class FixedClock extends Clock {
  FixedClock(DateTime initial) : _current = initial;

  DateTime _current;

  @override
  DateTime now() => _current;

  void setTime(DateTime value) => _current = value;

  void advance(Duration duration) => _current = _current.add(duration);
}
