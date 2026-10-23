import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 对话角色（与 OpenAI Chat Completions 的 role 对齐）。
enum AiRole { system, user, assistant, tool }

/// 一条发给模型的消息。
@immutable
class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
    this.toolCallId,
    this.toolCalls = const <AiToolCall>[],
    this.reasoning,
  });

  const AiMessage.system(String content)
      : this(role: AiRole.system, content: content);
  const AiMessage.user(String content)
      : this(role: AiRole.user, content: content);
  const AiMessage.assistant(String content)
      : this(role: AiRole.assistant, content: content);

  /// 工具执行结果（回灌给模型）。
  const AiMessage.toolResult({
    required String toolCallId,
    required String content,
  }) : this(role: AiRole.tool, content: content, toolCallId: toolCallId);

  final AiRole role;
  final String content;

  /// `role == tool` 时对应的工具调用 id。
  final String? toolCallId;

  /// `role == assistant` 时模型请求调用的工具。
  final List<AiToolCall> toolCalls;

  /// 思考模型的内部推理（MiMo / DeepSeek-R1 等返回的 `reasoning_content`）。
  ///
  /// 官方建议多轮工具调用时把它原样回传以获得最佳表现；界面默认不展示。
  final String? reasoning;

  String get roleName => switch (role) {
        AiRole.system => 'system',
        AiRole.user => 'user',
        AiRole.assistant => 'assistant',
        AiRole.tool => 'tool',
      };

  Map<String, Object?> toJson() => <String, Object?>{
        'role': roleName,
        if (role != AiRole.assistant || content.isNotEmpty) 'content': content,
        if (toolCallId != null) 'tool_call_id': toolCallId,
        if (toolCalls.isNotEmpty)
          'tool_calls': toolCalls
              .map((AiToolCall call) => call.toJson())
              .toList(growable: false),
        // OpenAI 兼容的思考模型扩展：回传历史推理内容（为空时不带这个字段）。
        if (reasoning != null && reasoning!.trim().isNotEmpty)
          'reasoning_content': reasoning,
      };
}

/// 暴露给模型的工具定义（OpenAI function calling 格式）。
@immutable
class AiToolDefinition {
  const AiToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;

  /// JSON Schema（type: object + properties + required）。
  final Map<String, Object?> parameters;

  Map<String, Object?> toJson() => <String, Object?>{
        'type': 'function',
        'function': <String, Object?>{
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

/// 模型请求的一次工具调用。
@immutable
class AiToolCall {
  const AiToolCall({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  final String id;
  final String name;

  /// 模型给的原始参数（JSON 字符串，可能为空）。
  final String argumentsJson;

  /// 解析后的参数；解析失败时为空 map（由工具层报错，不在这里崩）。
  Map<String, Object?> get arguments {
    if (argumentsJson.trim().isEmpty) return const <String, Object?>{};
    try {
      final decoded = jsonDecode(argumentsJson);
      return decoded is Map<String, Object?>
          ? decoded
          : Map<String, Object?>.from(decoded as Map);
    } on FormatException {
      return const <String, Object?>{};
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'type': 'function',
        'function': <String, Object?>{
          'name': name,
          'arguments': argumentsJson,
        },
      };
}

/// 一次对话请求。
@immutable
class AiChatRequest {
  const AiChatRequest({
    required this.messages,
    this.temperature,
    this.maxTokens,
    this.tools = const <AiToolDefinition>[],
    this.cancelToken,
  });

  final List<AiMessage> messages;
  final double? temperature;
  final int? maxTokens;

  /// 允许模型调用的工具；为空表示纯聊天。
  final List<AiToolDefinition> tools;

  /// 可选取消令牌；支持时 Provider 应真正中止底层 HTTP 请求。
  final AiCancellationToken? cancelToken;
}

/// 领域层取消令牌，不暴露 Dio 类型。
class AiCancellationToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// 非流式回复。
@immutable
class AiResponse {
  const AiResponse({
    required this.content,
    this.finishReason,
    this.toolCalls = const <AiToolCall>[],
    this.reasoning,
  });

  final String content;
  final String? finishReason;

  /// 非流式响应里的工具调用。
  final List<AiToolCall> toolCalls;

  /// 非流式响应里的思考内容。
  final String? reasoning;
}

/// 流式回复的一块增量。
@immutable
class AiResponseChunk {
  const AiResponseChunk({
    this.delta = '',
    this.done = false,
    this.toolCalls = const <AiToolCall>[],
    this.reasoning = '',
  });

  /// 本次新增的文本（可能为空字符串）。
  final String delta;

  /// 是否结束。
  final bool done;

  /// 模型在这一轮请求调用的工具（流结束时一次性给出完整参数）。
  final List<AiToolCall> toolCalls;

  /// 本次新增的思考文本（可能为空字符串；界面按需展示）。
  final String reasoning;

  /// 这一块是不是只有思考内容（没有正文）。
  bool get isReasoningOnly => reasoning.isNotEmpty && delta.isEmpty;
}

/// AI 服务抽象（规格 §1）。
///
/// 第一版只实现 OpenAI Compatible 一种，但业务层只依赖这个接口，
/// 以后加 Anthropic / Gemini 等不需要改上层。
///
abstract interface class AiProvider {
  /// 一次性返回完整回复。
  Future<AiResponse> chat(AiChatRequest request);

  /// 逐块返回增量文本，供界面做"逐字输出"。
  Stream<AiResponseChunk> chatStream(AiChatRequest request);

  /// 拉取该服务当前可用的模型 id 列表（OpenAI 兼容的 `GET {baseUrl}/models`）。
  ///
  /// 设置页用它做"从服务商获取模型 → 选一个"，省得用户手打模型名。
  Future<List<String>> listModels();
}
