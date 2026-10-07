import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/infrastructure/device/device_channel.dart';
import 'package:toki/infrastructure/device/image_edit_service.dart';

/// 调用系统图片编辑器：走原生通道（Android）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('toki/device');

  late Directory temp;
  late File original;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('toki_edit_test');
    original = File('${temp.path}/bg.png')..writeAsBytesSync(<int>[1, 2, 3]);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  void mockChannel(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  test('平台不支持时给出可读错误', () async {
    final service = ImageEditService(
      channel: DeviceChannel(supported: false),
      platform: DevicePlatform.unsupported,
    );
    final outcome = await service.edit(original.path);
    expect(outcome.ok, isFalse);
    expect(outcome.error, contains('不支持'));
  });

  test('图片不存在时提前报错，不去调原生', () async {
    var called = false;
    mockChannel((MethodCall call) async {
      called = true;
      return null;
    });
    final service = ImageEditService(
      channel: DeviceChannel(channel: channel, supported: true),
      platform: DevicePlatform.android,
    );

    final outcome = await service.edit('${temp.path}/missing.png');

    expect(outcome.ok, isFalse);
    expect(outcome.error, contains('找不到'));
    expect(called, isFalse);
  });

  test('路径为空时报错', () async {
    final service = ImageEditService(
      channel: DeviceChannel(channel: channel, supported: true),
      platform: DevicePlatform.android,
    );
    final outcome = await service.edit('   ');
    expect(outcome.error, contains('改不了'));
  });

  test('Android：编辑器改过就返回新路径', () async {
    mockChannel((MethodCall call) async {
      expect(call.method, 'editImage');
      expect((call.arguments as Map<Object?, Object?>)['path'], original.path);
      return <Object?, Object?>{
        'path': '${temp.path}/edited_123_bg.png',
        'changed': true,
      };
    });
    final service = ImageEditService(
      channel: DeviceChannel(channel: channel, supported: true),
      platform: DevicePlatform.android,
    );

    final outcome = await service.edit(original.path);

    expect(outcome.ok, isTrue);
    expect(outcome.changed, isTrue);
    expect(outcome.path, endsWith('edited_123_bg.png'));
  });

  test('Android：内容没变时保持原路径', () async {
    mockChannel((MethodCall call) async => <Object?, Object?>{
          'path': original.path,
          'changed': false,
        });
    final service = ImageEditService(
      channel: DeviceChannel(channel: channel, supported: true),
      platform: DevicePlatform.android,
    );

    final outcome = await service.edit(original.path);

    expect(outcome.ok, isTrue);
    expect(outcome.changed, isFalse);
    expect(outcome.path, original.path);
  });

  test('Android：没有编辑器时把原生原因透给用户', () async {
    mockChannel((MethodCall call) async {
      throw PlatformException(
        code: 'no-editor',
        message: '这台设备上没有能编辑图片的应用',
      );
    });
    final service = ImageEditService(
      channel: DeviceChannel(channel: channel, supported: true),
      platform: DevicePlatform.android,
    );

    final outcome = await service.edit(original.path);

    expect(outcome.ok, isFalse);
    expect(outcome.error, contains('没有能编辑图片的应用'));
  });
}
