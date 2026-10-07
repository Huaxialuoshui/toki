import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/sqlite_bootstrap.dart';

/// 单条消息操作（规格 §12）：复制（UI 层）/ 重新生成 / 编辑并重发 / 删除。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late FakeAiProvider ai;
  late ProviderContainer container;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 7, 9));

  Future<void> setUpContainer({List<String>? chunks}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    await seedDemoDataIfEmpty(database, now: clock.now());
    ai = FakeAiProvider(chunks: chunks ?? <String>['回复']);
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
    await container.read(personasProvider.future);
  }

  Future<List<ChatMessage>> messages() async {
    final session = await container.read(chatSessionProvider.future);
    return container.read(chatRepositoryProvider).getMessages(session.id);
  }

  test('删除单条消息只影响那一条', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('第一问');
    await controller.send('第二问');
    final before = await messages();
    expect(before, hasLength(4));

    final assistant = before.firstWhere(
      (ChatMessage m) => m.role == ChatRole.assistant,
    );
    await controller.deleteMessage(assistant.id);

    final after = await messages();
    expect(after, hasLength(3));
    expect(after.map((ChatMessage m) => m.id), isNot(contains(assistant.id)));
  });

  test('重新生成：删掉这条助手消息及其后的消息，用同一个问题重跑', () async {
    await setUpContainer(chunks: <String>['第一版回答']);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('今天有什么安排？');
    var history = await messages();
    expect(history, hasLength(2));
    final firstAssistant = history.last;
    expect(firstAssistant.content, '第一版回答');
    expect(ai.requests, hasLength(1));

    // 换成新的回答内容再重新生成
    ai.chunks.clear();
    ai.chunks.add('第二版回答');
    await controller.regenerateFrom(firstAssistant.id);

    history = await messages();
    expect(history, hasLength(2), reason: '用户消息保留，助手消息被替换');
    expect(history.first.role, ChatRole.user);
    expect(history.first.content, '今天有什么安排？');
    expect(history.last.content, '第二版回答');
    expect(ai.requests, hasLength(2));
    // 重跑时请求里带的是同一条用户问题
    expect(
      ai.requests.last.messages
          .where((AiMessage m) => m.role == AiRole.user)
          .map((AiMessage m) => m.content),
      contains('今天有什么安排？'),
    );
  });

  test('重新生成会把它之后的消息一起删掉', () async {
    await setUpContainer(chunks: <String>['回答']);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('第一问');
    final firstAssistant = (await messages()).last;
    await controller.send('第二问');
    expect(await messages(), hasLength(4));

    ai.chunks.clear();
    ai.chunks.add('重答');
    await controller.regenerateFrom(firstAssistant.id);

    final history = await messages();
    expect(history, hasLength(2), reason: '第二问及其回复都应被删掉');
    expect(history.last.content, '重答');
  });

  test('编辑并重发：更新用户消息内容，删掉后续消息后重跑', () async {
    await setUpContainer(chunks: <String>['旧回答']);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('原始问题');
    await controller.send('后面一句');
    expect(await messages(), hasLength(4));

    final firstUser = (await messages()).first;
    ai.chunks.clear();
    ai.chunks.add('新回答');
    await controller.editAndResend(firstUser.id, '改过的问题');

    final history = await messages();
    expect(history, hasLength(2));
    expect(history.first.content, '改过的问题');
    expect(history.last.content, '新回答');
    expect(ai.requests.last.messages.last.content, '改过的问题');
  });

  test('编辑成空内容时什么都不做', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('原始问题');
    final firstUser = (await messages()).first;
    await controller.editAndResend(firstUser.id, '   ');

    expect(await messages(), hasLength(2));
    expect((await messages()).first.content, '原始问题');
  });
}
