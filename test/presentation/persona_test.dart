import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/test_app.dart';

/// Phase 7 人设系统：CRUD + 聊天页切换。
void main() {
  const Size surface = Size(1400, 2200);

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

  /// 把某个控件滚进可视区域（设置页很长）。
  Future<Finder> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    return target;
  }

  tokiWidgetTest('设置页可以新建人设', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettings(tester);

    await reveal(tester, find.text('Add persona').first);
    await tester.tap(find.text('Add persona').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '阿蓝');
    await tester.enterText(find.byType(TextFormField).at(1), '学习搭子');
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();

    expect(find.text('阿蓝'), findsOneWidget);
    expect(find.text('学习搭子'), findsOneWidget);
  });

  tokiWidgetTest('可以编辑与删除人设', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openSettings(tester);

    // 示例数据里有「小雪」，点进去改名。
    await reveal(tester, find.text('小雪').last);
    await tester.tap(find.text('小雪').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '小雪（改）');
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();
    expect(find.text('小雪（改）'), findsOneWidget);

    // 再删除它。
    await reveal(tester, find.text('小雪（改）').last);
    await tester.tap(find.text('小雪（改）').last);
    await tester.pumpAndSettle();
    // 编辑器里的「删除」是 TextButton.icon（私有子类），用文案定位。
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('小雪（改）'), findsNothing);
    expect(find.text('No personas yet'), findsOneWidget);
  });

  tokiWidgetTest('聊天页可以切换人设，并影响后续请求的系统提示词', (tester) async {
    final ai = FakeAiProvider(chunks: <String>['好的']);
    await pumpTokiApp(
      tester,
      size: surface,
      aiProvider: ai,
      aiConfig: config(),
    );

    // 先加一个自定义人设，方便切换。
    await openSettings(tester);
    await reveal(tester, find.text('Add persona').first);
    await tester.tap(find.text('Add persona').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '阿蓝');
    await tester.enterText(
      // 字段顺序：名称 / 身份 / 性格 / 说话方式 / 称呼 / 系统提示词
      // （头像改成了"预览 + 更换"按钮，不再是一个输入框）
      find.byType(TextFormField).at(5),
      '你是阿蓝，说话简短直接。',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save').last);
    await tester.pumpAndSettle();

    await openAi(tester);
    // 打开人设菜单并选择「阿蓝」。
    await tester.tap(find.text('小雪').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('阿蓝').last);
    await tester.pumpAndSettle();

    expect(find.text('Switched to 阿蓝'), findsOneWidget);
    // 等 SnackBar 消失，避免遮挡输入框。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '在吗');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    // 请求里的 system prompt 必须是刚切换的人设。
    expect(ai.requests, hasLength(1));
    expect(ai.requests.single.messages.first.role.name, 'system');
    expect(
      ai.requests.single.messages.first.content,
      '你是阿蓝，说话简短直接。',
    );
  });
}
