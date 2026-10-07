import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/ai/openai_compatible_provider.dart';

/// 记录请求并返回预设响应的 dio 适配器（不触碰网络）。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  RequestOptions? lastRequest;
  String? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      lastBody =
          utf8.decode(chunks.expand((Uint8List chunk) => chunk).toList());
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, Object?> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

ResponseBody _sse(List<String> payloads, {int status = 200}) =>
    ResponseBody.fromString(
      payloads.map((String payload) => 'data: $payload\n\n').join(),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );

AiProviderConfig _config({
  String baseUrl = 'http://127.0.0.1:11434/v1',
  String? apiKey,
  String model = 'qwen2.5:7b',
  double temperature = 0.7,
  int? maxTokens,
}) {
  return AiProviderConfig(
    id: 'p1',
    name: '本地',
    baseUrl: baseUrl,
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    createdAt: DateTime(2026, 10, 6),
    updatedAt: DateTime(2026, 10, 6),
  );
}

OpenAiCompatibleProvider _provider(
  _FakeAdapter adapter, {
  AiProviderConfig? config,
}) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return OpenAiCompatibleProvider(
    config: config ?? _config(),
    dio: dio,
  );
}

const AiChatRequest _request = AiChatRequest(
  messages: <AiMessage>[
    AiMessage.system('你是日程助手'),
    AiMessage.user('今天有什么安排？'),
  ],
);

