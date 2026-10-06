/// 全局常量。只放真正跨层共享的值，避免变成杂物箱。
abstract final class AppConstants {
  /// 应用显示名。
  static const String appName = 'Toki';

  /// 应用版本（与 pubspec.yaml 保持一致）。
  static const String appVersion = '0.1.0+1';

  /// 构建本项目所用的 Flutter SDK 版本（与 `flutter --version` 保持一致）。
  static const String flutterSdkVersion = '3.27.2 (stable)';

  /// 响应式断点：`< 600` 手机，`600 - 1000` 平板，`> 1000` 桌面。
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1000;

  /// 桌面 Sidebar 展开 / 折叠宽度。
  static const double sidebarWidth = 232;
  static const double sidebarCollapsedWidth = 76;

  /// 布局切换动画时长。
  static const Duration layoutAnimation = Duration(milliseconds: 220);

  /// 倒计时节拍间隔。
  static const Duration countdownTick = Duration(seconds: 1);
}
