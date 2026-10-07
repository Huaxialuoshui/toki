import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/domain/entities/avatar_config.dart';

import '../helpers/test_app.dart';

/// 头像编辑器：表情 / 文字 / 图片三种形态 + 底色（不是"一个输入框"）。
void main() {
  const Size surface = Size(1400, 2600);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAvatarEditor(WidgetTester tester) async {
    final button = find.byKey(const ValueKey<String>('chat-avatar-edit'));
    await tester.scrollUntilVisible(
      button,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Finder inDialog(Finder matching) => find.descendant(
        of: find.byType(AlertDialog),
        matching: matching,
      );

  tokiWidgetTest('头像编辑器提供表情 / 文字 / 图片三档，而不是只让填一个字符串', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettings(tester);
    await openAvatarEditor(tester);

    // 表情档：有 emoji 面板和文字输入（最多 2 字）
    expect(inDialog(find.byKey(const ValueKey<String>('avatar-emoji-0'))),
        findsOneWidget);
    expect(inDialog(find.byKey(const ValueKey<String>('avatar-text'))),
        findsOneWidget);

    // 图片档：相册按钮 + 路径 / URL 输入框
    await tester.tap(
      inDialog(find.byKey(const ValueKey<String>('avatar-kind-image'))),
    );
    await tester.pumpAndSettle();
    expect(inDialog(find.byKey(const ValueKey<String>('avatar-pick-image'))),
        findsOneWidget);
    expect(inDialog(find.byKey(const ValueKey<String>('avatar-image-path'))),
        findsOneWidget);
  });

  tokiWidgetTest('选一个表情 + 底色，保存后写入聊天外观设置', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettings(tester);
    await openAvatarEditor(tester);

    final emoji = kAvatarEmojis[3];
    await tester.tap(
      inDialog(find.byKey(const ValueKey<String>('avatar-emoji-3'))),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      inDialog(find.byKey(const ValueKey<String>('avatar-color-0'))),
    );
    await tester.pumpAndSettle();

    await tester.tap(inDialog(find.byKey(const ValueKey<String>('avatar-save'))));
    await tester.pumpAndSettle();

    // 预览区（弹窗外）已经换成新头像
    expect(find.text(emoji), findsWidgets);

    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('settings.chatAppearance');
    expect(raw, isNotNull);
    final json = jsonDecode(raw!) as Map<String, Object?>;
    expect(json['userAvatar'], emoji);
    expect(json['userAvatarColor'], isNotNull);
  });

  tokiWidgetTest('已有头像时可以一键移除', (tester) async {
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
    await openAvatarEditor(tester);

    await tester.tap(
      inDialog(find.byKey(const ValueKey<String>('avatar-clear'))),
    );
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final json =
        jsonDecode(preferences.getString('settings.chatAppearance')!)
            as Map<String, Object?>;
    expect(json['userAvatar'], isNull);
  });
}
