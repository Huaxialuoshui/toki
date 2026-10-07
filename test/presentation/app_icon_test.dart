import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/device/device_providers.dart';
import 'package:toki/infrastructure/device/app_icon_service.dart';
import 'package:toki/infrastructure/device/device_channel.dart';
import 'package:toki/infrastructure/device/image_edit_service.dart';

import '../helpers/test_app.dart';

/// 设置页「应用图标」区块 + 「用系统工具编辑」按钮。
void main() {
  const Size surface = Size(1400, 2800);
  const MethodChannel channel = MethodChannel('toki/device');

  /// 1×1 的合法 PNG，避免预览走 errorBuilder。
  final Uint8List pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/'
    'q842iQAAAABJRU5ErkJggg==',
  );

  late Directory temp;
  late File iconFile;
  late List<String> calls;
  late List<Object?> arguments;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('toki_app_icon_test');
    iconFile = File('${temp.path}/my_icon.png')..writeAsBytesSync(pngBytes);
    calls = <String>[];
    arguments = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      arguments.add(call.arguments);
      switch (call.method) {
        case 'setAppIcon':
          return <Object?, Object?>{'recents': true, 'shortcut': true};
        case 'resetAppIcon':
          return true;
        case 'editImage':
          return <Object?, Object?>{
            'path': '${temp.path}/edited_my_icon.png',
            'changed': true,
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  DeviceChannel deviceChannel() =>
      DeviceChannel(channel: channel, supported: true);

  List<Override> overrides() => <Override>[
        deviceChannelProvider.overrideWithValue(deviceChannel()),
        imageEditServiceProvider.overrideWithValue(
          ImageEditService(
            channel: deviceChannel(),
            platform: DevicePlatform.android,
          ),
        ),
        appIconServiceProvider.overrideWithValue(
          AppIconService(
            channel: deviceChannel(),
            platform: DevicePlatform.android,
          ),
        ),
      ];

  Future<void> openSettingsAndScrollTo(WidgetTester tester, Finder target) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('没有自定义图标时，「应用到系统」是禁用的', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      extraOverrides: overrides(),
    );
    await openSettingsAndScrollTo(
      tester,
      find.byKey(const ValueKey<String>('app-icon-apply')),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('app-icon-apply')),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const ValueKey<String>('app-icon-reset')), findsNothing);
  });

  tokiWidgetTest('选了图片后可以应用到系统（走原生通道）', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{'settings.appIcon': iconFile.path},
      extraOverrides: overrides(),
    );
    await openSettingsAndScrollTo(
      tester,
      find.byKey(const ValueKey<String>('app-icon-apply')),
    );

    expect(find.text(iconFile.path), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('app-icon-apply')));
    await tester.pumpAndSettle();

    expect(calls, contains('setAppIcon'));
    expect(
      (arguments.last! as Map<Object?, Object?>)['path'],
      iconFile.path,
    );
    // 有反馈即可（文案跟随界面语言，所以只断言"弹了提示"）。
    expect(find.byType(SnackBar), findsOneWidget);
  });

  tokiWidgetTest('「用系统工具编辑」拿到新路径后会替换掉旧图片', (tester) async {
    final edited = File('${temp.path}/edited_my_icon.png')
      ..writeAsBytesSync(pngBytes);
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{'settings.appIcon': iconFile.path},
      extraOverrides: overrides(),
    );
    await openSettingsAndScrollTo(
      tester,
      find.byKey(const ValueKey<String>('app-icon-edit-image')),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('app-icon-edit-image')),
    );
    await tester.pumpAndSettle();

    expect(calls, contains('editImage'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('settings.appIcon'), edited.path);
    expect(find.text(edited.path), findsOneWidget);
  });

  tokiWidgetTest('恢复默认会通知原生并清掉设置', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{'settings.appIcon': iconFile.path},
      extraOverrides: overrides(),
    );
    await openSettingsAndScrollTo(
      tester,
      find.byKey(const ValueKey<String>('app-icon-reset')),
    );

    await tester.tap(find.byKey(const ValueKey<String>('app-icon-reset')));
    await tester.pumpAndSettle();

    expect(calls, contains('resetAppIcon'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('settings.appIcon'), isNull);
  });
}
