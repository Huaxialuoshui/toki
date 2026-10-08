import 'package:flutter/foundation.dart';

/// AI 人设（规格 §3）。
///
/// Phase 1 只用它渲染 AI 页面的人设信息，CRUD 在 Phase 7 实现；字段与规格保持
/// 一致，避免后续返工。
@immutable
class AiPersona {
  const AiPersona({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.avatar,
    this.avatarColor,
    this.description,
    this.personality,
    this.speakingStyle,
    this.userNickname,
    this.systemPrompt,
    this.enabledTools = const <String>[],
    this.calendarAssistantEnabled = true,
    this.temperature = 0.7,
  });

  final String id;
  final String name;

  /// 头像标识：本地资源路径或网络地址，Phase 7 支持自定义。
  final String? avatar;

  /// 头像底色（ARGB int）；为空时用主题色。
  final int? avatarColor;

  final String? description;
  final String? personality;
  final String? speakingStyle;

  /// AI 对用户的称呼，例如"主人"。
  final String? userNickname;

  final String? systemPrompt;

  /// 允许该人设使用的工具名（Phase 8 的 ToolPermission）。
  final List<String> enabledTools;

  /// 是否作为日历助手。
  ///
  /// 关掉之后它就是"纯聊天 / 扮演"：不注入日程上下文、不给任何工具，
  /// 只用 [systemPrompt] 里用户自己写的提示词。默认打开，保持老数据的行为。
  final bool calendarAssistantEnabled;

  final double temperature;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 头像在未设置时使用的显示首字。
  String get avatarInitial => name.isEmpty ? '?' : name.substring(0, 1);

  AiPersona copyWith({
    String? name,
    String? avatar,
    bool clearAvatar = false,
    int? avatarColor,
    bool clearAvatarColor = false,
    String? description,
    String? personality,
    String? speakingStyle,
    String? userNickname,
    String? systemPrompt,
    List<String>? enabledTools,
    bool? calendarAssistantEnabled,
    double? temperature,
    DateTime? updatedAt,
  }) =>
      AiPersona(
        id: id,
        name: name ?? this.name,
        avatar: clearAvatar ? null : (avatar ?? this.avatar),
        avatarColor: clearAvatarColor ? null : (avatarColor ?? this.avatarColor),
        description: description ?? this.description,
        personality: personality ?? this.personality,
        speakingStyle: speakingStyle ?? this.speakingStyle,
        userNickname: userNickname ?? this.userNickname,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        enabledTools: enabledTools ?? this.enabledTools,
        calendarAssistantEnabled:
            calendarAssistantEnabled ?? this.calendarAssistantEnabled,
        temperature: temperature ?? this.temperature,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiPersona &&
        other.id == id &&
        other.name == name &&
        other.avatar == avatar &&
        other.avatarColor == avatarColor &&
        other.description == description &&
        other.personality == personality &&
        other.speakingStyle == speakingStyle &&
        other.userNickname == userNickname &&
        other.systemPrompt == systemPrompt &&
        listEquals(other.enabledTools, enabledTools) &&
        other.calendarAssistantEnabled == calendarAssistantEnabled &&
        other.temperature == temperature &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        avatar,
        avatarColor,
        description,
        personality,
        speakingStyle,
        userNickname,
        systemPrompt,
        Object.hashAll(enabledTools),
        calendarAssistantEnabled,
        temperature,
        createdAt,
        updatedAt,
      );
}
