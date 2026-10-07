import 'dart:io';

import 'device_channel.dart';
import 'image_edit_service.dart' show DevicePlatform;
import 'windows_app_icon.dart';

/// 一次「应用自定义图标」的结果。
class AppIconOutcome {
  const AppIconOutcome({
    this.recents = false,
    this.shortcut = false,
    this.error,
  });

  /// 换掉了"最近任务"里的图标（Android）。
  final bool recents;

  /// 成功请求了"把带自定义图标的快捷方式钉到桌面"（Android，系统会弹确认框）。
  final bool shortcut;

  final String? error;

  bool get ok => error == null && (recents || shortcut);
}

/// 自定义应用图标。
///
/// 两个平台能做的事情不一样，这里如实分开：
/// * Android：运行时改不了 `android:icon`（那是打包资源），但可以
///   ① 换掉「最近任务」里的图标；② 用 `requestPinShortcut` 生成一个
///   **带你自己图片**的桌面快捷方式（系统弹一次确认）。
/// * Windows：窗口标题栏 / 任务栏图标可以运行时换（`WM_SETICON`）；
///   exe 自身的图标是编译时资源，改它需要重新构建。
class AppIconService {
  AppIconService({
    DeviceChannel? channel,
    WindowsAppIcon? windows,
    DevicePlatform? platform,
  })
      : _channel = channel ?? DeviceChannel(),
        _windows = windows,
        _platformOverride = platform;

  final DeviceChannel _channel;
  final DevicePlatform? _platformOverride;
  WindowsAppIcon? _windows;

  DevicePlatform get platform => _platformOverride ?? DevicePlatform.current;

  bool get isSupported => platform != DevicePlatform.unsupported;

  Future<AppIconOutcome> apply(String path) async {
    final value = path.trim();
    if (value.isEmpty) return const AppIconOutcome(error: '先选一张图片');
    if (!File(value).existsSync()) {
      return const AppIconOutcome(error: '找不到这张图片');
    }
    if (platform == DevicePlatform.android) {
      try {
        final result = await _channel.setAppIcon(value);
        return AppIconOutcome(
          recents: result.recents,
          shortcut: result.shortcut,
        );
      } on DeviceChannelException catch (error) {
        return AppIconOutcome(error: error.message);
      }
    }
    if (platform == DevicePlatform.windows) {
      final applied = await (_windows ??= WindowsAppIcon()).setIcon(value);
      return applied
          ? const AppIconOutcome(recents: true)
          : const AppIconOutcome(error: '设置窗口图标失败（找不到应用窗口或图片读不出来）');
    }
    return const AppIconOutcome(error: '当前平台不支持自定义应用图标');
  }

  Future<void> reset() async {
    if (platform == DevicePlatform.android) {
      await _channel.resetAppIcon();
      return;
    }
    if (platform == DevicePlatform.windows) {
      await (_windows ??= WindowsAppIcon()).resetIcon();
    }
  }
}
