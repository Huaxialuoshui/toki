import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/application/ai/persona_prompt.dart';
import 'package:toki/application/ai/tool_permissions.dart';
import 'package:toki/application/ai/tools/tool_registry.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/ai_persona.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/scripted_ai_provider.dart';
import '../../helpers/sqlite_bootstrap.dart';

/// 人设的「作为日历助手」开关。
///
/// 关掉之后就是纯聊天 / 扮演：不注入日程上下文、不给任何工具，
/// 只保留用户自己写的系统提示词。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late ProviderContainer container;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  Future<void> setUpContainer(ScriptedAiProvider provider) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    await seedDemoDataIfEmpty(database, now: clock.now());
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        aiProviderFactoryProvider.overrideWithValue(() => provider),
      ],
    );
    addTearDown(() {
      container.dispose();
      return database.close();
    });
    await container.read(personasProvider.future);
  }

  /// 等人设流刷到满足条件的那一版（upsert 之后立即发消息会读到旧值）。
  Future<void> waitForPersonas(
    bool Function(List<AiPersona> personas) ready,
  ) async {
    final completer = Completer<void>();
    final subscription = container.listen<AsyncValue<List<AiPersona>>>(
      personasProvider,
      (AsyncValue<List<AiPersona>>? _, AsyncValue<List<AiPersona>> next) {
        final personas = next.valueOrNull;
        if (personas != null && ready(personas) && !completer.isCompleted) {
          completer.complete();
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await completer.future;
  }

  /// 把当前会话用的人设改成"纯聊天"。
  Future<void> makeChatOnly({required String systemPrompt}) async {
    final persona = (await container.read(personasProvider.future)).first;
    await container.read(aiPersonaRepositoryProvider).upsert(
          persona.copyWith(
            calendarAssistantEnabled: false,
            systemPrompt: systemPrompt,
          ),
        );
    await waitForPersonas(
      (List<AiPersona> personas) =>
          personas.any((AiPersona item) => !item.calendarAssistantEnabled),
    );
  }

  Future<void> addEventToday(String title) async {
    await container.read(calendarRepositoryProvider).upsert(
          CalendarEvent(
            id: 'event-$title',
            title: title,
            startTime: DateTime(2026, 10, 6, 14),
            endTime: DateTime(2026, 10, 6, 15),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
  }

  List<AiMessage> systemsOf(AiChatRequest request) => request.messages
      .where((AiMessage message) => message.role == AiRole.system)
      .toList();

  test('默认人设是日历助手：仍然注入日程上下文并提供工具', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[textTurn('好的。')]);
    await setUpContainer(ai);
    await addEventToday('今天的会议');

    await container.read(chatControllerProvider.notifier).send('今天有什么安排？');

    final request = ai.requests.single;
    final systems = systemsOf(request);
    // 第一条是人设提示词，第二条是动态日程上下文。
    expect(systems, hasLength(2));
    expect(systems.last.content, contains('当前时间'));
    expect(systems.last.content, contains('今天的日程'));
    expect(request.tools, isNotEmpty);
  });

  test('纯聊天人设：不注入日程上下文，只用自己的提示词', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[textTurn('（喵）')]);
    await setUpContainer(ai);
    await addEventToday('今天的会议');
    await makeChatOnly(systemPrompt: '你是猫娘助手，不管日程，只用喵喵叫回应。');

    await container.read(chatControllerProvider.notifier).send('今天有什么安排？');

    final request = ai.requests.single;
    expect(request.tools, isEmpty);
    final systems = systemsOf(request);
    expect(systems, hasLength(1));
    expect(systems.single.content, '你是猫娘助手，不管日程，只用喵喵叫回应。');

    // 整条请求里不该出现任何日程数据 / 当前时间。
    final joined =
        request.messages.map((AiMessage message) => message.content).join('\n');
    expect(joined, isNot(contains('当前时间')));
    expect(joined, isNot(contains('今天的日程')));
    expect(joined, isNot(contains('今天的会议')));
  });

  test('纯聊天人设没写提示词时，一条 system 消息都不注入', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[textTurn('在的。')]);
    await setUpContainer(ai);
    await makeChatOnly(systemPrompt: '   ');

    await container.read(chatControllerProvider.notifier).send('在吗');

    expect(systemsOf(ai.requests.single), isEmpty);
  });

  test('工具注册表对纯聊天人设一个工具都不给', () async {
    await setUpContainer(
      ScriptedAiProvider(<List<AiResponseChunk>>[textTurn('好的。')]),
    );
    final registry = container.read(aiToolRegistryProvider);
    const ToolPermissions permissions = ToolPermissions(allowDelete: true);
    final now = clock.now();

    final chatOnly = AiPersona(
      id: 'p-chat',
      name: '猫娘',
      calendarAssistantEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
    expect(
      registry.allowedTools(permissions: permissions, persona: chatOnly),
      isEmpty,
    );
    expect(
      registry.definitions(permissions: permissions, persona: chatOnly),
      isEmpty,
    );

    // 兜底人设（persona == null）和日历助手人设照旧有工具。
    expect(
      registry.allowedTools(permissions: permissions, persona: null),
      isNotEmpty,
    );
    expect(
      registry.allowedTools(
        permissions: permissions,
        persona: chatOnly.copyWith(calendarAssistantEnabled: true),
      ),
      isNotEmpty,
    );
  });

  test('「作为日历助手」会写进数据库并读回来', () async {
    await setUpContainer(
      ScriptedAiProvider(<List<AiResponseChunk>>[textTurn('好的。')]),
    );
    final repository = container.read(aiPersonaRepositoryProvider);
    final now = clock.now();

    await repository.upsert(
      AiPersona(
        id: 'p-chat',
        name: '猫娘',
        systemPrompt: '只用喵喵叫回应。',
        calendarAssistantEnabled: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final stored = (await repository.findById('p-chat'))!;
    expect(stored.calendarAssistantEnabled, isFalse);
    expect(PersonaPrompt.usesCalendar(stored), isFalse);
    expect(PersonaPrompt.systemPromptOf(stored), '只用喵喵叫回应。');

    // 示例人设没动过：仍然是日历助手。
    final seeded =
        (await container.read(personasProvider.future)).firstWhere(
              (AiPersona item) => item.id != 'p-chat',
            );
    expect(seeded.calendarAssistantEnabled, isTrue);
    expect(PersonaPrompt.isCalendarAssistant(seeded), isTrue);
  });
}
