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

/// 原生能力调用失败（带可读原因，例如"这台设备上没有能编辑图片的应用"）。
///
/// 绝大多数通道方法失败时安静返回 null / false；但"用户主动点了一个按钮"的
/// 场景（定位、改图、换图标）需要把原因说出来。
class DeviceChannelException implements Exception {
  const DeviceChannelException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 一次「系统图片编辑器」的结果。
class ImageEditResult {
  const ImageEditResult({required this.path, required this.changed});

  /// 编辑后的图片路径；没有改动时就是原路径。
  final String path;

  /// 内容是否真的变了（原生侧比对了大小 + MD5）。
  final bool changed;
}

/// 一次「自定义应用图标」的结果。
class AppIconResult {
  const AppIconResult({required this.recents, required this.shortcut});

  /// 是否换掉了"最近任务"里的图标。
  final bool recents;

  /// 是否成功发起了"把带图标的快捷方式钉到桌面"的请求（系统会弹确认框）。
  final bool shortcut;
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

  /// 把图片交给系统自带的图片编辑器去改，返回改完后的路径。
  ///
  /// 原生侧会先复制一份到缓存目录再共享，所以原图不会被别的应用直接写坏；
  /// 只有内容真的变了才另存为新文件并把新路径还回来。
  Future<ImageEditResult> editImage(String path) async {
    if (!isSupported) {
      throw const DeviceChannelException('当前平台不支持调用系统图片编辑器');
    }
    final Map<Object?, Object?>? raw;
    try {
      raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'editImage',
        <String, Object?>{'path': path},
      );
    } on MissingPluginException {
      throw const DeviceChannelException('当前平台不支持调用系统图片编辑器');
    } on PlatformException catch (error) {
      throw DeviceChannelException(error.message ?? '打开图片编辑器失败');
    }
    final edited = raw?['path']?.toString();
    if (edited == null || edited.isEmpty) {
      return ImageEditResult(path: path, changed: false);
    }
    return ImageEditResult(path: edited, changed: raw?['changed'] == true);
  }

  /// 自定义应用图标：换掉最近任务里的图标 + 请求一个带自定义图标的桌面快捷方式。
  Future<AppIconResult> setAppIcon(String path) async {
    if (!isSupported) {
      throw const DeviceChannelException('当前平台不支持自定义应用图标');
    }
    final Map<Object?, Object?>? raw;
    try {
      raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'setAppIcon',
        <String, Object?>{'path': path},
      );
    } on MissingPluginException {
      throw const DeviceChannelException('当前平台不支持自定义应用图标');
    } on PlatformException catch (error) {
      throw DeviceChannelException(error.message ?? '设置应用图标失败');
    }
    return AppIconResult(
      recents: raw?['recents'] == true,
      shortcut: raw?['shortcut'] == true,
    );
  }

  /// 恢复默认应用图标（最近任务图标回到系统默认，动态快捷方式清掉）。
  Future<void> resetAppIcon() async {
    if (!isSupported) return;
    await _invoke<bool>('resetAppIcon');
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
