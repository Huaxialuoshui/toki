import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/tool_permissions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/scripted_ai_provider.dart';
import '../../helpers/sqlite_bootstrap.dart';

/// Phase 8 的核心：模型请求工具 → 应用执行 → 结果回灌 → 模型给出最终回复。
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

  Future<List<ChatMessage>> messages() async {
    final session = await container.read(chatSessionProvider.future);
    return container.read(chatRepositoryProvider).getMessages(session.id);
  }

  test('模型请求 create_event → 应用真的创建，并把结果回灌给模型', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      toolCallTurn(
        id: 'call-1',
        name: 'create_event',
        argumentsJson:
            '{"title":"毕业答辩","start_time":"2026-10-20T15:00:00","reminder_minutes":30}',
      ),
      textTurn('已经帮你安排好了：10月20日下午3点毕业答辩，提前30分钟提醒。'),
    ]);
    await setUpContainer(ai);

    await container.read(chatControllerProvider.notifier).send(
          '帮我创建一个10月20日下午3点的毕业答辩提醒',
        );

    // 1) 数据真的写进了数据库
    final events = await container.read(calendarRepositoryProvider).getAll();
    final created = events.firstWhere((event) => event.title == '毕业答辩');
    expect(created.startTime, DateTime(2026, 10, 20, 15));

    // 2) 消息序列：user → assistant(工具请求) → tool(结果) → assistant(最终回复)
    final stored = await messages();
    expect(
        stored.map((ChatMessage message) => message.role).toList(), <ChatRole>[
      ChatRole.user,
      ChatRole.assistant,
      ChatRole.tool,
      ChatRole.assistant,
    ]);
    expect(stored[1].requestedToolCalls.single.name, 'create_event');
    expect(stored[2].toolCallId, 'call-1');
    expect(stored[2].toolResult, contains('毕业答辩'));
    expect(stored[3].content, contains('已经帮你安排好了'));

    // 3) 第二次请求里带上了工具结果，且工具定义也发给了模型
    expect(ai.requests, hasLength(2));
    expect(ai.requests.first.tools, isNotEmpty);
    final toolMessage = ai.requests[1].messages
        .firstWhere((AiMessage message) => message.role == AiRole.tool);
    expect(toolMessage.toolCallId, 'call-1');
    expect(toolMessage.content, contains('毕业答辩'));

    // 4) 状态复位
    final state = container.read(chatControllerProvider);
    expect(state.isStreaming, isFalse);
    expect(state.error, isNull);
  });

  test('未授权删除时：工具返回拒绝，数据保持不变，模型知道被拒绝', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      toolCallTurn(
        id: 'call-del',
        name: 'delete_event',
        argumentsJson: '{"event_id":"demo-event-defense"}',
      ),
      textTurn('抱歉，我没有权限删除日程。'),
    ]);
    await setUpContainer(ai);
    final before =
        (await container.read(calendarRepositoryProvider).getAll()).length;

    await container.read(chatControllerProvider.notifier).send('删掉毕业答辩');

    // 数据没变
    expect(
      (await container.read(calendarRepositoryProvider).getAll()).length,
      before,
    );

    final toolMessage = (await messages())
        .firstWhere((ChatMessage message) => message.role == ChatRole.tool);
    expect(toolMessage.toolCall?.status, ToolCallStatus.failed);
    expect(toolMessage.toolResult, contains('未授权'));
    expect(
      ai.requests[1].messages
          .firstWhere((AiMessage message) => message.role == AiRole.tool)
          .content,
      contains('未授权'),
    );
  });

  test('授权删除但用户拒绝确认：不会删除，模型收到"用户拒绝"', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      toolCallTurn(
        id: 'call-del',
        name: 'delete_event',
        argumentsJson: '{"event_id":"demo-event-defense"}',
      ),
      textTurn('好的，我没有删除。'),
    ]);
    await setUpContainer(ai);
    container.read(toolPermissionsProvider.notifier).setDelete(true);
    final before =
        (await container.read(calendarRepositoryProvider).getAll()).length;

    final controller = container.read(chatControllerProvider.notifier);
    final future = controller.send('删掉毕业答辩');

    // 等待确认请求出现，然后拒绝
    while (container.read(chatControllerProvider).pendingConfirmation == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final pending = container.read(chatControllerProvider).pendingConfirmation!;
    expect(pending.toolName, 'delete_event');
    expect(pending.arguments['event_id'], 'demo-event-defense');
    controller.resolveConfirmation(false);

    await future;

    expect(
      (await container.read(calendarRepositoryProvider).getAll()).length,
      before,
    );
    final toolMessage = (await messages())
        .firstWhere((ChatMessage message) => message.role == ChatRole.tool);
    expect(toolMessage.toolResult, contains('用户拒绝'));
    expect(container.read(chatControllerProvider).pendingConfirmation, isNull);
  });

  test('授权删除并确认后：真的删除', () async {
    final ai = ScriptedAiProvider(<List<AiResponseChunk>>[
      toolCallTurn(
        id: 'call-del',
        name: 'delete_event',
        argumentsJson: '{"event_id":"demo-event-defense"}',
      ),
      textTurn('已删除。'),
    ]);
    await setUpContainer(ai);
    container.read(toolPermissionsProvider.notifier).setDelete(true);

    final controller = container.read(chatControllerProvider.notifier);
    final future = controller.send('删掉毕业答辩');
    while (container.read(chatControllerProvider).pendingConfirmation == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    controller.resolveConfirmation(true);
    await future;

    final remaining = await container.read(calendarRepositoryProvider).getAll();
    expect(
      remaining.any((event) => event.id == 'demo-event-defense'),
      isFalse,
    );
    final toolMessage = (await messages())
        .firstWhere((ChatMessage message) => message.role == ChatRole.tool);
    expect(toolMessage.toolCall?.status, ToolCallStatus.succeeded);
  });
}
