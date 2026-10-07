import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_appearance.dart';
import '../../infrastructure/storage/app_settings_store.dart';

/// 聊天外观（背景 / 头像 / 气泡 / 字号 / 动画）。
///
/// 属于"应用级外观设置"，与主题 id 一样存在 shared_preferences 里；
/// 用户自建主题（Phase 11）才会进数据库。
class ChatAppearanceController extends Notifier<ChatAppearanceConfig> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  ChatAppearanceConfig build() {
    final raw = ref.watch(appSettingsStoreProvider).readChatAppearance();
    return ChatAppearanceConfig.decode(raw);
  }

  void updateBackground(ChatBackgroundConfig background) =>
      _apply(state.copyWith(background: background));

  void setUserAvatar(String? avatar) => _apply(
        (avatar == null || avatar.trim().isEmpty)
            ? state.copyWith(clearUserAvatar: true)
            : state.copyWith(userAvatar: avatar.trim()),
      );

  /// 用户头像底色（传 null 表示跟随主题色）。
  void setUserAvatarColor(int? color) => _apply(
        color == null
            ? state.copyWith(clearUserAvatarColor: true)
            : state.copyWith(userAvatarColor: color),
      );

  void setBubbleOpacity(double value) =>
      _apply(state.copyWith(bubbleOpacity: value.clamp(0.4, 1).toDouble()));

  void setBubbleRadius(double value) =>
      _apply(state.copyWith(bubbleRadius: value.clamp(0, 32).toDouble()));

  void setFontScale(double value) =>
      _apply(state.copyWith(fontScale: value.clamp(0.85, 1.4).toDouble()));

  void setAnimationEnabled(bool value) =>
      _apply(state.copyWith(animationEnabled: value));

  void resetAll() => _apply(ChatAppearanceConfig.defaults);

  void _apply(ChatAppearanceConfig next) {
    if (next == state) return;
    state = next;
    unawaited(_store.writeChatAppearance(next.encode()));
  }
}

final chatAppearanceProvider =
    NotifierProvider<ChatAppearanceController, ChatAppearanceConfig>(
  ChatAppearanceController.new,
);
