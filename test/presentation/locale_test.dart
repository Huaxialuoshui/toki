import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('系统语言为英文时界面是英文', (tester) async {
    tester.binding.platformDispatcher.localesTestValue =
        const <Locale>[Locale('en', 'US')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await pumpTokiApp(tester, size: const Size(1280, 900));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('首页'), findsNothing);
  });

  testWidgets('系统语言不受支持时回退中文', (tester) async {
    tester.binding.platformDispatcher.localesTestValue =
        const <Locale>[Locale('ja', 'JP')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await pumpTokiApp(tester, size: const Size(1280, 900));

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('设置页切换语言后界面立即变化且被持久化', (tester) async {
    tester.binding.platformDispatcher.localesTestValue =
        const <Locale>[Locale('en', 'US')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await pumpTokiApp(tester, size: const Size(1280, 900));
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('sidebar-tile-/settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '中文'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsWidgets);
    expect(find.text('外观'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('sidebar-tile-/home')));
    await tester.pumpAndSettle();
    expect(find.text('首页'), findsOneWidget);

    // 语言选择写入 shared_preferences（应用级轻量设置）
    final preferences = await SharedPreferencesReader.read();
    expect(preferences, 'zh');
  });
}

/// 读取当前 mock 的 shared_preferences 内容。
abstract final class SharedPreferencesReader {
  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('settings.locale');
  }
}
