import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/countdown_remaining.dart';
import '../../infrastructure/clock_provider.dart';

/// 全应用共享的倒计时控制器。
///
/// 设计要点（规格 §7）：
/// * 只有**一个** 1Hz 节拍源，页面与卡片都不允许自己开 `Timer`；
/// * 剩余时间永远由 `targetTime - now` 计算，不持久化；
/// * 时间来源于可注入的 [Clock]，测试可以用 `FixedClock` 得到确定结果。
class CountdownController {
  CountdownController({
    required Clock clock,
    Duration tickInterval = AppConstants.countdownTick,
  })  : _clock = clock,
        _tickInterval = tickInterval;

  final Clock _clock;
  final Duration _tickInterval;

  StreamController<DateTime>? _tickController;
  Timer? _timer;
  bool _disposed = false;

  DateTime get now => _clock.now();

  /// 节拍是否正在运行（测试用来断言没有 Timer 泄漏）。
  bool get hasActiveTicker => _timer != null;

  CountdownRemaining remainingFor(DateTime target) =>
      CountdownRemaining.between(target: target, now: _clock.now());

  /// 唯一的 1Hz 节拍流；订阅开始时才创建 Timer，最后一个订阅者离开时停止。
  ///
  /// 使用 broadcast：首页与倒计时页可以同时订阅同一个节拍源，仍然只有一个
  /// Timer 在运行。
  Stream<DateTime> get ticks {
    assert(!_disposed, 'CountdownController 已被释放，不能再订阅。');
    final existing = _tickController;
    if (existing != null) return existing.stream;

    final controller = StreamController<DateTime>.broadcast();
    controller.onListen = () {
      if (_disposed) return;
      // broadcast 流的订阅尚未完成时 add 会丢掉事件，因此首帧用 microtask 推送。
      scheduleMicrotask(() {
        if (_disposed || controller.isClosed) return;
        controller.add(_clock.now());
      });
      _timer = Timer.periodic(_tickInterval, (_) {
        if (!controller.isClosed) controller.add(_clock.now());
      });
    };
    controller.onCancel = () {
      _timer?.cancel();
      _timer = null;
    };
    _tickController = controller;
    return controller.stream;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    final controller = _tickController;
    _tickController = null;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }
}

/// 应用级生命周期：最后一个监听者离开后自动释放节拍 Timer。
final countdownControllerProvider =
    Provider.autoDispose<CountdownController>((ref) {
  final controller = CountdownController(clock: ref.watch(clockProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

/// 共享节拍流。
final countdownTickProvider = StreamProvider.autoDispose<DateTime>((ref) {
  return ref.watch(countdownControllerProvider).ticks;
});

/// 某个目标时间的实时剩余量。
///
/// 组件请用 `select` 只订阅自己需要的粒度（例如 `summary` 或 `seconds`），
/// 这样秒数变化不会导致整张卡片重建。
final countdownRemainingProvider =
    StreamProvider.autoDispose.family<CountdownRemaining, DateTime>(
  (ref, target) {
    final controller = ref.watch(countdownControllerProvider);
    return controller.ticks.map(
      (tick) => CountdownRemaining.between(target: target, now: tick),
    );
  },
);
