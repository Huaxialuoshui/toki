import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/domain/entities/chat_appearance.dart';
import 'package:toki/presentation/widgets/chat_background.dart';

import '../helpers/test_app.dart';

/// 应用级外观：自定义背景（纯色 / 渐变 / 图片）+ 图标风格。
///
/// 这两项存在 shared_preferences 里，和 ThemeConfig（配色）互不影响。
void main() {
  const Size surface = Size(1400, 2600);

  ChatBackground appBackgroundOf(WidgetTester tester) =>
      tester.widget<ChatBackground>(
        find.byKey(const ValueKey<String>('app-background')),
      );

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('没有自定义应用背景时沿用主题背景色', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);

    final background = appBackgroundOf(tester);
    expect(background.config.type, ChatBackgroundType.solid);
    expect(background.config.blurAmount, 0);
    expect(background.config.overlayOpacity, 0);
  });

  tokiWidgetTest('保存过的应用背景在启动时就生效', (tester) async {
    const saved = ChatBackgroundConfig(
      type: ChatBackgroundType.gradient,
      gradientColors: <int>[0xFF102030, 0xFF405060],
      blurAmount: 8,
      overlayOpacity: 0.25,
    );
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{
        'settings.appBackground': jsonEncode(saved.toJson()),
      },
    );

    final background = appBackgroundOf(tester);
    expect(background.config.type, ChatBackgroundType.gradient);
    expect(background.config.gradientColors, <int>[0xFF102030, 0xFF405060]);
    expect(background.config.blurAmount, 8);
    expect(background.config.overlayOpacity, 0.25);
  });

  tokiWidgetTest('设置页可以切换应用背景为渐变并持久化', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettings(tester);

    final gradient = find.byKey(
      const ValueKey<String>('app-bg-type-gradient'),
    );
    await scrollTo(tester, gradient);
    await tester.tap(gradient);
    await tester.pumpAndSettle();

    // 立即生效（应用级背景层换了类型）
    expect(appBackgroundOf(tester).config.type, ChatBackgroundType.gradient);

    // 写入 shared_preferences（应用级轻量设置）
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('settings.appBackground');
    expect(raw, isNotNull);
    expect(
      ChatBackgroundConfig.fromJson(
        Map<String, Object?>.from(jsonDecode(raw!) as Map<Object?, Object?>),
      ).type,
      ChatBackgroundType.gradient,
    );
  });

  tokiWidgetTest('设置页切换图标风格后导航图标变实心并持久化', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettings(tester);

    Icon homeIcon() => tester.widget<Icon>(
          find
              .descendant(
                of: find.byKey(
                  const ValueKey<String>('sidebar-tile-/home'),
                ),
                matching: find.byType(Icon),
              )
              .first,
        );

    expect(homeIcon().icon, Icons.dashboard_outlined);

    final filled = find.descendant(
      of: find.byKey(const ValueKey<String>('icon-style')),
      matching: find.text('Filled'),
    );
    await scrollTo(tester, filled);
    await tester.tap(filled);
    await tester.pumpAndSettle();

    expect(homeIcon().icon, Icons.dashboard);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('settings.iconStyle'), 'filled');
  });
}
