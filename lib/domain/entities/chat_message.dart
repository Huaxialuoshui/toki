import 'package:flutter/foundation.dart';

/// 聊天角色（规格 §5 的 `ChatMessage.role`）。
enum ChatRole { user, assistant, system, tool }

/// 工具调用状态，用于在气泡里展示"正在创建日程…"这类人类可读的进度。
enum ToolCallStatus { running, succeeded, failed }

/// 一次工具调用的展示信息。
///
/// 刻意只保留摘要：规格 §12 明确要求不要把复杂 JSON 直接展示给用户，
/// 原始参数与结果留给 Phase 8 的调试视图。
@immutable
class ToolCallInfo {
  const ToolCallInfo({
    required this.toolName,
    required this.status,
    this.summary,
  });

  final String toolName;
  final ToolCallStatus status;
  final String? summary;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCallInfo &&
        other.toolName == toolName &&
        other.status == status &&
        other.summary == summary;
  }

  @override
  int get hashCode => Object.hash(toolName, status, summary);
}

/// 聊天消息。
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.toolCall,
    this.isStreaming = false,
  });

  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final ToolCallInfo? toolCall;

  /// 流式输出中（Phase 6 使用；Phase 1 只用于渲染风格）。
  final bool isStreaming;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.role == role &&
        other.content == content &&
        other.toolCall == toolCall &&
        other.isStreaming == isStreaming &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sessionId,
        role,
        content,
        toolCall,
        isStreaming,
        createdAt,
      );
}
