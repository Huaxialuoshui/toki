import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/device/app_icon_service.dart';
import '../../domain/entities/chat_appearance.dart';
import '../device/device_providers.dart';
import '../../infrastructure/storage/app_settings_store.dart';

/// 图标风格：描边 / 实心（规格 §9「图标风格」）。
enum AppIconStyle {
  outlined('outlined'),
  filled('filled');

  const AppIconStyle(this.storageValue);
  final String storageValue;

  static AppIconStyle parse(String? raw) =>
      raw == 'filled' ? AppIconStyle.filled : AppIconStyle.outlined;
}

/// 应用级背景（规格 §9「背景」）：纯色 / 渐变 / 图片。
///
/// 复用聊天背景的配置模型与渲染组件，但存储在独立的应用级设置里，
/// 和"聊天页背景"互不影响。
class AppBackgroundController extends Notifier<ChatBackgroundConfig> {
  @override
  ChatBackgroundConfig build() {
    final raw = ref.watch(appSettingsStoreProvider).readAppBackground();
    if (raw == null || raw.isEmpty) return const ChatBackgroundConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ChatBackgroundConfig();
      return ChatBackgroundConfig.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return const ChatBackgroundConfig();
    }
  }

  Future<void> update(ChatBackgroundConfig config) async {
    state = config;
    await ref
        .read(appSettingsStoreProvider)
        .writeAppBackground(jsonEncode(config.toJson()));
  }
}

final appBackgroundProvider =
    NotifierProvider<AppBackgroundController, ChatBackgroundConfig>(
  AppBackgroundController.new,
);

/// 图标风格（应用级）。
class AppIconStyleController extends Notifier<AppIconStyle> {
  @override
  AppIconStyle build() => AppIconStyle.parse(
        ref.watch(appSettingsStoreProvider).readIconStyle(),
      );

  Future<void> update(AppIconStyle style) async {
    state = style;
    await ref.read(appSettingsStoreProvider).writeIconStyle(style.storageValue);
  }
}

final appIconStyleProvider =
    NotifierProvider<AppIconStyleController, AppIconStyle>(
  AppIconStyleController.new,
);

/// 自定义应用图标：存的是本机图片路径。
///
/// 「换图标」分两步走——先选/改图片（只记路径），再点「应用到系统」。
/// 这样用户可以在应用前先用系统图片编辑器把图改好，不会选完就被硬塞进桌面。
class AppIconController extends Notifier<String?> {
  @override
  String? build() {
    final raw = ref.watch(appSettingsStoreProvider).readAppIcon();
    return (raw == null || raw.trim().isEmpty) ? null : raw;
  }

  Future<void> setPath(String? path) async {
    final value = (path == null || path.trim().isEmpty) ? null : path.trim();
    state = value;
    await ref.read(appSettingsStoreProvider).writeAppIcon(value);
  }

  /// 真正应用到系统（Android：最近任务图标 + 桌面快捷方式；Windows：窗口 / 任务栏图标）。
  Future<AppIconOutcome> apply() async {
    final path = state;
    if (path == null) {
      return const AppIconOutcome(error: '先选一张图片');
    }
    return ref.read(appIconServiceProvider).apply(path);
  }

  /// 恢复默认图标。
  Future<void> reset() async {
    try {
      await ref.read(appIconServiceProvider).reset();
    } on Object {
      // 恢复失败也要把设置清掉，否则界面会一直显示"已自定义"。
    }
    await setPath(null);
  }
}

final appIconProvider = NotifierProvider<AppIconController, String?>(
  AppIconController.new,
);

/// 启动时把上次的自定义应用图标再应用一次。
///
/// Android 侧由原生自己在 `onCreate` 恢复"最近任务图标"，所以这里只需要处理
/// Windows（窗口 / 任务栏图标每次启动都会回到 exe 里的默认图标）。
final appIconStartupProvider = FutureProvider<void>((ref) async {
  if (!Platform.isWindows) return;
  final path = ref.watch(appIconProvider);
  if (path == null) return;
  try {
    await ref.read(appIconServiceProvider).apply(path);
  } on Object {
    // 启动期的图标问题不该影响启动。
  }
});
