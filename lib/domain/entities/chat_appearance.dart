import 'dart:convert';

import 'package:flutter/material.dart';

/// 聊天背景类型（规格 §10）。
enum ChatBackgroundType { solid, gradient, image }

/// 聊天背景配置。
///
/// 只描述"长什么样"，不关心它存在哪里；持久化见 `ChatAppearanceStore`。
@immutable
class ChatBackgroundConfig {
  const ChatBackgroundConfig({
    this.type = ChatBackgroundType.solid,
    this.solidColor = 0x00000000,
    this.gradientColors = const <int>[0xFF1B2030, 0xFF3A2A5A],
    this.imagePath,
    this.imageOpacity = 1,
    this.blurAmount = 0,
    this.overlayColor = 0xFF000000,
    this.overlayOpacity = 0,
  });

  final ChatBackgroundType type;

  /// 纯色背景（ARGB）。
  final int solidColor;

  /// 渐变背景的两个颜色（ARGB）。
  final List<int> gradientColors;

  /// 图片背景：本地路径或 `http(s)` URL。
  final String? imagePath;

  /// 图片透明度（0-1）。
  final double imageOpacity;

  /// 背景模糊强度（sigma）。
  final double blurAmount;

  /// 暗色遮罩颜色与不透明度。
  final int overlayColor;
  final double overlayOpacity;

  bool get hasImage => (imagePath ?? '').trim().isNotEmpty;

  Color get solid => Color(solidColor);

  List<Color> get gradient =>
      gradientColors.map(Color.new).toList(growable: false);

  Color get overlay => Color(overlayColor);

