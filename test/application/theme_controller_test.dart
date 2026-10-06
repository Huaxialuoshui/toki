import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/theme/theme_controller.dart';
import 'package:toki/application/theme/theme_mapper.dart';
import 'package:toki/application/theme/theme_presets.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/domain/entities/glass_style.dart';

import '../helpers/test_app.dart';

void main() {
  group('主题解析', () {
    test('默认跟随系统：浅色用 Default，深色用 Dark', () async {
      final container = await createTestContainer(clock: FixedClock(kTestNow));
      final resolution = container.read(themeResolutionProvider);

      expect(resolution.mode, ThemeMode.system);
      expect(resolution.light.id, ThemePresets.defaultId);
      expect(resolution.dark.id, ThemePresets.darkId);
      expect(
        resolution.configFor(Brightness.dark).brightness,
        Brightness.dark,
      );
      expect(
        resolution.configFor(Brightness.light).brightness,
        Brightness.light,
      );
    });

    test('显式选择预设后不再跟随系统，ThemeMode 由预设明暗决定', () async {
      final container = await createTestContainer(clock: FixedClock(kTestNow));
      final controller = container.read(themeControllerProvider.notifier);

      controller.selectPreset(ThemePresets.darkId);
      final resolution = container.read(themeResolutionProvider);

      expect(controller.state.followSystem, isFalse);
      expect(resolution.mode, ThemeMode.dark);
      expect(resolution.light, resolution.dark);
      expect(resolution.dark.id, ThemePresets.darkId);
      expect(buildThemeData(resolution.dark).brightness, Brightness.dark);
    });

    test('字号与圆角微调叠加在预设之上', () async {
      final container = await createTestContainer(clock: FixedClock(kTestNow));
      final controller = container.read(themeControllerProvider.notifier);

      controller.setFontScale(1.2);
      controller.setBorderRadius(4);
      final config = container.read(themeResolutionProvider).dark;

      expect(config.fontScale, 1.2);
      expect(config.borderRadius, 4);

      controller.resetBorderRadius();
      expect(
        container.read(themeResolutionProvider).dark.borderRadius,
        ThemePresets.darkTheme.borderRadius,
      );
    });

    test('未知主题 id 回落到 Default', () async {
      final container = await createTestContainer(
        clock: FixedClock(kTestNow),
        initialPreferences: <String, Object>{'settings.themeId': 'nope'},
      );
      expect(
        container.read(themeControllerProvider).themeId,
        ThemePresets.defaultId,
      );
    });
  });

  group('ThemeData 与玻璃层职责分离', () {
    test('只有透明度/模糊变化时 ThemeData 完全不变', () {
      const base = ThemePresets.defaultTheme;
      final translucent = base.copyWith(cardOpacity: 0.4, blurAmount: 24);

      expect(buildThemeData(base), buildThemeData(translucent));
      expect(
        GlassStyle.fromThemeConfig(base),
        isNot(GlassStyle.fromThemeConfig(translucent)),
      );
    });

    test('玻璃参数来自 ThemeConfig', () {
      final glass = GlassStyle.fromThemeConfig(ThemePresets.darkTheme);
      expect(glass.opacity, ThemePresets.darkTheme.cardOpacity);
      expect(glass.blurAmount, ThemePresets.darkTheme.blurAmount);
      expect(glass.hasBlur, isTrue);
    });

    test('字号缩放不写进 ThemeData', () {
      const config = ThemePresets.defaultTheme;

      expect(
        buildThemeData(config.copyWith(fontScale: 1.25)),
        buildThemeData(config),
      );
    });

    tokiWidgetTest('字号缩放通过 MediaQuery.textScaler 生效', (tester) async {
      await pumpTokiApp(
        tester,
        size: const Size(1280, 900),
        initialPreferences: <String, Object>{'settings.fontScale': 1.25},
      );

      final context = tester.element(find.text('Home'));
      expect(MediaQuery.textScalerOf(context).scale(10), closeTo(12.5, 0.001));
    });
  });
}
