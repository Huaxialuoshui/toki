import 'package:flutter/foundation.dart';

/// 对话角色（与 OpenAI Chat Completions 的 role 对齐）。
enum AiRole { system, user, assistant, tool }

/// 一条发给模型的消息。
@immutable
class AiMessage {
  const AiMessage({required this.role, required this.content});

  const AiMessage.system(String content) : this(role: AiRole.system, content: content);
  const AiMessage.user(String content) : this(role: AiRole.user, content: content);
  const AiMessage.assistant(String content)
      : this(role: AiRole.assistant, content: content);

  final AiRole role;
  final String content;

  String get roleName => switch (role) {
        AiRole.system => 'system',
        AiRole.user => 'user',
        AiRole.assistant => 'assistant',
        AiRole.tool => 'tool',
      };

  Map<String, Object?> toJson() => <String, Object?>{
        'role': roleName,
        'content': content,
      };
}

/// 一次对话请求。
@immutable
class AiChatRequest {
  const AiChatRequest({
    required this.messages,
    this.temperature,
    this.maxTokens,
  });

  final List<AiMessage> messages;
  final double? temperature;
  final int? maxTokens;
}

/// 非流式回复。
@immutable
class AiResponse {
  const AiResponse({required this.content, this.finishReason});

  final String content;
  final String? finishReason;
}

/// 流式回复的一块增量。
@immutable
class AiResponseChunk {
  const AiResponseChunk({required this.delta, this.done = false});

  /// 本次新增的文本（可能为空字符串）。
  final String delta;

  /// 是否结束。
  final bool done;
}

/// AI 服务抽象（规格 §1）。
///
/// 第一版只实现 OpenAI Compatible 一种，但业务层只依赖这个接口，
/// 以后加 Anthropic / Gemini 等不需要改上层。
///
/// 工具调用（`generateToolCalls`）在 Phase 8 扩展这个接口。
abstract interface class AiProvider {
  /// 一次性返回完整回复。
  Future<AiResponse> chat(AiChatRequest request);

  /// 逐块返回增量文本，供界面做"逐字输出"。
  Stream<AiResponseChunk> chatStream(AiChatRequest request);
}
