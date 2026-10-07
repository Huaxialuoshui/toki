import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/chat_appearance.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/presentation/widgets/chat_background.dart';

import '../helpers/fake_ai_provider.dart';
import '../helpers/test_app.dart';

/// Phase 10：聊天外观（背景 / 头像 / 气泡 / 字号 / 动画）在聊天页生效。
void main() {
  const Size surface = Size(1400, 1600);

  Future<void> openAi(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/ai')),
    );
    await tester.pumpAndSettle();
  }

  ChatAppearanceConfig custom() => const ChatAppearanceConfig(
        background: ChatBackgroundConfig(
          type: ChatBackgroundType.gradient,
          gradientColors: <int>[0xFF112233, 0xFF445566],
          blurAmount: 6,
          overlayOpacity: 0.2,
        ),
        userAvatar: '🐱',
        bubbleOpacity: 0.75,
        bubbleRadius: 26,
        fontScale: 1.2,
        animationEnabled: false,
      );

  tokiWidgetTest('聊天页使用设置里的背景配置', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{
        'settings.chatAppearance': custom().encode(),
      },
    );
    await openAi(tester);

    // 注意：应用级背景也是一个 ChatBackground，所以这里按 key 取聊天页那个。
    final background = tester.widget<ChatBackground>(
      find.byKey(const ValueKey<String>('ai-chat-background')),
    );
    expect(background.config.type, ChatBackgroundType.gradient);
    expect(background.config.gradientColors, <int>[0xFF112233, 0xFF445566]);
    expect(background.config.blurAmount, 6);
    expect(background.config.overlayOpacity, 0.2);
  });

  tokiWidgetTest('用户头像会显示在用户消息旁边', (tester) async {
    final ai = FakeAiProvider(chunks: <String>['嗯嗯']);
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      aiProvider: ai,
      aiConfig: AiProviderConfig(
        id: 'p-test',
        name: '测试',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test',
        isDefault: true,
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      ),
      initialPreferences: <String, Object>{
        'settings.chatAppearance': custom().encode(),
      },
    );
    await openAi(tester);

    await tester.enterText(find.byType(TextField).last, '你好');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('🐱'), findsOneWidget);
  });

  tokiWidgetTest('没有自定义外观时使用默认纯色背景', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openAi(tester);

    final background = tester.widget<ChatBackground>(
      find.byType(ChatBackground).first,
    );
    expect(background.config.type, ChatBackgroundType.solid);
    expect(background.config.blurAmount, 0);
  });

  tokiWidgetTest('设置页可以切换背景类型并实时预览', (tester) async {
    await pumpTokiApp(tester,
        size: const Size(1400, 2400), seedDatabase: false);
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();

    // 设置页里有两个"Gradient"（应用级背景 + 聊天外观），所以精确定位聊天那一组。
    final gradient = find.descendant(
      of: find.byKey(const ValueKey<String>('chat-background-type')),
      matching: find.text('Gradient'),
    );
    await tester.scrollUntilVisible(
      gradient,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(gradient);
    await tester.pumpAndSettle();

    // 预览区使用同一份配置
    final background = tester.widget<ChatBackground>(
      find.byKey(const ValueKey<String>('chat-preview-background')),
    );
    expect(background.config.type, ChatBackgroundType.gradient);
    expect(find.text('This is a preview bubble'), findsOneWidget);
  });
}
