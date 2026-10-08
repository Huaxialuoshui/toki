import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/services/ai_provider.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/test_app.dart';

/// 人设编辑器里的「作为日历助手」开关（界面视角）。
void main() {
  const Size surface = Size(1400, 2200);
  const ValueKey<String> switchKey =
      ValueKey<String>('persona-calendar-assistant');

  AiProviderConfig config() => AiProviderConfig(
        id: 'p-test',
        name: '测试服务商',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test-model',
        isDefault: true,
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      );

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAi(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/ai')),
    );
    await tester.pumpAndSettle();
  }

  /// 打开示例人设「小雪」的编辑器。
  Future<void> openPersonaEditor(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('小雪').last,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('小雪').last);
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('人设编辑器默认打开「作为日历助手」', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openSettings(tester);
    await openPersonaEditor(tester);

    expect(find.text('Acting as a calendar assistant'), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byKey(switchKey)).value,
      isTrue,
      reason: '老数据 / 新 人设 都默认还是日历助手',
    );
  });

  tokiWidgetTest('关掉开关保存后人设列表出现「纯聊天」徽标', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openSettings(tester);
    await openPersonaEditor(tester);

    await tester.tap(find.byKey(switchKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byKey(switchKey)).value, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();

    expect(find.text('Chat only'), findsOneWidget);
  });

  tokiWidgetTest('纯聊天人设发消息时不给工具、也不注入日程上下文', (tester) async {
    final ai = FakeAiProvider(chunks: <String>['好的']);
    await pumpTokiApp(
      tester,
      size: surface,
      aiProvider: ai,
      aiConfig: config(),
    );

    await openSettings(tester);
    await openPersonaEditor(tester);
    await tester.enterText(
      // 字段顺序：名称 / 身份 / 性格 / 说话方式 / 称呼 / 系统提示词
      find.byType(TextFormField).at(5),
      '你是猫娘助手，不管日程，只用喵喵叫回应。',
    );
    await tester.tap(find.byKey(switchKey));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();

    await openAi(tester);
    // 聊天页顶栏也要看得出来当前是纯聊天。
    expect(find.text('小雪 · 私人日程助手 · Chat only'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '今天有什么安排？');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(ai.requests, hasLength(1));
    final request = ai.requests.single;
    expect(request.tools, isEmpty);
    expect(
      request.messages
          .where((AiMessage message) => message.role == AiRole.system)
          .map((AiMessage message) => message.content)
          .toList(),
      <String>['你是猫娘助手，不管日程，只用喵喵叫回应。'],
    );
  });
}