  ChatBackgroundConfig copyWith({
    ChatBackgroundType? type,
    int? solidColor,
    List<int>? gradientColors,
    String? imagePath,
    bool clearImage = false,
    double? imageOpacity,
    double? blurAmount,
    int? overlayColor,
    double? overlayOpacity,
  }) {
    return ChatBackgroundConfig(
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      imageOpacity: imageOpacity ?? this.imageOpacity,
      blurAmount: blurAmount ?? this.blurAmount,
      overlayColor: overlayColor ?? this.overlayColor,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type.name,
        'solidColor': solidColor,
        'gradientColors': gradientColors,
        'imagePath': imagePath,
        'imageOpacity': imageOpacity,
        'blurAmount': blurAmount,
        'overlayColor': overlayColor,
        'overlayOpacity': overlayOpacity,
      };

  static ChatBackgroundConfig fromJson(Map<String, Object?> json) {
    final typeName = json['type']?.toString();
    final type = ChatBackgroundType.values.firstWhere(
      (ChatBackgroundType value) => value.name == typeName,
      orElse: () => ChatBackgroundType.solid,
    );
    final gradient = (json['gradientColors'] as List<Object?>?)
        ?.whereType<num>()
        .map((num value) => value.toInt())
        .toList(growable: false);
    return ChatBackgroundConfig(
      type: type,
      solidColor: (json['solidColor'] as num?)?.toInt() ?? 0x00000000,
      gradientColors: (gradient == null || gradient.length < 2)
          ? const <int>[0xFF1B2030, 0xFF3A2A5A]
          : gradient,
      imagePath: json['imagePath']?.toString(),
      imageOpacity: (json['imageOpacity'] as num?)?.toDouble() ?? 1,
      blurAmount: (json['blurAmount'] as num?)?.toDouble() ?? 0,
      overlayColor: (json['overlayColor'] as num?)?.toInt() ?? 0xFF000000,
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatBackgroundConfig &&
        other.type == type &&
        other.solidColor == solidColor &&
        _sameColors(other.gradientColors, gradientColors) &&
        other.imagePath == imagePath &&
        other.imageOpacity == imageOpacity &&
        other.blurAmount == blurAmount &&
        other.overlayColor == overlayColor &&
        other.overlayOpacity == overlayOpacity;
  }

  @override
  int get hashCode => Object.hash(
        type,
        solidColor,
        Object.hashAll(gradientColors),
        imagePath,
        imageOpacity,
        blurAmount,
        overlayColor,
        overlayOpacity,
      );

  static bool _sameColors(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 聊天外观总配置（规格 §10 + §12）：背景、头像、气泡、字号、消息动画。
@immutable
class ChatAppearanceConfig {
  const ChatAppearanceConfig({
    this.background = const ChatBackgroundConfig(),
    this.userAvatar,
    this.userAvatarColor,
    this.bubbleOpacity = 1,
    this.bubbleRadius = 18,
    this.fontScale = 1,
    this.animationEnabled = true,
  });

  static const ChatAppearanceConfig defaults = ChatAppearanceConfig();

  final ChatBackgroundConfig background;

  /// 用户头像：emoji / 单个字 / 图片路径或 URL。
  final String? userAvatar;

  /// 用户头像底色（ARGB int）；为空时用主题色。
  final int? userAvatarColor;

  /// 气泡不透明度（0.4 - 1）。
  final double bubbleOpacity;

  /// 气泡圆角（0 - 32）。
  final double bubbleRadius;

  /// 聊天气泡里的字号缩放（0.85 - 1.4）。
  final double fontScale;

  /// 消息出现动画。
  final bool animationEnabled;

  ChatAppearanceConfig copyWith({
    ChatBackgroundConfig? background,
    String? userAvatar,
    bool clearUserAvatar = false,
    int? userAvatarColor,
    bool clearUserAvatarColor = false,
    double? bubbleOpacity,
    double? bubbleRadius,
    double? fontScale,
    bool? animationEnabled,
  }) {
    return ChatAppearanceConfig(
      background: background ?? this.background,
      userAvatar: clearUserAvatar ? null : (userAvatar ?? this.userAvatar),
      userAvatarColor: clearUserAvatarColor
          ? null
          : (userAvatarColor ?? this.userAvatarColor),
      bubbleOpacity: bubbleOpacity ?? this.bubbleOpacity,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
      fontScale: fontScale ?? this.fontScale,
      animationEnabled: animationEnabled ?? this.animationEnabled,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'background': background.toJson(),
        'userAvatar': userAvatar,
        'userAvatarColor': userAvatarColor,
        'bubbleOpacity': bubbleOpacity,
        'bubbleRadius': bubbleRadius,
        'fontScale': fontScale,
        'animationEnabled': animationEnabled,
      };

  static ChatAppearanceConfig fromJson(Map<String, Object?> json) {
    final background = json['background'];
    return ChatAppearanceConfig(
      background: background is Map
          ? ChatBackgroundConfig.fromJson(
              Map<String, Object?>.from(background),
            )
          : const ChatBackgroundConfig(),
      userAvatar: json['userAvatar']?.toString(),
      userAvatarColor: (json['userAvatarColor'] as num?)?.toInt(),
      bubbleOpacity: (json['bubbleOpacity'] as num?)?.toDouble() ?? 1,
      bubbleRadius: (json['bubbleRadius'] as num?)?.toDouble() ?? 18,
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1,
      animationEnabled: json['animationEnabled'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toJson());

  static ChatAppearanceConfig decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return defaults;
      return ChatAppearanceConfig.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return defaults;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatAppearanceConfig &&
        other.background == background &&
        other.userAvatar == userAvatar &&
        other.userAvatarColor == userAvatarColor &&
        other.bubbleOpacity == bubbleOpacity &&
        other.bubbleRadius == bubbleRadius &&
        other.fontScale == fontScale &&
        other.animationEnabled == animationEnabled;
  }

  @override
  int get hashCode => Object.hash(
        background,
        userAvatar,
        userAvatarColor,
        bubbleOpacity,
        bubbleRadius,
        fontScale,
        animationEnabled,
      );
}
