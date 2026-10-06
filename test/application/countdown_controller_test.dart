import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/countdown/countdown_controller.dart';
import 'package:toki/core/clock.dart';

void main() {
  group('CountdownController', () {
    test('使用唯一 1Hz 节拍，订阅时立即推送一次，取消后停止', () {
      fakeAsync((async) {
        final clock = FixedClock(DateTime(2026, 10, 6, 10));
        final controller = CountdownController(clock: clock);
        final ticks = <DateTime>[];

        final subscription = controller.ticks.listen(ticks.add);
        async.flushMicrotasks();

        expect(ticks, hasLength(1), reason: '订阅后立即给一次当前时间');
        expect(controller.hasActiveTicker, isTrue);
        expect(async.periodicTimerCount, 1, reason: '整个控制器只有一个 Timer');

        async.elapse(const Duration(seconds: 3));
        expect(ticks, hasLength(4));

        subscription.cancel();
        async.flushMicrotasks();
        expect(controller.hasActiveTicker, isFalse);
        expect(async.periodicTimerCount, 0, reason: '没有订阅者后不应残留 Timer');

        controller.dispose();
      });
    });

    test('多次订阅共享同一个节拍源', () {
      fakeAsync((async) {
        final controller =
            CountdownController(clock: FixedClock(DateTime(2026, 10, 6, 10)));
        final first = <DateTime>[];
        final second = <DateTime>[];

        final subA = controller.ticks.listen(first.add);
        final subB = controller.ticks.listen(second.add);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));

        expect(async.periodicTimerCount, 1);
        expect(first, hasLength(3));
        expect(second, hasLength(3));

        subA.cancel();
        subB.cancel();
        async.flushMicrotasks();
        controller.dispose();
        expect(async.periodicTimerCount, 0);
      });
    });

    test('remainingFor 始终基于目标时间与当前时间实时计算', () {
      final clock = FixedClock(DateTime(2026, 10, 6, 10));
      final controller = CountdownController(clock: clock);
      final target = DateTime(2026, 10, 6, 12, 30);

      expect(controller.remainingFor(target).hours, 2);
      expect(controller.remainingFor(target).minutes, 30);

      clock.advance(const Duration(hours: 3));
      final afterTarget = controller.remainingFor(target);
      expect(afterTarget.isPast, isTrue);
      expect(afterTarget.minutes, 30);

      controller.dispose();
    });
  });
}
