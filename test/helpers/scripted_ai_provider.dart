import 'package:toki/domain/services/ai_provider.dart';

/// 按脚本逐轮返回内容的假 AI：用于测试"模型 → 工具 → 模型"的循环。
class ScriptedAiProvider implements AiProvider {
  ScriptedAiProvider(this.turns);

  /// 每一轮要发出的 chunk 列表（按顺序取，用完后重复最后一轮）。
  final List<List<AiResponseChunk>> turns;

  final List<AiChatRequest> requests = <AiChatRequest>[];
  int _index = 0;

  @override
  Future<AiResponse> chat(AiChatRequest request) async {
    requests.add(request);
    return const AiResponse(content: '');
  }

  @override
  Stream<AiResponseChunk> chatStream(AiChatRequest request) async* {
    requests.add(request);
    final turn = _index < turns.length ? turns[_index] : turns.last;
    _index++;
    for (final AiResponseChunk chunk in turn) {
      yield chunk;
    }
  }
}

/// 便捷构造：一轮纯文本回复。
List<AiResponseChunk> textTurn(String text) => <AiResponseChunk>[
      AiResponseChunk(delta: text),
      const AiResponseChunk(done: true),
    ];

/// 便捷构造：一轮工具调用。
List<AiResponseChunk> toolCallTurn({
  required String id,
  required String name,
  required String argumentsJson,
}) =>
    <AiResponseChunk>[
      AiResponseChunk(
        toolCalls: <AiToolCall>[
          AiToolCall(id: id, name: name, argumentsJson: argumentsJson),
        ],
      ),
      const AiResponseChunk(done: true),
    ];
