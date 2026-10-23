import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/planning/daily_automation_service.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/entities/daily_digest.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/sqlite_bootstrap.dart';

class _MutableProvider implements AiProvider {
  String content = '';
  int calls = 0;

  @override
  Future<AiResponse> chat(AiChatRequest request) async {
    calls++;
    return AiResponse(content: content);
  }

  @override
  Stream<AiResponseChunk> chatStream(AiChatRequest request) =>
      const Stream<AiResponseChunk>.empty();

  @override
  Future<List<String>> listModels() async => const <String>[];
}

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late ProviderContainer container;
  late FixedClock clock;
  late _MutableProvider ai;

  AiProviderConfig config() => AiProviderConfig(
        id: 'p1',
        name: '测试',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test',
        isDefault: true,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<void> setUpContainer() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.digest.morning': true,
      'settings.digest.evening': true,
    });
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 19, 9));
    ai = _MutableProvider()
      ..content = '''
{
  "dayKey": "2026-10-19",
  "summary": "自动计划",
  "goals": [],
  "items": [],
  "unscheduledTaskIds": [],
  "conflicts": [],
  "notes": []
}
''';
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        aiProviderBuilderProvider.overrideWithValue((_) => ai),
        aiProvidersProvider.overrideWith(
          (Ref ref) => Stream<List<AiProviderConfig>>.value(
            <AiProviderConfig>[config()],
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
    await container.read(aiProvidersProvider.future);
  }

  test('早间自动生成只创建一次草稿', () async {
    await setUpContainer();
    final service = container.read(dailyAutomationServiceProvider);
    await service.runCatchUp();

    final plans = await container
        .read(dailyPlanRepositoryProvider)
        .findVersions('2026-10-19');
    expect(plans, hasLength(1));
    expect(plans.single.status.name, 'draft');
    final morning = await container
        .read(dailyDigestRepositoryProvider)
        .find('2026-10-19', DailyDigestKind.morning);
    expect(morning, isNotNull);
    expect(ai.calls, 1);

    await service.runCatchUp();
    expect(
      await container
          .read(dailyPlanRepositoryProvider)
          .findVersions('2026-10-19'),
      hasLength(1),
    );
    expect(ai.calls, 1);
  });

  test('晚间自动复盘每天只生成一次', () async {
    await setUpContainer();
    clock.setTime(DateTime(2026, 10, 19, 19));
    ai.content = '{"summary":"今日复盘","differences":[],"suggestions":["明天继续"]}';
    final service = container.read(dailyAutomationServiceProvider);
    await service.runCatchUp();

    final evening = await container
        .read(dailyDigestRepositoryProvider)
        .find('2026-10-19', DailyDigestKind.evening);
    expect(evening, isNotNull);
    expect(evening!.content, contains('今日复盘'));
    expect(ai.calls, 1);

    await service.runCatchUp();
    expect(ai.calls, 1);
  });
}
