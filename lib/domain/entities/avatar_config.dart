import 'package:flutter/foundation.dart';

/// 头像的三种来源。
enum AvatarKind {
  emoji('emoji'),
  text('text'),
  image('image');

  const AvatarKind(this.storageValue);
  final String storageValue;

  static AvatarKind parse(Object? raw) {
    for (final kind in AvatarKind.values) {
      if (kind.storageValue == raw) return kind;
    }
    return AvatarKind.emoji;
  }
}

/// 头像配置：emoji / 文字（带底色）/ 图片。
///
/// 用户头像与人设头像共用；图片既可以是本地路径也可以是 http(s) URL。
@immutable
class AvatarConfig {
  const AvatarConfig({
    this.kind = AvatarKind.emoji,
    this.value = '',
    this.color,
  });

  final AvatarKind kind;

  /// emoji / 文字内容，或图片路径 / URL。
  final String value;

  /// 底色（ARGB int）；为空时用主题色。
  final int? color;

  bool get isImage => kind == AvatarKind.image && value.trim().isNotEmpty;

  bool get isEmpty => value.trim().isEmpty;

  AvatarConfig copyWith(
          {AvatarKind? kind,
          String? value,
          int? color,
          bool clearColor = false}) =>
      AvatarConfig(
        kind: kind ?? this.kind,
        value: value ?? this.value,
        color: clearColor ? null : (color ?? this.color),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind.storageValue,
        'value': value,
        'color': color,
      };

  static AvatarConfig fromJson(Map<String, Object?> json) => AvatarConfig(
        kind: AvatarKind.parse(json['kind']),
        value: '${json['value'] ?? ''}',
        color: (json['color'] as num?)?.toInt(),
      );

  /// 从旧版本"一个字符串"的设置推断（emoji / 字 / 路径 / URL）。
  static AvatarConfig fromLegacy(String? raw, {int? color}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return AvatarConfig(color: color);
    final lower = value.toLowerCase();
    final looksLikeImage = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        value.contains('/') ||
        value.contains('\\') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
    return AvatarConfig(
      kind: looksLikeImage ? AvatarKind.image : AvatarKind.emoji,
      value: value,
      color: color,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AvatarConfig &&
      other.kind == kind &&
      other.value == value &&
      other.color == color;

  @override
  int get hashCode => Object.hash(kind, value, color);
}

/// 编辑器里可选的表情（挑常用的，不做全量）。
const List<String> kAvatarEmojis = <String>[
  '🙂',
  '😀',
  '😄',
  '😁',
  '😆',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😎',
  '🤗',
  '🤔',
  '🙃',
  '😴',
  '😪',
  '🥳',
  '😤',
  '😢',
  '😭',
  '😱',
  '🤯',
  '😳',
  '🥺',
  '😅',
  '😂',
  '🤣',
  '👍',
  '👏',
  '🙏',
  '💪',
  '🤝',
  '✌️',
  '🤟',
  '👌',
  '🫶',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🐱',
  '🐶',
  '🦊',
  '🐻',
  '🐼',
  '🐨',
  '🐯',
  '🦁',
  '🌸',
  '🌻',
  '🌙',
  '⭐',
  '🔥',
  '🍀',
];
