import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/device/app_icon_service.dart';
import '../../infrastructure/device/device_channel.dart';
import '../../infrastructure/device/image_edit_service.dart';

/// 原生能力通道（定位 / 小组件 / 后台服务）。
///
/// 测试里可以 override 成"supported=true + 假通道"来断言推给原生的内容。
final deviceChannelProvider = Provider<DeviceChannel>(
  (ref) => DeviceChannel(),
);

/// 调用系统图片编辑器（背景 / 头像 / 应用图标共用）。
final imageEditServiceProvider = Provider<ImageEditService>(
  (ref) => ImageEditService(channel: ref.watch(deviceChannelProvider)),
);

/// 自定义应用图标（Android：最近任务图标 + 桌面快捷方式；Windows：窗口 / 任务栏图标）。
final appIconServiceProvider = Provider<AppIconService>(
  (ref) => AppIconService(channel: ref.watch(deviceChannelProvider)),
);
