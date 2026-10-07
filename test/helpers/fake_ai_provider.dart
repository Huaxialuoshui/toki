import 'dart:async';

import 'package:toki/domain/services/ai_provider.dart';

/// 可编排的假 AI 服务：按给定文本块"流式"返回，便于断言逐字输出与落库。
class FakeAiProvider implements AiProvider {
  FakeAiProvider({
    this.chunks = const <String>['你好', '，我是小雪'],
    this.error,
    this.delay,
    this.models = const <String>['fake-small', 'fake-large'],
    this.modelsError,
  });

  final List<String> chunks;

  /// 非空时在流开始处抛出该错误。
  final Object? error;

  /// 每个块之间的延迟（用于观察中间状态）。
  final Duration? delay;

  /// `listModels` 返回的模型 id。
  final List<String> models;

  /// 非空时 `listModels` 抛出该错误。
  final Object? modelsError;

  final List<AiChatRequest> requests = <AiChatRequest>[];
  int listModelsCalls = 0;

  @override
  Future<List<String>> listModels() async {
    listModelsCalls++;
    if (modelsError != null) throw modelsError!;
    return models;
  }

  @override
  Future<AiResponse> chat(AiChatRequest request) async {
    requests.add(request);
    if (error != null) throw error!;
    return AiResponse(content: chunks.join());
  }

  @override
  Stream<AiResponseChunk> chatStream(AiChatRequest request) async* {
    requests.add(request);
    if (error != null) throw error!;
    for (final String chunk in chunks) {
      if (delay != null) await Future<void>.delayed(delay!);
      yield AiResponseChunk(delta: chunk);
    }
    yield const AiResponseChunk(delta: '', done: true);
  }
}
