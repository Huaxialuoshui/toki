import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/services/ai_provider.dart';

/// OpenAI Compatible 实现（规格 §2）。
///
/// 兼容 OpenAI / DeepSeek / Qwen / Moonshot / 智谱 / Ollama / LM Studio 等：
/// 只要服务提供 `POST {baseUrl}/chat/completions`（含 SSE 流式）即可。
///
/// 安全约定：API Key 只出现在请求头里，任何错误信息、日志、异常里都不带 Key。
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({
    required this.config,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 120),
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: connectTimeout,
                receiveTimeout: receiveTimeout,
                // 不跟随 3xx 之外的特殊处理；默认即可。
              ),
            );

  final AiProviderConfig config;
  final Dio _dio;

  /// 把用户填的 Base URL 规范化成 chat/completions 端点。
  ///
  /// 支持这些写法：
  /// * `https://api.deepseek.com`
  /// * `https://api.deepseek.com/v1`
  /// * `https://api.deepseek.com/v1/`
  /// * `http://127.0.0.1:11434/v1`
  /// * `.../v1/chat/completions`（原样使用）
  static String resolveChatCompletionsUrl(String baseUrl) {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/chat/completions')) return url;
    return '$url/chat/completions';
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final key = config.apiKey;
    if (key != null && key.trim().isNotEmpty) {
      // 本地 Ollama 之类不需要 Key，因此只在非空时带上。
      headers['Authorization'] = 'Bearer ${key.trim()}';
    }
    return headers;
  }

  Map<String, Object?> _body(AiChatRequest request, {required bool stream}) {
    return <String, Object?>{
      'model': config.model,
      'messages': request.messages
          .map((AiMessage message) => message.toJson())
          .toList(growable: false),
      'temperature': request.temperature ?? config.temperature,
      if ((request.maxTokens ?? config.maxTokens) != null)
        'max_tokens': request.maxTokens ?? config.maxTokens,
      'stream': stream,
      if (request.tools.isNotEmpty)
        'tools': request.tools
            .map((AiToolDefinition tool) => tool.toJson())
            .toList(growable: false),
      if (request.tools.isNotEmpty) 'tool_choice': 'auto',
    };
  }

  @override
  Future<AiResponse> chat(AiChatRequest request) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        resolveChatCompletionsUrl(config.baseUrl),
        data: _body(request, stream: false),
        options: Options(headers: _headers()),
      );
    } on DioException catch (error) {
      throw await _mapDioError(error);
    }

    final data = response.data;
    if (data is! Map) {
      throw const AppException('AI 返回格式无法解析');
    }
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AppException('AI 没有返回任何内容');
    }
    final first = choices.first;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    return AiResponse(
      content: content is String ? content : '',
      finishReason: first is Map && first['finish_reason'] is String
          ? first['finish_reason'] as String
          : null,
      toolCalls: _toolCallsOf(message is Map ? message['tool_calls'] : null),
    );
  }

  /// 解析非流式响应里的 tool_calls。
  static List<AiToolCall> _toolCallsOf(Object? raw) {
    if (raw is! List) return const <AiToolCall>[];
    final calls = <AiToolCall>[];
    var index = 0;
    for (final entry in raw) {
      if (entry is! Map) continue;
      final function = entry['function'];
      if (function is! Map) continue;
      calls.add(
        AiToolCall(
          id: entry['id'] is String ? entry['id'] as String : 'call-$index',
          name: function['name'] is String ? function['name'] as String : '',
          argumentsJson: function['arguments'] is String
              ? function['arguments'] as String
              : '',
        ),
      );
      index++;
    }
    return calls;
  }

  @override
  Stream<AiResponseChunk> chatStream(AiChatRequest request) async* {
    final Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        resolveChatCompletionsUrl(config.baseUrl),
        data: _body(request, stream: true),
        options: Options(
          headers: _headers(),
          responseType: ResponseType.stream,
        ),
      );
    } on DioException catch (error) {
      throw await _mapDioError(error, streamed: true);
    }

    final body = response.data;
    if (body == null) {
      throw const AppException('AI 返回了空响应');
    }

    // utf8.decoder 处理跨分片的 UTF-8 字符，LineSplitter 处理跨分片的行。
    final lines =
        utf8.decoder.bind(body.stream).transform(const LineSplitter());

    final builders = <int, _ToolCallBuilder>{};

    await for (final String line in lines) {
      final payload = _sseData(line);
      if (payload == null) continue;
      if (payload == '[DONE]') {
        if (builders.isNotEmpty) {
          yield AiResponseChunk(toolCalls: _finishToolCalls(builders));
        }
        yield const AiResponseChunk(delta: '', done: true);
        return;
      }

      _collectToolCalls(payload, builders);

      final delta = _deltaOf(payload);
      if (delta == null) continue;
      if (delta.isEmpty) continue;
      yield AiResponseChunk(delta: delta);
    }

    // 有些服务端不发 [DONE]，直接结束流。
    if (builders.isNotEmpty) {
      yield AiResponseChunk(toolCalls: _finishToolCalls(builders));
    }
    yield const AiResponseChunk(delta: '', done: true);
  }

  /// 累积流式返回的 tool_calls 分片（id / name / arguments 都可能被切开）。
  static void _collectToolCalls(
    String payload,
    Map<int, _ToolCallBuilder> builders,
  ) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return;
      final first = choices.first;
      if (first is! Map) return;
      final delta = first['delta'];
      if (delta is! Map) return;
      final toolCalls = delta['tool_calls'];
      if (toolCalls is! List) return;

      for (final entry in toolCalls) {
        if (entry is! Map) continue;
        final index = entry['index'] is int ? entry['index'] as int : 0;
        final builder = builders.putIfAbsent(index, _ToolCallBuilder.new);
        if (entry['id'] is String) builder.id = entry['id'] as String;
        final function = entry['function'];
        if (function is Map) {
          if (function['name'] is String &&
              (function['name'] as String).isNotEmpty) {
            builder.name = function['name'] as String;
          }
          if (function['arguments'] is String) {
            builder.arguments.write(function['arguments'] as String);
          }
        }
      }
    } on FormatException {
      // 分片不完整时不处理，等下一块补齐。
    }
  }

  static List<AiToolCall> _finishToolCalls(
    Map<int, _ToolCallBuilder> builders,
  ) {
    final indexes = builders.keys.toList()..sort();
    return <AiToolCall>[
      for (final index in indexes)
        AiToolCall(
          id: builders[index]!.id.isEmpty ? 'call-$index' : builders[index]!.id,
          name: builders[index]!.name,
          argumentsJson: builders[index]!.arguments.toString(),
        ),
    ];
  }

  /// 取出一行 SSE 里的 data 负载；非 data 行（空行 / 注释 / event: 行）返回 null。
  static String? _sseData(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('data:')) return null;
    return trimmed.substring('data:'.length).trim();
  }

  /// 从一个 data 负载里取出增量文本。
  static String? _deltaOf(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final delta = first['delta'];
      if (delta is Map && delta['content'] is String) {
        return delta['content'] as String;
      }
      // 少数服务端在流里返回完整 message。
      final message = first['message'];
      if (message is Map && message['content'] is String) {
        return message['content'] as String;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<AppException> _mapDioError(
    DioException error, {
    bool streamed = false,
  }) async {
    final status = error.response?.statusCode;
    if (status != null) {
      final snippet = await _snippetOf(error.response?.data);
      final hint = switch (status) {
        401 || 403 => '（API Key 可能无效或没有权限）',
        404 => '（检查 Base URL 是否正确）',
        429 => '（触发限流，稍后再试）',
        _ => '',
      };
      return AppException(
        'AI 服务返回 HTTP $status$hint${snippet.isEmpty ? '' : '：$snippet'}',
      );
    }

    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.transformTimeout =>
        '连接 AI 服务超时',
      DioExceptionType.receiveTimeout => 'AI 服务响应超时',
      DioExceptionType.connectionError => '无法连接 AI 服务（检查网络或 Base URL）',
      DioExceptionType.cancel => 'AI 请求已取消',
      DioExceptionType.badCertificate => 'AI 服务证书校验失败',
      DioExceptionType.badResponse => 'AI 服务响应异常',
      DioExceptionType.unknown => 'AI 请求失败',
    };
    // 注意：cause 里也不放 API Key（dio 的异常对象本身不含请求头）。
    return AppException(streamed ? '$message（流式）' : message);
  }

  /// 只取响应体的一小段作为错误提示，避免把大段内容塞进 UI。
  /// 错误响应可能是普通字符串，也可能是流式请求的 `ResponseBody`。
  /// 后者必须把流读出来，否则只会得到无用的 `Instance of 'ResponseBody'`。
  static Future<String> _snippetOf(Object? data) async {
    if (data == null) return '';
    String text;
    if (data is ResponseBody) {
      try {
        text = utf8.decode(
          await data.stream.fold<List<int>>(
            <int>[],
            (List<int> acc, List<int> chunk) => acc..addAll(chunk),
          ),
        );
      } on Object {
        text = '';
      }
    } else {
      text = data is String ? data : data.toString();
    }
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length <= 200 ? oneLine : '${oneLine.substring(0, 200)}…';
  }
}

/// 流式 tool_calls 的累积器。
class _ToolCallBuilder {
  String id = '';
  String name = '';
  final StringBuffer arguments = StringBuffer();
}
