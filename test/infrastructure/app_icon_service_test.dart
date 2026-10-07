import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/infrastructure/device/app_icon_service.dart';
import 'package:toki/infrastructure/device/device_channel.dart';
import 'package:toki/infrastructure/device/image_edit_service.dart';

/// 自定义应用图标：Android 走原生通道（最近任务图标 + 桌面快捷方式）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('toki/device');

  late Directory temp;
  late File icon;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('toki_icon_test');
    icon = File('${temp.path}/icon.png')..writeAsBytesSync(<int>[1, 2, 3, 4]);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  AppIconService service(void Function(MethodCall call) onCall) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      onCall(call);
      switch (call.method) {
        case 'setAppIcon':
          return <Object?, Object?>{'recents': true, 'shortcut': true};
        case 'resetAppIcon':
          return true;
        default:
          return null;
      }
    });
    return AppIconService(
      channel: DeviceChannel(channel: channel, supported: true),
      platform: DevicePlatform.android,
    );
  }

  test('应用图标：把路径交给原生，并带回"最近任务 + 快捷方式"结果', () async {
    final calls = <String>[];
    final outcome = await service((MethodCall call) => calls.add(call.method))
        .apply(icon.path);

    expect(outcome.ok, isTrue);
    expect(outcome.recents, isTrue);
    expect(outcome.shortcut, isTrue);
    expect(calls, contains('setAppIcon'));
  });

  test('应用图标：图片不存在时不调原生并给出可读错误', () async {
    final calls = <String>[];
    final outcome = await service((MethodCall call) => calls.add(call.method))
        .apply('${temp.path}/nope.png');

    expect(outcome.ok, isFalse);
    expect(outcome.error, contains('找不到'));
    expect(calls, isEmpty);
  });

  test('应用图标：空路径直接报错', () async {
    final outcome = await service((MethodCall call) {}).apply('  ');
    expect(outcome.error, contains('先选一张图片'));
  });

  test('应用图标：平台不支持时给出可读错误', () async {
    final outcome = await AppIconService(
      channel: DeviceChannel(supported: false),
      platform: DevicePlatform.unsupported,
    ).apply(icon.path);
    expect(outcome.error, contains('不支持'));
  });

  test('恢复默认会通知原生清掉自定义图标', () async {
    final calls = <String>[];
    await service((MethodCall call) => calls.add(call.method)).reset();
    expect(calls, contains('resetAppIcon'));
  });
}
