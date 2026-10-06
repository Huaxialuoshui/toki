import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/test_app.dart';

void main() {
  const Size surface = Size(1400, 1400);

  AiProviderConfig config() => AiProviderConfig(
        id: 'p-test',
        name: '测试服务商',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test-model',
        isDefault: true,
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      );

  Future<void> openAi(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/ai')),
    );
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('没有配置服务商时给出提示与入口', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openAi(tester);

    expect(find.text('No AI provider configured yet'), findsOneWidget);
    expect(find.text('Open settings'), findsWidgets);
    expect(find.byTooltip('Open settings'), findsOneWidget);
  });

  tokiWidgetTest('发送消息后逐字显示回复并保留在会话里', (tester) async {
    final ai = FakeAiProvider(chunks: <String>['今天', '有 3 个安排']);
    await pumpTokiApp(
      tester,
      size: surface,
      aiProvider: ai,
      aiConfig: config(),
    );
    await openAi(tester);

    await tester.enterText(find.byType(TextField).last, '今天有什么安排？');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    // 用户消息 + 助手回复都在对话里
    expect(find.text('今天有什么安排？'), findsOneWidget);
    expect(find.text('今天有 3 个安排'), findsOneWidget);
    expect(ai.requests, hasLength(1));
  });

  tokiWidgetTest('服务报错时显示错误提示而不是假回复', (tester) async {
    final ai = FakeAiProvider(error: const AppException('无法连接 AI 服务'));
    await pumpTokiApp(
      tester,
      size: surface,
      aiProvider: ai,
      aiConfig: config(),
    );
    await openAi(tester);

    await tester.enterText(find.byType(TextField).last, '在吗');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('无法连接 AI 服务'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  tokiWidgetTest('清空对话会移除消息', (tester) async {
    final ai = FakeAiProvider(chunks: <String>['好的']);
    await pumpTokiApp(
      tester,
      size: surface,
      aiProvider: ai,
      aiConfig: config(),
    );
    await openAi(tester);

    await tester.enterText(find.byType(TextField).last, '你好');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('你好'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear conversation'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('你好'), findsNothing);
  });
}
