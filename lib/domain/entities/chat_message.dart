import 'dart:convert';

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

/// 助手请求调用的一次工具（落库时序列化进 `tool_arguments`）。
@immutable
class ChatToolCall {
  const ChatToolCall({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  final String id;
  final String name;
  final String argumentsJson;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'arguments': argumentsJson,
      };

  static ChatToolCall? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return ChatToolCall(
      id: raw['id']?.toString() ?? '',
      name: raw['name']?.toString() ?? '',
      argumentsJson: raw['arguments']?.toString() ?? '',
    );
  }

  /// 从 `tool_arguments` 文本解析出工具调用列表。
  static List<ChatToolCall> parseList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <ChatToolCall>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ChatToolCall>[];
      return decoded
          .map(ChatToolCall.fromJson)
          .whereType<ChatToolCall>()
          .toList(growable: false);
    } on FormatException {
      return const <ChatToolCall>[];
    }
  }

  static String encodeList(List<ChatToolCall> calls) => jsonEncode(
        calls.map((ChatToolCall call) => call.toJson()).toList(growable: false),
      );
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
    this.toolCallId,
    this.requestedToolCalls = const <ChatToolCall>[],
    this.toolResult,
    this.reasoningContent,
    this.isStreaming = false,
  });

  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final ToolCallInfo? toolCall;

  /// `role == tool` 时对应的工具调用 id。
  final String? toolCallId;

  /// `role == assistant` 时请求调用的工具。
  final List<ChatToolCall> requestedToolCalls;

  /// `role == tool` 时的原始结果（JSON 串）。
  final String? toolResult;

  /// 思考模型的内部推理（MiMo / DeepSeek-R1）。多轮工具调用时会回传，
  /// 界面默认折叠展示。
  final String? reasoningContent;

  /// 流式输出中（Phase 6 使用；Phase 1 只用于渲染风格）。
  final bool isStreaming;

  final DateTime createdAt;

  ChatMessage copyWith({
    String? content,
    ToolCallInfo? toolCall,
    String? toolCallId,
    List<ChatToolCall>? requestedToolCalls,
    String? toolResult,
    String? reasoningContent,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      toolCall: toolCall ?? this.toolCall,
      toolCallId: toolCallId ?? this.toolCallId,
      requestedToolCalls: requestedToolCalls ?? this.requestedToolCalls,
      toolResult: toolResult ?? this.toolResult,
      reasoningContent: reasoningContent ?? this.reasoningContent,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

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
