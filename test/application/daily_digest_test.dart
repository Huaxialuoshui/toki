import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/application/ai/daily_digest_service.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/entities/daily_digest.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/sqlite_bootstrap.dart';

/// AI 每日计划 / 每日总结（规格 §14）。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late FakeAiProvider ai;
  late ProviderContainer container;
  late AppSettingsStore store;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 7, 9));

  AiProviderConfig aiConfig() => AiProviderConfig(
        id: 'p1',
        name: '测试',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test',
        isDefault: true,
        createdAt: DateTime(2026, 10, 7),
        updatedAt: DateTime(2026, 10, 7),
      );

  Future<void> setUpContainer({bool withProvider = true}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    store = AppSettingsStore(preferences);
    database = AppDatabase.memory();
    await seedDemoDataIfEmpty(database, now: clock.now());
    ai = FakeAiProvider(chunks: <String>['## 今日计划\n- 15:00 答辩']);
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        aiProviderFactoryProvider.overrideWithValue(() => ai),
        aiProviderBuilderProvider.overrideWithValue((_) => ai),
        if (withProvider)
          aiProvidersProvider.overrideWith(
            (Ref ref) => Stream<List<AiProviderConfig>>.value(
              <AiProviderConfig>[aiConfig()],
            ),
          ),
      ],
    );
    addTearDown(() {
      container.dispose();
      return database.close();
    });
    // 让服务商配置的流先出值。
    await container.read(aiProvidersProvider.future);
  }

  test('默认关闭：ensureToday 不生成，也不请求 AI', () async {
    await setUpContainer();
    final service = container.read(dailyDigestServiceProvider);

    expect(service.isEnabled(DailyDigestKind.morning), isFalse);
    expect(await service.ensureToday(DailyDigestKind.morning), isNull);
    expect(ai.requests, isEmpty);
  });

  test('打开开关后生成一条并落库', () async {
    await setUpContainer();
    final service = container.read(dailyDigestServiceProvider);
    await service.setEnabled(DailyDigestKind.morning, true);

    final digest = await service.ensureToday(DailyDigestKind.morning);

    expect(digest, isNotNull);
    expect(digest!.kind, DailyDigestKind.morning);
    expect(digest.dayKey, '2026-10-07');
    expect(digest.content, contains('今日计划'));
    expect(ai.requests, hasLength(1));
    // 请求里带上了"今天"的上下文
    expect(
      ai.requests.single.messages.last.content,
      contains('2026-10-07'),
    );
  });

  test('同一天再次 ensureToday 复用已有结果，不重复请求', () async {
    await setUpContainer();
    final service = container.read(dailyDigestServiceProvider);
    await service.setEnabled(DailyDigestKind.morning, true);

    final first = await service.ensureToday(DailyDigestKind.morning);
    clock.advance(const Duration(hours: 2));
    final second = await service.ensureToday(DailyDigestKind.morning);

    expect(second!.id, first!.id);
    expect(ai.requests, hasLength(1));
  });

  test('手动重新生成会覆盖同一天的那条，不会留下两条', () async {
    await setUpContainer();
    final service = container.read(dailyDigestServiceProvider);
    await service.setEnabled(DailyDigestKind.evening, true);
    final first = await service.ensureToday(DailyDigestKind.evening);

    ai.chunks.clear();
    ai.chunks.add('## 今日总结\n- 完成了答辩');
    final second = await service.generate(DailyDigestKind.evening);

    expect(second.id, first!.id);
    final rows = await container
        .read(dailyDigestRepositoryProvider)
        .findByDay('2026-10-07');
    expect(rows, hasLength(1));
    expect(rows.single.content, contains('今日总结'));
  });

  test('没配置服务商时给出可读错误，不写半条数据', () async {
    await setUpContainer(withProvider: false);
    final service = container.read(dailyDigestServiceProvider);

    await expectLater(
      service.generate(DailyDigestKind.morning),
      throwsA(isA<AppException>()),
    );
    expect(
      await container
          .read(dailyDigestRepositoryProvider)
          .findByDay('2026-10-07'),
      isEmpty,
    );
  });

  test('开关写进 shared_preferences', () async {
    await setUpContainer();
    final service = container.read(dailyDigestServiceProvider);

    await service.setEnabled(DailyDigestKind.evening, true);
    expect(store.readEveningDigestEnabled(), isTrue);
    expect(store.readMorningDigestEnabled(), isFalse);

    await service.setEnabled(DailyDigestKind.evening, false);
    expect(store.readEveningDigestEnabled(), isFalse);
  });
}
