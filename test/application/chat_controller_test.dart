import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late FakeAiProvider ai;
  late ProviderContainer container;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  Future<void> setUpContainer(FakeAiProvider provider) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    await seedDemoDataIfEmpty(database, now: clock.now());
    ai = provider;
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        aiProviderFactoryProvider.overrideWithValue(() => ai),
      ],
    );
    addTearDown(() {
      container.dispose();
      return database.close();
    });
    // 让 persona / 配置的流先出值，避免断言受首帧时序影响。
    await container.read(personasProvider.future);
  }

  Future<List<ChatMessage>> messages() async {
    final repository = container.read(chatRepositoryProvider);
    final session = await container.read(chatSessionProvider.future);
    return repository.getMessages(session.id);
  }

  test('发送消息：用户消息与助手回复都会落库，顺序正确', () async {
    await setUpContainer(FakeAiProvider(chunks: <String>['今天', '有 3 个安排']));
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('今天有什么安排？');

    final stored = await messages();
    expect(stored, hasLength(2));
    expect(stored[0].role, ChatRole.user);
    expect(stored[0].content, '今天有什么安排？');
    expect(stored[1].role, ChatRole.assistant);
    expect(stored[1].content, '今天有 3 个安排');
    expect(container.read(chatControllerProvider).isStreaming, isFalse);
  });

  test('流式过程中状态会逐块更新（逐字输出）', () async {
    await setUpContainer(
      FakeAiProvider(
        chunks: <String>['你', '好', '呀'],
        delay: const Duration(milliseconds: 10),
      ),
    );
    final controller = container.read(chatControllerProvider.notifier);

    final seen = <String>[];
    container.listen<ChatStreamState>(chatControllerProvider, (
      ChatStreamState? previous,
      ChatStreamState next,
    ) {
      if (next.streamingText.isNotEmpty) seen.add(next.streamingText);
    });

    await controller.send('打个招呼');

    expect(seen, containsAllInOrder(<String>['你', '你好', '你好呀']));
    expect(container.read(chatControllerProvider).streamingText, isEmpty);
  });

  test('请求里带上了人设的系统提示词，并且历史消息按顺序排列', () async {
    await setUpContainer(FakeAiProvider(chunks: <String>['好']));
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('第一条');
    await controller.send('第二条');

    final request = ai.requests.last;
    expect(request.messages.first.role, AiRole.system);
    expect(request.messages.first.content, isNotEmpty);
    expect(
      request.messages.where((AiMessage m) => m.role == AiRole.user).map((m) => m.content),
      <String>['第一条', '第二条'],
    );
  });

  test('服务出错时给出可读错误，且不写入助手消息', () async {
    await setUpContainer(
      FakeAiProvider(error: const AppException('无法连接 AI 服务')),
    );
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('在吗');

    final state = container.read(chatControllerProvider);
    expect(state.error, '无法连接 AI 服务');
    expect(state.isStreaming, isFalse);

    final stored = await messages();
    expect(stored, hasLength(1), reason: '只应该有用户那条');
    expect(stored.single.role, ChatRole.user);
  });

  test('中止流式输出会保留已收到的部分', () async {
    await setUpContainer(
      FakeAiProvider(
        chunks: <String>['第一段', '第二段', '第三段'],
        delay: const Duration(milliseconds: 30),
      ),
    );
    final controller = container.read(chatControllerProvider.notifier);

    final future = controller.send('开始');
    await Future<void>.delayed(const Duration(milliseconds: 45));
    await controller.cancel();
    await future;

    final state = container.read(chatControllerProvider);
    expect(state.isStreaming, isFalse);

    final stored = await messages();
    expect(stored.last.role, ChatRole.assistant);
    expect(stored.last.content, isNotEmpty);
    expect(stored.last.content.length, lessThan(9), reason: '应当是部分内容');
  });

  test('清空对话会删除所有消息', () async {
    await setUpContainer(FakeAiProvider(chunks: <String>['好的']));
    final controller = container.read(chatControllerProvider.notifier);
    await controller.send('你好');
    expect(await messages(), hasLength(2));

    await controller.clearConversation();

    expect(await messages(), isEmpty);
  });
}
