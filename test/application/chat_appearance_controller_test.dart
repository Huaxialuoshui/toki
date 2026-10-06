import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/chat_appearance_controller.dart';
import 'package:toki/domain/entities/chat_appearance.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container({
    Map<String, Object> initial = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final preferences = await SharedPreferences.getInstance();
    final created = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  test('默认外观：纯色背景 / 无自定义头像 / 无缩放', () async {
    final c = await container();
    final appearance = c.read(chatAppearanceProvider);

    expect(appearance.background.type, ChatBackgroundType.solid);
    expect(appearance.userAvatar, isNull);
    expect(appearance.bubbleOpacity, 1);
    expect(appearance.fontScale, 1);
    expect(appearance.animationEnabled, isTrue);
  });

  test('修改背景会写入 shared_preferences，并且能重新读出来', () async {
    final c = await container();
    final controller = c.read(chatAppearanceProvider.notifier);

    controller.updateBackground(
      const ChatBackgroundConfig(
        type: ChatBackgroundType.image,
        imagePath: 'D:/Pictures/ai_bg.png',
        blurAmount: 10,
        overlayOpacity: 0.3,
      ),
    );
    controller.setUserAvatar('🐱');
    controller.setBubbleOpacity(0.7);
    controller.setBubbleRadius(26);
    controller.setFontScale(1.25);
    controller.setAnimationEnabled(false);

    // 稍等写入完成（写 prefs 是异步的）
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('settings.chatAppearance');
    expect(raw, isNotNull);

    // 用一个全新的容器读同一份 prefs，验证持久化结果
    final reloaded = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(reloaded.dispose);
    final appearance = reloaded.read(chatAppearanceProvider);

    expect(appearance.background.type, ChatBackgroundType.image);
    expect(appearance.background.imagePath, 'D:/Pictures/ai_bg.png');
    expect(appearance.background.blurAmount, 10);
    expect(appearance.userAvatar, '🐱');
    expect(appearance.bubbleOpacity, 0.7);
    expect(appearance.bubbleRadius, 26);
    expect(appearance.fontScale, 1.25);
    expect(appearance.animationEnabled, isFalse);
  });

  test('数值会被限制在合理范围', () async {
    final c = await container();
    final controller = c.read(chatAppearanceProvider.notifier);

    controller.setBubbleOpacity(0);
    expect(c.read(chatAppearanceProvider).bubbleOpacity, 0.4);
    controller.setBubbleRadius(999);
    expect(c.read(chatAppearanceProvider).bubbleRadius, 32);
    controller.setFontScale(9);
    expect(c.read(chatAppearanceProvider).fontScale, 1.4);
  });

  test('恢复默认外观', () async {
    final c = await container();
    final controller = c.read(chatAppearanceProvider.notifier);
    controller.setUserAvatar('🐱');
    controller.setBubbleRadius(2);

    controller.resetAll();

    expect(c.read(chatAppearanceProvider), ChatAppearanceConfig.defaults);
  });

  test('清除头像', () async {
    final c = await container();
    final controller = c.read(chatAppearanceProvider.notifier);
    controller.setUserAvatar('🐱');
    expect(c.read(chatAppearanceProvider).userAvatar, '🐱');

    controller.setUserAvatar('   ');
    expect(c.read(chatAppearanceProvider).userAvatar, isNull);
  });
}
