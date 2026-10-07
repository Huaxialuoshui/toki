import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_appearance.dart';
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
