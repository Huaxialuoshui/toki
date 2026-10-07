import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/utils/id_generator.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/scripted_ai_provider.dart';
import '../../helpers/sqlite_bootstrap.dart';

/// Phase 9：上下文按问题动态注入 + 历史裁剪不破坏工具调用协议。
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

  Future<void> addEvent(String title, DateTime start) async {
    await container.read(calendarRepositoryProvider).upsert(
          CalendarEvent(
            id: 'event-$title',
            title: title,
            startTime: start,
            endTime: start.add(const Duration(hours: 1)),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
  }

  test('请求里注入"与问题相关"的上下文，而不是整库', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      textTurn('下周你有 1 件事。'),
    ]);
    await setUpContainer(ai);
    await addEvent('今天的会议', DateTime(2026, 10, 6, 14));
    await addEvent('下周答辩', DateTime(2026, 10, 14, 15));

    await container.read(chatControllerProvider.notifier).send('我下周有什么安排？');

    final systems = ai.requests.single.messages
        .where((AiMessage message) => message.role == AiRole.system)
        .toList();
    // 第一条是人设的 system prompt，第二条是动态上下文
    expect(systems, hasLength(2));
    expect(systems.last.content, contains('当前时间'));
    expect(systems.last.content, contains('下周的日程'));
    expect(systems.last.content, contains('下周答辩'));
    expect(systems.last.content, isNot(contains('今天的会议')));
  });

  test('上下文里的倒计时也按问题筛选', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      textTurn('还有 13 天。'),
    ]);
    await setUpContainer(ai);

    await container.read(chatControllerProvider.notifier).send('距离毕业设计答辩还有多久？');

    final context = ai.requests.single.messages
        .firstWhere((AiMessage message) =>
            message.role == AiRole.system && message.content.contains('当前时间'))
        .content;
    expect(context, contains('毕业设计答辩'));
    expect(context, contains('还有 13 天'));
    expect(context, isNot(contains('生日')));
  });

  test('历史超过 40 条时从 user 消息开始裁剪，不会留下孤儿 tool 消息', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      textTurn('好的。'),
    ]);
    await setUpContainer(ai);
    final repository = container.read(chatRepositoryProvider);
    final session = await container.read(chatSessionProvider.future);

    // 造 50 条历史，其中包含一次工具调用与它的结果。
    for (var i = 0; i < 24; i++) {
      await repository.upsertMessage(
        ChatMessage(
          id: generateId('msg'),
          sessionId: session.id,
          role: ChatRole.user,
          content: '历史问题 $i',
          createdAt: clock.now().add(Duration(minutes: i * 2)),
        ),
      );
      await repository.upsertMessage(
        ChatMessage(
          id: generateId('msg'),
          sessionId: session.id,
          role: ChatRole.assistant,
          content: '历史回答 $i',
          createdAt: clock.now().add(Duration(minutes: i * 2 + 1)),
        ),
      );
    }
    await repository.upsertMessage(
      ChatMessage(
        id: 'msg-tool-call',
        sessionId: session.id,
        role: ChatRole.assistant,
        content: '',
        requestedToolCalls: const <ChatToolCall>[
          ChatToolCall(
              id: 'call-x', name: 'get_today_events', argumentsJson: '{}'),
        ],
        createdAt: clock.now().add(const Duration(hours: 1)),
      ),
    );
    await repository.upsertMessage(
      ChatMessage(
        id: 'msg-tool-result',
        sessionId: session.id,
        role: ChatRole.tool,
        content: '已完成',
        toolCallId: 'call-x',
        toolResult: '{"result":{"count":0}}',
        createdAt: clock.now().add(const Duration(hours: 1, seconds: 1)),
      ),
    );

    await container.read(chatControllerProvider.notifier).send('最后一条');

    final messages = ai.requests.single.messages
        .where((AiMessage message) => message.role != AiRole.system)
        .toList();
    expect(messages.length, lessThanOrEqualTo(41));
    expect(messages.first.role, AiRole.user);

    // 每个 tool 结果前面必须紧跟带 tool_calls 的 assistant（否则 OpenAI 会报错）
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].role != AiRole.tool) continue;
      expect(i, greaterThan(0));
      expect(messages[i - 1].role, AiRole.assistant);
      expect(messages[i - 1].toolCalls, isNotEmpty);
      expect(messages[i].toolCallId, isNotEmpty);
    }
  });
}
