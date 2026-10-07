import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/test_app.dart';

/// 服务商编辑器：模型从服务商远程获取后**选择**，而不是手打。
void main() {
  const Size surface = Size(1400, 1800);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> openProviderEditor(
    WidgetTester tester,
    FakeAiProvider ai,
  ) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiProvider: ai,
      extraOverrides: <Override>[
        aiProviderBuilderProvider.overrideWithValue(
          (AiProviderConfig _) => ai,
        ),
      ],
    );
    await openSettings(tester);
    await tapText(tester, 'Add provider');
  }

  /// 填 Base URL（拉模型只需要它）。
  Future<void> fillBaseUrl(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Base URL'),
      'https://api.xiaomimimo.com/v1',
    );
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('模型从服务商拉取后点选，不需要手打', (tester) async {
    final ai = FakeAiProvider(
      models: <String>['mimo-v2.5', 'mimo-v2.6-flash', 'mimo-v2.6-pro'],
    );
    await openProviderEditor(tester, ai);
    await fillBaseUrl(tester);

    await tester.tap(find.byKey(const ValueKey<String>('ai-fetch-models')));
    await tester.pumpAndSettle();

    expect(ai.listModelsCalls, 1);
    expect(find.text('Choose a model'), findsOneWidget);
    expect(find.text('3 models available'), findsOneWidget);
    expect(find.text('mimo-v2.6-pro'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('ai-model-mimo-v2.6-pro')));
    await tester.pumpAndSettle();

    // 对话框关闭，模型写进表单并给出反馈。
    expect(find.text('Choose a model'), findsNothing);
    expect(find.text('Selected model: mimo-v2.6-pro'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'Model'))
          .controller
          ?.text,
      'mimo-v2.6-pro',
    );
  });

  tokiWidgetTest('保存后数据库里存的是选中的模型', (tester) async {
    final ai =
        FakeAiProvider(models: <String>['mimo-v2.6-flash', 'mimo-v2.6-pro']);
    await openProviderEditor(tester, ai);
    await fillBaseUrl(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      '小米 MiMo',
    );

    await tester.tap(find.byKey(const ValueKey<String>('ai-fetch-models')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey<String>('ai-model-mimo-v2.6-flash')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Save');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final saved = await container.read(aiProviderRepositoryProvider).getAll();
    expect(saved, hasLength(1));
    expect(saved.single.name, '小米 MiMo');
    expect(saved.single.model, 'mimo-v2.6-flash');
    expect(saved.single.baseUrl, 'https://api.xiaomimimo.com/v1');
  });

  tokiWidgetTest('可以按关键字筛选模型', (tester) async {
    final ai = FakeAiProvider(
      models: <String>['mimo-v2.5', 'mimo-v2.6-flash', 'mimo-v2.6-pro'],
    );
    await openProviderEditor(tester, ai);
    await fillBaseUrl(tester);
    await tester.tap(find.byKey(const ValueKey<String>('ai-fetch-models')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('ai-model-filter')),
      'flash',
    );
    await tester.pumpAndSettle();

    expect(find.text('mimo-v2.6-flash'), findsOneWidget);
    expect(find.text('mimo-v2.5'), findsNothing);
    expect(find.text('mimo-v2.6-pro'), findsNothing);
  });

  tokiWidgetTest('获取失败给可读原因，可重试或改手动输入', (tester) async {
    final ai = FakeAiProvider(
      modelsError: const _Boom('HTTP 401（API Key 可能无效或没有权限）'),
    );
    await openProviderEditor(tester, ai);
    await fillBaseUrl(tester);

    await tester.tap(find.byKey(const ValueKey<String>('ai-fetch-models')));
    await tester.pumpAndSettle();
    expect(find.text('Could not fetch models'), findsOneWidget);
    expect(find.textContaining('HTTP 401'), findsWidgets);

    // 重试会再打一次接口。
    await tapText(tester, 'Retry');
    expect(ai.listModelsCalls, 2);

    // 切到手动输入：模型字段变成可编辑。
    await tapText(tester, 'Enter manually');
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Model'),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isFalse);
    expect(find.textContaining('Type the model name'), findsWidgets);
  });

  tokiWidgetTest('Base URL 没填时不去请求，直接提示', (tester) async {
    final ai = FakeAiProvider();
    await openProviderEditor(tester, ai);

    await tester.tap(find.byKey(const ValueKey<String>('ai-fetch-models')));
    await tester.pumpAndSettle();

    expect(ai.listModelsCalls, 0);
    expect(find.text('Choose a model'), findsNothing);
    expect(find.textContaining('http://'), findsWidgets);
  });
}

/// 一个只带 message 的假异常（模拟 AppException 的展示路径）。
class _Boom implements Exception {
  const _Boom(this.message);
  final String message;
  @override
  String toString() => message;
}
