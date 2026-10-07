import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 一次设备定位结果。
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
}

/// 定位失败（原生给了具体原因，例如"系统定位服务没有打开"）。
///
/// 其它通道方法在失败时安静地返回 null / false；定位是个例外——用户是**主动**
/// 点了"用当前位置"，所以要把原因说出来，而不是显示"拿不到位置"。
class GeoLocationException implements Exception {
  const GeoLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 原生能力通道（`toki/device`）。
///
/// * 定位：天气按 GPS 取位置；
/// * 小组件：把状态与外观写到原生能读到的位置，并触发重绘；
/// * 后台：电池优化白名单 + 可选的常驻前台服务。
///
/// 桌面端没有这条通道，所有方法都会安全降级（返回 null / false）。
class DeviceChannel {
  DeviceChannel({MethodChannel? channel, bool? supported})
      : _channel = channel ?? const MethodChannel('toki/device'),
        _supportedOverride = supported,
        _directoryOverride = null;

  final MethodChannel _channel;
  final bool? _supportedOverride;

  /// 测试用：直接指定状态文件所在目录，避免依赖 path_provider。
  final Future<Directory> Function()? _directoryOverride;

  /// 见 [DeviceChannel]，这是给测试用的构造入口。
  DeviceChannel.withDirectory({
    required Future<Directory> Function() directory,
    MethodChannel? channel,
    bool supported = true,
  })  : _channel = channel ?? const MethodChannel('toki/device'),
        _supportedOverride = supported,
        _directoryOverride = directory;

  /// 小组件状态文件（原生按同一路径读取）。
  static const String widgetStateFileName = 'widget_state.json';
  static const String widgetBackgroundFileName = 'widget_background.png';

  bool get isSupported => _supportedOverride ?? Platform.isAndroid;

  Future<bool> hasLocationPermission() async {
    if (!isSupported) return false;
    return await _invoke<bool>('hasLocationPermission') ?? false;
  }

  Future<bool> requestLocationPermission() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestLocationPermission') ?? false;
  }

  /// 取一次位置；没有权限或系统定位关闭时返回 null。
  Future<GeoPoint?> getLocation() async {
    if (!isSupported) return null;
    final Map<Object?, Object?>? result;
    try {
      result = await _channel.invokeMethod<Map<Object?, Object?>>('getLocation');
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      throw GeoLocationException(error.message ?? '定位失败');
    }
    if (result == null) return null;
    final latitude = (result['latitude'] as num?)?.toDouble();
    final longitude = (result['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    return GeoPoint(
      latitude: latitude,
      longitude: longitude,
      accuracy: (result['accuracy'] as num?)?.toDouble(),
    );
  }

  /// 把小组件状态写入原生可读的文件，并通知重绘。
  Future<void> pushWidgetState(String json) async {
    if (!isSupported) return;
    final directory = await _directory();
    final file = File(p.join(directory.path, widgetStateFileName));
    await file.writeAsString(json, flush: true);
    await _invoke<bool>('updateWidget');
  }

  /// 请求把小组件钉到桌面（Android 8+，需要启动器支持）。
  Future<bool> requestPinWidget() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestPinWidget') ?? false;
  }

  /// 把用户选的背景图片复制到应用私有目录，返回新路径。
  Future<String?> copyWidgetBackground(String sourcePath) async {
    if (!isSupported) return null;
    final source = File(sourcePath);
    if (!source.existsSync()) return null;
    final directory = await _directory();
    final target = File(p.join(directory.path, widgetBackgroundFileName));
    await source.copy(target.path);
    return target.path;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!isSupported) return false;
    return await _invoke<bool>('isIgnoringBatteryOptimizations') ?? false;
  }

  /// 打开系统的"电池优化白名单"确认框。
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!isSupported) return false;
    return await _invoke<bool>('requestIgnoreBatteryOptimizations') ?? false;
  }

  Future<bool> isBackgroundServiceEnabled() async {
    if (!isSupported) return false;
    return await _invoke<bool>('isBackgroundServiceEnabled') ?? false;
  }

  Future<bool> setBackgroundService(bool enabled) async {
    if (!isSupported) return false;
    return await _invoke<bool>(
          'setBackgroundService',
          <String, Object?>{'enabled': enabled},
        ) ??
        false;
  }

  /// 通道不可用（桌面端 / 原生未实现）时安静地返回 null。
  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<Directory> _directory() =>
      _directoryOverride?.call() ?? getApplicationSupportDirectory();
}
