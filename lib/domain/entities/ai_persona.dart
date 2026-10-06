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
    this.description,
    this.personality,
    this.speakingStyle,
    this.userNickname,
    this.systemPrompt,
    this.enabledTools = const <String>[],
    this.temperature = 0.7,
  });

  final String id;
  final String name;

  /// 头像标识：本地资源路径或网络地址，Phase 7 支持自定义。
  final String? avatar;

  final String? description;
  final String? personality;
  final String? speakingStyle;

  /// AI 对用户的称呼，例如"主人"。
  final String? userNickname;

  final String? systemPrompt;

  /// 允许该人设使用的工具名（Phase 8 的 ToolPermission）。
  final List<String> enabledTools;

  final double temperature;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 头像在未设置时使用的显示首字。
  String get avatarInitial => name.isEmpty ? '?' : name.substring(0, 1);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiPersona &&
        other.id == id &&
        other.name == name &&
        other.avatar == avatar &&
        other.description == description &&
        other.personality == personality &&
        other.speakingStyle == speakingStyle &&
        other.userNickname == userNickname &&
        other.systemPrompt == systemPrompt &&
        listEquals(other.enabledTools, enabledTools) &&
        other.temperature == temperature &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        avatar,
        description,
        personality,
        speakingStyle,
        userNickname,
        systemPrompt,
        Object.hashAll(enabledTools),
        temperature,
        createdAt,
        updatedAt,
      );
}
