import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// 「用系统工具编辑」要出现在所有涉及图片的地方：
/// 用户头像、助手头像、应用背景 / 聊天背景 / 小组件背景、应用图标。
void main() {
  const Size surface = Size(1400, 2800);

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

  bool isEnabled(WidgetTester tester, String key) {
    final widget = tester.widget<OutlinedButton>(
      find.byKey(ValueKey<String>(key)),
    );
    return widget.onPressed != null;
  }

  tokiWidgetTest('我的头像：本地图片时可以开系统编辑器', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{
        'settings.chatAppearance': jsonEncode(<String, Object?>{
          'userAvatar': '/tmp/toki_avatar.png',
        }),
      },
    );
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const ValueKey<String>('user-avatar-edit-image')));

    expect(isEnabled(tester, 'user-avatar-edit-image'), isTrue);
  });

  tokiWidgetTest('我的头像：表情头像时按钮禁用（没有本地图片可改）', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{
        'settings.chatAppearance': jsonEncode(<String, Object?>{
          'userAvatar': '🐱',
        }),
      },
    );
    await openSettings(tester);
    await scrollTo(tester, find.byKey(const ValueKey<String>('user-avatar-edit-image')));

    expect(isEnabled(tester, 'user-avatar-edit-image'), isFalse);
  });

  tokiWidgetTest('应用背景：图片档里始终有「用系统工具编辑」', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettings(tester);

    final imageTab = find.byKey(const ValueKey<String>('app-bg-type-image'));
    await scrollTo(tester, imageTab);
    await tester.tap(imageTab);
    await tester.pumpAndSettle();

    // 还没选图：按钮在，但不可点。
    expect(find.byKey(const ValueKey<String>('app-bg-edit-image')), findsOneWidget);
    expect(isEnabled(tester, 'app-bg-edit-image'), isFalse);
  });

  tokiWidgetTest('聊天背景：图片档里始终有「用系统工具编辑」', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{'settings.locale': 'zh'},
    );
    await openSettings(tester);

    // 聊天外观区块有自己的分段按钮（key = chat-background-type）。
    final imageTab = find.descendant(
      of: find.byKey(const ValueKey<String>('chat-background-type')),
      matching: find.text('图片'),
    );
    await scrollTo(tester, imageTab);
    await tester.tap(imageTab);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('chat-bg-edit-image')), findsOneWidget);
    expect(isEnabled(tester, 'chat-bg-edit-image'), isFalse);
  });

  tokiWidgetTest('应用图标：选过图之后「用系统工具编辑」可点', (tester) async {
    final directory = Directory.systemTemp.createTempSync('toki_entry_test');
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    final icon = File('${directory.path}/icon.png')..writeAsBytesSync(<int>[1, 2]);

    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{
        'settings.appIcon': icon.path,
      },
    );
    await openSettings(tester);
    await scrollTo(
      tester,
      find.byKey(const ValueKey<String>('app-icon-edit-image')),
    );

    expect(isEnabled(tester, 'app-icon-edit-image'), isTrue);
  });

  tokiWidgetTest('AI 聊天页：头像菜单能直接改「我的头像 / 助手头像」', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1400, 1600),
      seedDatabase: false,
      // 用中文界面断言菜单文案（默认是跟随系统的英文）。
      initialPreferences: <String, Object>{'settings.locale': 'zh'},
    );
    await tester.tap(find.byKey(const ValueKey<String>('sidebar-tile-/ai')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('ai-avatar-menu')));
    await tester.pumpAndSettle();

    expect(find.text('我的头像'), findsOneWidget);
    expect(find.text('助手头像'), findsOneWidget);

    // 点「我的头像」→ 打开的就是设置页那套头像编辑器（含表情/文字/图片三档）。
    await tester.tap(find.text('我的头像'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('avatar-kind-image')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('avatar-edit-image')), findsOneWidget);
  });
}