void main() {
  group('Base URL 规范化', () {
    test('补齐 /chat/completions，兼容有无 /v1 与结尾斜杠', () {
      expect(
        OpenAiCompatibleProvider.resolveChatCompletionsUrl(
          'https://api.deepseek.com',
        ),
        'https://api.deepseek.com/chat/completions',
      );
      expect(
        OpenAiCompatibleProvider.resolveChatCompletionsUrl(
          'https://api.deepseek.com/v1/',
        ),
        'https://api.deepseek.com/v1/chat/completions',
      );
      expect(
        OpenAiCompatibleProvider.resolveChatCompletionsUrl(
          'http://127.0.0.1:11434/v1',
        ),
        'http://127.0.0.1:11434/v1/chat/completions',
      );
      expect(
        OpenAiCompatibleProvider.resolveChatCompletionsUrl(
          'http://127.0.0.1:1234/v1/chat/completions',
        ),
        'http://127.0.0.1:1234/v1/chat/completions',
      );
    });

    test('模型列表地址补 /models，并兜底去掉误填的 /chat/completions', () {
      expect(
        OpenAiCompatibleProvider.resolveModelsUrl('https://api.deepseek.com'),
        'https://api.deepseek.com/models',
      );
      expect(
        OpenAiCompatibleProvider.resolveModelsUrl(
          'https://api.xiaomimimo.com/v1/',
        ),
        'https://api.xiaomimimo.com/v1/models',
      );
      expect(
        OpenAiCompatibleProvider.resolveModelsUrl(
          'http://127.0.0.1:11434/v1/models',
        ),
        'http://127.0.0.1:11434/v1/models',
      );
      expect(
        OpenAiCompatibleProvider.resolveModelsUrl(
          'https://api.deepseek.com/v1/chat/completions',
        ),
        'https://api.deepseek.com/v1/models',
      );
    });
  });

  group('模型列表', () {
    test('GET {baseUrl}/models，解析 OpenAI 的 data[].id 并排序去重', () async {
      final adapter = _FakeAdapter(
        (_) => _json(<String, Object?>{
          'object': 'list',
          'data': <Object?>[
            <String, Object?>{'id': 'mimo-v2.6-pro', 'object': 'model'},
            <String, Object?>{'id': 'mimo-v2.5', 'object': 'model'},
            <String, Object?>{'id': 'mimo-v2.6-pro', 'object': 'model'},
            <String, Object?>{'object': 'model'},
          ],
        }),
      );

      final models = await _provider(adapter).listModels();

      expect(models, <String>['mimo-v2.5', 'mimo-v2.6-pro']);
      expect(adapter.lastRequest?.method, 'GET');
      expect(
        adapter.lastRequest?.uri.toString(),
        'http://127.0.0.1:11434/v1/models',
      );
    });

    test('兼容 models[].name 与纯数组两种写法', () {
      expect(
        OpenAiCompatibleProvider.parseModels(<String, Object?>{
          'models': <Object?>[
            <String, Object?>{'name': 'glm-4-flash'},
          ],
        }),
        <String>['glm-4-flash'],
      );
      expect(
        OpenAiCompatibleProvider.parseModels(<Object?>['b', 'a']),
        <String>['a', 'b'],
      );
      expect(
        OpenAiCompatibleProvider.parseModels(<String, Object?>{'nope': 1}),
        isEmpty,
      );
    });

    test('带 Key 时请求头仍然是 Bearer，且 401 给出可读原因', () async {
      final adapter = _FakeAdapter(
        (_) => _json(<String, Object?>{}, status: 401),
      );
      try {
        await _provider(adapter, config: _config(apiKey: 'sk-secret'))
            .listModels();
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        expect(error.message, contains('HTTP 401'));
        expect(error.message, isNot(contains('sk-secret')));
      }
      expect(adapter.lastRequest?.headers['Authorization'], 'Bearer sk-secret');
    });
  });

  group('非流式 chat', () {
    test('发送 model/messages/temperature，并解析回复内容', () async {
      final adapter = _FakeAdapter(
        (_) => _json(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{
                'role': 'assistant',
                'content': '今天有 3 个安排'
              },
              'finish_reason': 'stop',
            },
          ],
        }),
      );
      final provider = _provider(
        adapter,
        config: _config(maxTokens: 256),
      );

      final response = await provider.chat(
        const AiChatRequest(
          messages: <AiMessage>[AiMessage.user('今天有什么安排？')],
          temperature: 0.2,
        ),
      );

      expect(response.content, '今天有 3 个安排');
      expect(response.finishReason, 'stop');

      final body = jsonDecode(adapter.lastBody!) as Map<String, Object?>;
      expect(body['model'], 'qwen2.5:7b');
      expect(body['temperature'], 0.2);
      expect(body['max_tokens'], 256);
      expect(body['stream'], false);
      expect((body['messages']! as List<Object?>).length, 1);
      expect(adapter.lastRequest!.uri.toString(),
          'http://127.0.0.1:11434/v1/chat/completions');
    });

    test('没有 API Key 时不发送 Authorization 头（本地 Ollama 场景）', () async {
      final adapter = _FakeAdapter(
        (_) => _json(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{'content': 'ok'},
            },
          ],
        }),
      );
      await _provider(adapter).chat(_request);

      expect(
          adapter.lastRequest!.headers.containsKey('Authorization'), isFalse);
    });

    test('有 API Key 时带上 Bearer 头', () async {
      final adapter = _FakeAdapter(
        (_) => _json(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{'content': 'ok'},
            },
          ],
        }),
      );
      await _provider(adapter, config: _config(apiKey: 'sk-secret-123'))
          .chat(_request);

      expect(
        adapter.lastRequest!.headers['Authorization'],
        'Bearer sk-secret-123',
      );
    });

    test('返回体结构异常时报错而不是崩溃', () async {
      final adapter =
          _FakeAdapter((_) => _json(<String, Object?>{'foo': 'bar'}));
      expect(
        () => _provider(adapter).chat(_request),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('流式 chatStream', () {
    test('逐块产出增量文本，并在 [DONE] 结束', () async {
      final adapter = _FakeAdapter(
        (_) => _sse(<String>[
          '{"choices":[{"delta":{"role":"assistant"}}]}',
          '{"choices":[{"delta":{"content":"今天"}}]}',
          '{"choices":[{"delta":{"content":"有 3 个"}}]}',
          '{"choices":[{"delta":{"content":"安排"}}]}',
          '[DONE]',
        ]),
      );

      final chunks = await _provider(adapter).chatStream(_request).toList();
      final text = chunks.map((AiResponseChunk chunk) => chunk.delta).join();

      expect(text, '今天有 3 个安排');
      expect(chunks.last.done, isTrue);
    });

    test('忽略 keep-alive 注释与空行，兼容 data: 后没有空格', () async {
      final adapter = _FakeAdapter(
        (_) => ResponseBody.fromString(
          ': keep-alive\n\n'
          'data:{"choices":[{"delta":{"content":"A"}}]}\n\n'
          '\n'
          'data: {"choices":[{"delta":{"content":"B"}}]}\n\n'
          'data: [DONE]\n\n',
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/event-stream'],
          },
        ),
      );

      final chunks = await _provider(adapter).chatStream(_request).toList();
      expect(chunks.map((AiResponseChunk c) => c.delta).join(), 'AB');
    });

    test('UTF-8 字符跨分片也能正确解码', () async {
      final bytes = utf8.encode(
        'data: {"choices":[{"delta":{"content":"你好世界"}}]}\n\n'
        'data: [DONE]\n\n',
      );
      // 在"你"这个三字节字符中间切开。
      final first = bytes.sublist(0, bytes.indexOf(0xE4) + 1);
      final second = bytes.sublist(bytes.indexOf(0xE4) + 1);

      final adapter = _FakeAdapter(
        (_) => ResponseBody(
          Stream<Uint8List>.fromIterable(<Uint8List>[first, second]),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/event-stream'],
          },
        ),
      );

      final chunks = await _provider(adapter).chatStream(_request).toList();
      expect(chunks.map((AiResponseChunk c) => c.delta).join(), '你好世界');
    });

    test('没有 [DONE] 时流结束也会给出 done 标记', () async {
      final adapter = _FakeAdapter(
        (_) => _sse(<String>['{"choices":[{"delta":{"content":"hi"}}]}']),
      );
      final chunks = await _provider(adapter).chatStream(_request).toList();
      expect(chunks.last.done, isTrue);
      expect(chunks.map((AiResponseChunk c) => c.delta).join(), 'hi');
    });
  });

  group('错误处理（不泄漏 API Key）', () {
    test('401 提示 Key 可能无效，且异常里不含 Key 原文', () async {
      const apiKey = 'sk-super-secret-value';
      final adapter = _FakeAdapter(
        (_) => _json(
          <String, Object?>{
            'error': <String, Object?>{'message': 'Invalid API key'},
          },
          status: 401,
        ),
      );

      try {
        await _provider(adapter, config: _config(apiKey: apiKey))
            .chat(_request);
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        expect(error.message, contains('HTTP 401'));
        expect(error.message, contains('API Key 可能无效'));
        expect(error.message, isNot(contains(apiKey)));
        expect(error.toString(), isNot(contains(apiKey)));
      }
    });

    test('404 提示检查 Base URL', () async {
      final adapter =
          _FakeAdapter((_) => _json(<String, Object?>{}, status: 404));
      try {
        await _provider(adapter).chat(_request);
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        expect(error.message, contains('HTTP 404'));
        expect(error.message, contains('Base URL'));
      }
    });

    test('连接失败给出可读提示', () async {
      final adapter = _FakeAdapter(
        (RequestOptions options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
        ),
      );
      try {
        await _provider(adapter).chat(_request);
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        expect(error.message, contains('无法连接 AI 服务'));
      }
    });

    test('流式请求失败同样是 AppException', () async {
      final adapter =
          _FakeAdapter((_) => _json(<String, Object?>{}, status: 500));
      expect(
        () => _provider(adapter).chatStream(_request).toList(),
        throwsA(isA<AppException>()),
      );
    });

    test('流式请求的错误体要读出来，不能是 Instance of ResponseBody', () async {
      // 流式请求的 response.data 是 ResponseBody（一个流），直接 toString()
      // 只会得到 "Instance of 'ResponseBody'"，用户看不懂。
      final adapter = _FakeAdapter(
        (_) => _json(
          <String, Object?>{
            'error': <String, Object?>{'message': 'Invalid API key'},
          },
          status: 401,
        ),
      );
      try {
        await _provider(adapter).chatStream(_request).toList();
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        expect(error.message, contains('HTTP 401'));
        expect(error.message, contains('Invalid API key'));
        expect(error.message, isNot(contains('Instance of')));
      }
    });
  });
}
