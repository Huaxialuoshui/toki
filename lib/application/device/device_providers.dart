import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/device/device_channel.dart';

/// 原生能力通道（定位 / 小组件 / 后台服务）。
///
/// 测试里可以 override 成"supported=true + 假通道"来断言推给原生的内容。
final deviceChannelProvider = Provider<DeviceChannel>(
  (ref) => DeviceChannel(),
);
