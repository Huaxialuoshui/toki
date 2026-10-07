import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/domain/services/recurrence.dart';
import 'package:toki/infrastructure/ai/openai_compatible_provider.dart';

/// Phase 13 质量清单：通知重复 / AI 失败与超时 / 跨年 / 边界。
void main() {
  group('重复日程的跨年 / 边界', () {
    CalendarEvent daily(DateTime start, {DateTime? until}) => CalendarEvent(
          id: 'e',
          title: '每日',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          repeatRule: 'daily',
          repeatUntil: until,
          createdAt: start,
          updatedAt: start,
        );

    test('每天重复跨年：12/31 与 1/1 都在', () {
      final event = daily(DateTime(2026, 12, 30, 9));

      final starts = expandRepeatTimes(
        origin: event.startTime,
        rule: RepeatRule.daily,
        from: DateTime(2026, 12, 30),
        to: DateTime(2027, 1, 3),
      );

      expect(starts, <DateTime>[
        DateTime(2026, 12, 30, 9),
        DateTime(2026, 12, 31, 9),
        DateTime(2027, 1, 1, 9),
        DateTime(2027, 1, 2, 9),
      ]);
    });

    test('每月重复跨年：12 月 → 次年 1 月', () {
      final starts = expandRepeatTimes(
        origin: DateTime(2026, 11, 15, 9),
        rule: RepeatRule.monthly,
        from: DateTime(2026, 11, 1),
        to: DateTime(2027, 2, 1),
      );

      expect(starts, <DateTime>[
        DateTime(2026, 11, 15, 9),
        DateTime(2026, 12, 15, 9),
        DateTime(2027, 1, 15, 9),
      ]);
    });

    test('跨天事件：刚好在窗口边界结束也算命中', () {
      final event = CalendarEvent(
        id: 'e2',
        title: '夜班',
        startTime: DateTime(2026, 10, 6, 23),
        endTime: DateTime(2026, 10, 7),
        createdAt: DateTime(2026, 10, 6),
        updatedAt: DateTime(2026, 10, 6),
      );

      // 窗口从 10/7 00:00 开始：结束时间正好等于窗口起点，视为命中。
      expect(
        expandOccurrences(event, DateTime(2026, 10, 7), DateTime(2026, 10, 8)),
        hasLength(1),
      );
    });
  });

  group('AI 失败与超时映射', () {
    ResponseBody json(Map<String, Object?> body, {int status = 200}) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );

    Future<AppException> errorFrom(
        DioException Function(RequestOptions) build) async {
      final dio = Dio();
      dio.httpClientAdapter =
          _Adapter((RequestOptions options) => throw build(options));
      final provider = OpenAiCompatibleProvider(
        config: _config(),
        dio: dio,
      );
      try {
        await provider.chat(
          const AiChatRequest(messages: <AiMessage>[AiMessage.user('hi')]),
        );
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        return error;
      }
    }

    test('连接超时 / 接收超时都有可读文案', () async {
      final connect = await errorFrom(
        (RequestOptions options) => DioException.connectionTimeout(
          requestOptions: options,
          timeout: const Duration(seconds: 15),
        ),
      );
      expect(connect.message, contains('超时'));

      final receive = await errorFrom(
        (RequestOptions options) => DioException.receiveTimeout(
          requestOptions: options,
          timeout: const Duration(seconds: 120),
        ),
      );
      expect(receive.message, contains('超时'));
    });

    test('证书错误 / 取消请求都有可读文案', () async {
      final certificate = await errorFrom(
        (RequestOptions options) => DioException.badCertificate(
          requestOptions: options,
        ),
      );
      expect(certificate.message, contains('证书'));

      final cancelled = await errorFrom(
        (RequestOptions options) => DioException.requestCancelled(
          requestOptions: options,
          reason: 'user',
        ),
      );
      expect(cancelled.message, contains('取消'));
    });

    test('429 限流给提示，且错误信息里没有 API Key', () async {
      final dio = Dio();
      dio.httpClientAdapter = _Adapter(
        (_) => json(<String, Object?>{'error': 'rate limited'}, status: 429),
      );
      final provider = OpenAiCompatibleProvider(
        config: _config(apiKey: 'sk-should-not-leak'),
        dio: dio,
      );

      try {
        await provider.chat(
          const AiChatRequest(messages: <AiMessage>[AiMessage.user('hi')]),
        );
        fail('应当抛出 AppException');
      } on AppException catch (error) {
        expect(error.message, contains('429'));
        expect(error.message, contains('限流'));
        expect(error.message, isNot(contains('sk-should-not-leak')));
        expect(error.toString(), isNot(contains('sk-should-not-leak')));
      }
    });

    test('响应不是 JSON 时给出可读错误而不是崩溃', () async {
      final dio = Dio();
      dio.httpClientAdapter = _Adapter(
        (_) => ResponseBody.fromString('not json', 200),
      );
      final provider = OpenAiCompatibleProvider(config: _config(), dio: dio);

      await expectLater(
        provider.chat(
          const AiChatRequest(messages: <AiMessage>[AiMessage.user('hi')]),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}

AiProviderConfig _config({String? apiKey}) => AiProviderConfig(
      id: 'p1',
      name: '测试',
      baseUrl: 'https://example.com/v1',
      apiKey: apiKey,
      model: 'test',
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 7),
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
