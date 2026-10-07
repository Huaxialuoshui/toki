import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/entities/chat_session.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/sqlite_bootstrap.dart';

/// 多会话（规格 §12）：新建 / 切换 / 删除 / 自动标题 / 消息隔离。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late FakeAiProvider ai;
  late ProviderContainer container;
  late SharedPreferences preferences;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 7, 9));

  Future<void> setUpContainer({String reply = '好的'}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    await seedDemoDataIfEmpty(database, now: clock.now());
    ai = FakeAiProvider(chunks: <String>[reply]);
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

  Future<List<ChatMessage>> messagesOf(String sessionId) =>
      container.read(chatRepositoryProvider).getMessages(sessionId);

  Future<ChatSession> currentSession() =>
      container.read(chatSessionProvider.future);

  test('首次使用会自动建一个默认会话', () async {
    await setUpContainer();

    final session = await currentSession();
    expect(session.id, kDefaultChatSessionId);
    expect(session.title, kDefaultChatSessionTitle);
    expect(await container.read(chatRepositoryProvider).getSessions(),
        hasLength(1));
  });

  test('新建会话会切过去，且两个会话的消息互不干扰', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('第一个会话的问题');
    final first = await currentSession();
    expect(await messagesOf(first.id), hasLength(2));

    await controller.createSession('新会话');
    final second = await currentSession();
    expect(second.id, isNot(first.id));
    expect(await messagesOf(second.id), isEmpty, reason: '新会话应当是空的');

    await controller.send('第二个会话的问题');
    expect(await messagesOf(second.id), hasLength(2));
    expect(await messagesOf(first.id), hasLength(2), reason: '旧会话不受影响');

    // 切回去还能看到原来的消息
    await controller.switchSession(first.id);
    expect((await currentSession()).id, first.id);
    expect(await messagesOf(first.id), hasLength(2));
  });

  test('会话列表按最近更新排序，发消息会把会话顶到前面', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    final first = await currentSession();
    clock.advance(const Duration(minutes: 1));
    await controller.createSession('第二个');
    final second = await currentSession();

    clock.advance(const Duration(minutes: 1));
    await controller.switchSession(first.id);
    await controller.send('把这个会话顶上去');

    final sessions = await container.read(chatRepositoryProvider).getSessions();
    expect(sessions.first.id, first.id);
    expect(sessions.map((ChatSession s) => s.id), contains(second.id));
  });

  test('首条消息会把默认标题改成摘要，之后再发不改标题', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('帮我看看明天下午的安排，谢谢');
    final first = await currentSession();
    var stored =
        await container.read(chatRepositoryProvider).findSession(first.id);
    expect(stored!.title, '帮我看看明天下午的安排，谢谢');

    await controller.send('再补充一个问题');
    stored = await container.read(chatRepositoryProvider).findSession(first.id);
    expect(stored!.title, '帮我看看明天下午的安排，谢谢');
  });

  test('很长的首条消息标题会被截断', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    await controller.send('一' * 40);
    final session = await currentSession();
    final stored =
        await container.read(chatRepositoryProvider).findSession(session.id);
    expect(stored!.title.length, 21);
    expect(stored.title.endsWith('…'), isTrue);
  });

  test('删除会话会连带删除消息；删掉当前会话后切到最近的', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    final first = await currentSession();
    await controller.send('第一个');
    await controller.createSession('第二个');
    final second = await currentSession();
    await controller.send('第二个');

    await controller.deleteSession(second.id);

    expect(await messagesOf(second.id), isEmpty);
    final sessions = await container.read(chatRepositoryProvider).getSessions();
    expect(sessions.map((ChatSession s) => s.id), isNot(contains(second.id)));
    expect((await currentSession()).id, first.id, reason: '应回落到剩下的会话');
  });

  test('删掉最后一个会话后会重新建一个可用的会话', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    final only = await currentSession();
    await controller.deleteSession(only.id);

    final next = await currentSession();
    expect(next.id, isNotEmpty, reason: '删光之后应当还能继续聊天');
    final sessions = await container.read(chatRepositoryProvider).getSessions();
    expect(sessions, hasLength(1));
    expect(await messagesOf(next.id), isEmpty);
  });

  test('当前会话 id 会写进 shared_preferences', () async {
    await setUpContainer();
    final controller = container.read(chatControllerProvider.notifier);

    await controller.createSession('第二个');
    final second = await currentSession();

    expect(preferences.getString('settings.chatSessionId'), second.id);
  });
}
