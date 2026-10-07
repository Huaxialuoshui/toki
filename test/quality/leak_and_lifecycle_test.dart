import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/app/app.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/application/app_startup.dart';
import 'package:toki/application/countdown/countdown_controller.dart';
import 'package:toki/application/notification/notification_providers.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/fake_notification_service.dart';
import '../helpers/sqlite_bootstrap.dart';

/// Phase 13 质量清单：Timer 泄漏 / 订阅释放 / 数据库连接生命周期。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  test('倒计时节拍：最后一个订阅者离开后 Timer 会被取消', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // autoDispose 的 provider：没有 provider 级监听时会被回收（连带停掉 Timer），
    // 所以先订阅 provider 本身，模拟"页面正在用它"。
    final keepAlive = container.listen(countdownControllerProvider, (_, __) {});
    addTearDown(keepAlive.close);

    final controller = container.read(countdownControllerProvider);
    expect(controller.hasActiveTicker, isFalse);

    final ticks = <DateTime>[];
    final subscription = controller.ticks.listen(ticks.add);
    // 节拍是 1Hz：等一个完整周期，确保 Timer 真的在跑。
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(controller.hasActiveTicker, isTrue);
    expect(ticks, isNotEmpty);

    await subscription.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(controller.hasActiveTicker, isFalse, reason: '取消订阅后 Timer 应停止');

    final before = ticks.length;
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(ticks.length, before, reason: '停止后不应再产生节拍');
  });

  test('聊天流式输出中释放容器，订阅会被取消', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase.memory();
    await seedDemoDataIfEmpty(database, now: DateTime(2026, 10, 7, 9));
    final ai = _CancellableAiProvider();

    final container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 7, 9))),
        appDatabaseProvider.overrideWithValue(database),
        demoSeedEnabledProvider.overrideWithValue(false),
        aiProviderFactoryProvider.overrideWithValue(() => ai),
      ],
    );

    final controller = container.read(chatControllerProvider.notifier);
    unawaited(controller.send('你好'));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(ai.cancelCount, 0, reason: '此刻还在流式输出');

    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(ai.cancelCount, greaterThan(0), reason: 'dispose 时应取消订阅');
    await database.close();
  });

  test('数据库：关闭再打开同一个文件，数据还在', () async {
    final directory = await Directory.systemTemp.createTemp('toki-db-reopen');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File('${directory.path}/toki.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await seedDemoDataIfEmpty(first, now: DateTime(2026, 10, 7, 9));
    final before = await first.select(first.calendarEvents).get();
    final countdownsBefore = await first.select(first.countdowns).get();
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    final after = await second.select(second.calendarEvents).get();
    final countdownsAfter = await second.select(second.countdowns).get();
    await second.close();

    expect(before, isNotEmpty);
    expect(after.length, before.length);
    expect(after.first.title, before.first.title);
    expect(countdownsAfter.length, countdownsBefore.length);
  });

  testWidgets('反复切换五个页面后不残留 Timer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final database = AppDatabase.memory();
    await tester.binding.setSurfaceSize(const Size(1400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 7, 9))),
          appDatabaseProvider.overrideWithValue(database),
          demoSeedEnabledProvider.overrideWithValue(false),
          notificationServiceProvider
              .overrideWithValue(FakeNotificationService()),
          aiProviderFactoryProvider.overrideWithValue(() => FakeAiProvider()),
        ],
        child: const TokiApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    for (var round = 0; round < 3; round++) {
      for (final String route in const <String>[
        '/calendar',
        '/countdown',
        '/ai',
        '/settings',
        '/home',
      ]) {
        await tester.tap(find.byKey(ValueKey<String>('sidebar-tile-$route')));
        await tester.pump(const Duration(milliseconds: 80));
      }
    }

    // 卸载整棵树：若还有 Timer 没释放，flutter_test 会在收尾时报错。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 80));

    var closed = false;
    unawaited(database.close().whenComplete(() => closed = true));
    for (var i = 0; i < 20 && !closed; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  });
}

/// 一直不结束的假 AI：只有订阅被取消才会停下，用来验证订阅确实被释放。
class _CancellableAiProvider implements AiProvider {
  int cancelCount = 0;

  @override
  Future<AiResponse> chat(AiChatRequest request) async =>
      const AiResponse(content: 'ok');

  @override
  Stream<AiResponseChunk> chatStream(AiChatRequest request) {
    final controller = StreamController<AiResponseChunk>(
      onCancel: () => cancelCount++,
    );
    controller.add(const AiResponseChunk(delta: '思'));
    return controller.stream;
  }

  @override
  Future<List<String>> listModels() async => const <String>[];
}
