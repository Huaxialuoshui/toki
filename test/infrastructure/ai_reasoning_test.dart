import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/ai/openai_compatible_provider.dart';

/// 思考模型（MiMo / DeepSeek-R1）的 `reasoning_content`：解析 + 回传。
void main() {
  AiProviderConfig config() => AiProviderConfig(
        id: 'p1',
        name: '测试',
        baseUrl: 'https://example.com/v1',
        model: 'reasoner',
        createdAt: DateTime(2026, 10, 7),
        updatedAt: DateTime(2026, 10, 7),
      );

  OpenAiCompatibleProvider providerWith(_Adapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return OpenAiCompatibleProvider(config: config(), dio: dio);
  }

  const AiChatRequest request = AiChatRequest(
    messages: <AiMessage>[AiMessage.user('现在几点？')],
  );

  test('流式：思考增量单独产出，不混进正文', () async {
    final adapter = _Adapter(
      (_) => _sse(<String>[
        '{"choices":[{"delta":{"reasoning_content":"用户"}}]}',
        '{"choices":[{"delta":{"reasoning_content":"在问时间"}}]}',
        '{"choices":[{"delta":{"content":"现在"}}]}',
        '{"choices":[{"delta":{"content":"是 10 点"}}]}',
        '[DONE]',
      ]),
    );

    final chunks = await providerWith(adapter).chatStream(request).toList();

    final reasoning = chunks.map((AiResponseChunk c) => c.reasoning).join();
    final text = chunks.map((AiResponseChunk c) => c.delta).join();
    expect(reasoning, '用户在问时间');
    expect(text, '现在是 10 点');
    expect(
        chunks.where((AiResponseChunk c) => c.isReasoningOnly), hasLength(2));
  });

  test('非流式：解析 message.reasoning_content', () async {
    final adapter = _Adapter(
      (_) => _json(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'finish_reason': 'stop',
            'message': <String, Object?>{
              'content': '现在是 10 点',
              'reasoning_content': '思考一下',
            },
          },
        ],
      }),
    );

    final response = await providerWith(adapter).chat(request);

    expect(response.content, '现在是 10 点');
    expect(response.reasoning, '思考一下');
  });

  test('历史里的推理会作为 reasoning_content 回传给服务端', () {
    final message = AiMessage(
      role: AiRole.assistant,
      content: '已完成',
      reasoning: '先看看日程',
      toolCalls: const <AiToolCall>[
        AiToolCall(id: 'call_1', name: 'get_today_events', argumentsJson: '{}'),
      ],
    );

    final json = message.toJson();
    expect(json['reasoning_content'], '先看看日程');
    expect(json['tool_calls'], isA<List<Object?>>());
  });

  test('没有推理时不带 reasoning_content 字段', () {
    const message = AiMessage(role: AiRole.assistant, content: '你好');
    expect(message.toJson().containsKey('reasoning_content'), isFalse);
  });
}

ResponseBody _json(Map<String, Object?> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

ResponseBody _sse(List<String> payloads) => ResponseBody.fromString(
      payloads.map((String payload) => 'data: $payload\n\n').join(),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}
