import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/chat_session.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/test_app.dart';

/// AI 页的消息操作与会话管理（P0：多会话 + 消息级操作 + Markdown）。
void main() {
  const Size surface = Size(1400, 1600);

  AiProviderConfig config() => AiProviderConfig(
        id: 'p-test',
        name: '测试服务商',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test-model',
        isDefault: true,
        createdAt: DateTime(2026, 10, 7),
        updatedAt: DateTime(2026, 10, 7),
      );

  Future<void> openAi(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('sidebar-tile-/ai')));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).last, text);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  /// 剪贴板在测试里没有默认实现。
  List<MethodCall> mockClipboard(WidgetTester tester) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return calls;
  }

  tokiWidgetTest('助手回复按 Markdown 渲染（标题 / 列表 / 代码块）', (tester) async {
    final ai = FakeAiProvider(
      chunks: <String>['## 今日安排\n- 15:00 答辩\n\n```dart\nfinal a = 1;\n```'],
    );
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiProvider: ai,
      aiConfig: config(),
    );
    await openAi(tester);
    await send(tester, '今天有什么安排？');

    expect(find.textContaining('今日安排'), findsWidgets);
    expect(find.text('15:00 答辩'), findsOneWidget);
    expect(find.textContaining('final a = 1;'), findsOneWidget);
    expect(find.textContaining('##'), findsNothing);
  });

  tokiWidgetTest('长按消息弹出操作菜单，复制会写进剪贴板', (tester) async {
    final calls = mockClipboard(tester);
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiConfig: config(),
      aiProvider: FakeAiProvider(chunks: <String>['这是回复内容']),
    );
    await openAi(tester);
    await send(tester, '你好');

    await tester.longPress(find.text('这是回复内容'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Regenerate'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('ai-msg-copy')));
    await tester.pumpAndSettle();

    final setData = calls.firstWhere(
      (MethodCall call) => call.method == 'Clipboard.setData',
    );
    expect((setData.arguments as Map)['text'], '这是回复内容');
    expect(find.text('Copied'), findsOneWidget);
  });

  tokiWidgetTest('用户消息可以编辑并重发', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiConfig: config(),
      aiProvider: FakeAiProvider(chunks: <String>['回答']),
    );
    await openAi(tester);
    await send(tester, '原始问题');

    await tester.longPress(find.text('原始问题'));
    await tester.pumpAndSettle();
    expect(find.text('Edit and resend'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('ai-msg-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '改过的问题');
    await tester.tap(find.byKey(const ValueKey<String>('ai-edit-save')));
    await tester.pumpAndSettle();

    expect(find.text('改过的问题'), findsOneWidget);
    expect(find.text('原始问题'), findsNothing);
  });

  tokiWidgetTest('删除单条消息', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiConfig: config(),
      aiProvider: FakeAiProvider(chunks: <String>['这条会被删掉']),
    );
    await openAi(tester);
    await send(tester, '你好');

    final container = containerOf(tester);
    final session = await container.read(chatSessionProvider.future);
    expect(
      await container.read(chatRepositoryProvider).getMessages(session.id),
      hasLength(2),
    );

    await tester.longPress(find.text('这条会被删掉'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('ai-msg-delete')));
    await tester.pumpAndSettle();

    expect(find.text('这条会被删掉'), findsNothing);
    expect(
      await container.read(chatRepositoryProvider).getMessages(session.id),
      hasLength(1),
    );
  });

  tokiWidgetTest('会话列表：新建会话后聊天区是空的', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiConfig: config(),
      aiProvider: FakeAiProvider(chunks: <String>['第一个会话的回复']),
    );
    await openAi(tester);
    await send(tester, '第一个会话');
    expect(find.text('第一个会话的回复'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('ai-sessions')));
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('ai-new-session')));
    await tester.pumpAndSettle();

    expect(find.text('第一个会话的回复'), findsNothing, reason: '新会话应当是空的');

    final container = containerOf(tester);
    final sessions = await container.read(chatRepositoryProvider).getSessions();
    expect(sessions, hasLength(2));
  });

  tokiWidgetTest('删除会话后回落到保留的会话', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiConfig: config(),
      aiProvider: FakeAiProvider(chunks: <String>['第一个会话的回复']),
    );
    await openAi(tester);
    await send(tester, '第一个会话');

    await tester.tap(find.byKey(const ValueKey<String>('ai-sessions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('ai-new-session')));
    await tester.pumpAndSettle();

    final container = containerOf(tester);
    final before = await container.read(chatRepositoryProvider).getSessions();
    expect(before, hasLength(2));
    final extra = before.firstWhere(
      (ChatSession s) => s.id != kDefaultChatSessionId,
    );

    await tester.tap(find.byKey(const ValueKey<String>('ai-sessions')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey<String>('ai-session-delete-${extra.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    final after = await container.read(chatRepositoryProvider).getSessions();
    expect(after, hasLength(1));
    expect(after.single.id, kDefaultChatSessionId);
  });
}
