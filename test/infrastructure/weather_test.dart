import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/domain/entities/weather.dart';
import 'package:toki/infrastructure/weather/open_meteo_weather_service.dart';

/// 天气（规格 §6）：WMO 编码归类 + Open-Meteo 解析。
void main() {
  group('天气编码归类', () {
    test('常见 WMO code 映射到对应状况', () {
      expect(WeatherCondition.fromCode(0), WeatherCondition.clear);
      expect(WeatherCondition.fromCode(1), WeatherCondition.partlyCloudy);
      expect(WeatherCondition.fromCode(2), WeatherCondition.partlyCloudy);
      expect(WeatherCondition.fromCode(3), WeatherCondition.cloudy);
      expect(WeatherCondition.fromCode(45), WeatherCondition.fog);
      expect(WeatherCondition.fromCode(53), WeatherCondition.drizzle);
      expect(WeatherCondition.fromCode(63), WeatherCondition.rain);
      expect(WeatherCondition.fromCode(81), WeatherCondition.rain);
      expect(WeatherCondition.fromCode(73), WeatherCondition.snow);
      expect(WeatherCondition.fromCode(86), WeatherCondition.snow);
      expect(WeatherCondition.fromCode(96), WeatherCondition.thunder);
      expect(WeatherCondition.fromCode(1234), WeatherCondition.unknown);
      expect(WeatherCondition.fromCode(null), WeatherCondition.unknown);
    });
  });

  group('快照', () {
    test('JSON 往返保留字段', () {
      final snapshot = WeatherSnapshot(
        city: '上海',
        condition: WeatherCondition.rain,
        temperature: 21.5,
        tempMax: 25,
        tempMin: 18,
        fetchedAt: DateTime(2026, 10, 7, 9),
      );

      final restored = WeatherSnapshot.fromJson(snapshot.toJson())!;
      expect(restored, snapshot);
      expect(restored.condition, WeatherCondition.rain);
    });

    test('缓存新鲜度', () {
      final snapshot = WeatherSnapshot(
        city: '上海',
        condition: WeatherCondition.clear,
        temperature: 20,
        fetchedAt: DateTime(2026, 10, 7, 9),
      );

      expect(snapshot.isFresh(DateTime(2026, 10, 7, 9, 10)), isTrue);
      expect(snapshot.isFresh(DateTime(2026, 10, 7, 10)), isFalse);
    });

    test('缺字段或格式错误时返回 null 而不是抛异常', () {
      expect(WeatherSnapshot.fromJson(<String, Object?>{}), isNull);
      expect(
        WeatherSnapshot.fromJson(<String, Object?>{'city': '上海'}),
        isNull,
      );
    });
  });

  group('Open-Meteo 解析', () {
    ResponseBody json(Map<String, Object?> body, {int status = 200}) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );

    Dio dioWith(
        FutureOr<ResponseBody> Function(RequestOptions options) handler) {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(handler);
      return dio;
    }

    test('先查城市再查天气，首页拿到温度与状况', () async {
      final paths = <String>[];
      final service = OpenMeteoWeatherService(
        now: () => DateTime(2026, 10, 7, 9, 30),
        dio: dioWith((RequestOptions options) {
          paths.add(options.uri.path);
          if (options.uri.host.contains('geocoding')) {
            return json(<String, Object?>{
              'results': <Object?>[
                <String, Object?>{
                  'name': '上海',
                  'latitude': 31.22,
                  'longitude': 121.46,
                },
              ],
            });
          }
          return json(<String, Object?>{
            'current': <String, Object?>{
              'temperature_2m': 23.4,
              'weather_code': 61,
            },
            'hourly': <String, Object?>{
              'time': <Object?>[
                '2026-10-07T09:00',
                '2026-10-07T10:00',
                '2026-10-07T11:00',
              ],
              'temperature_2m': <Object?>[22.1, 23.4, 24.0],
              'weather_code': <Object?>[3, 61, 2],
            },
            'daily': <String, Object?>{
              'time': <Object?>['2026-10-07', '2026-10-08'],
              'weather_code': <Object?>[61, 3],
              'temperature_2m_max': <Object?>[27.1, 26.0],
              'temperature_2m_min': <Object?>[19.2, 18.0],
            },
          });
        }),
      );

      final snapshot = await service.fetch('上海');

      expect(paths, hasLength(2));
      expect(snapshot.city, '上海');
      expect(snapshot.temperature, 23.4);
      expect(snapshot.condition, WeatherCondition.rain);
      expect(snapshot.tempMax, 27.1);
      expect(snapshot.tempMin, 19.2);
      expect(snapshot.daily, hasLength(2));
      expect(snapshot.daily.last.condition, WeatherCondition.cloudy);
      // 逐小时里晚于"现在"的那些（测试固定不了系统时间，只校验解析结果）
      expect(snapshot.hourly.map((WeatherHour h) => h.temperature),
          contains(23.4));
    });

    test('城市查不到时给出可读错误', () async {
      final service = OpenMeteoWeatherService(
        dio: dioWith((_) => json(<String, Object?>{'results': <Object?>[]})),
      );

      await expectLater(
        service.fetch('不存在的城市'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.message,
            'message',
            contains('找不到城市'),
          ),
        ),
      );
    });

    test('空城市名不发请求', () async {
      var calls = 0;
      final service = OpenMeteoWeatherService(
        dio: dioWith((_) {
          calls++;
          return json(<String, Object?>{});
        }),
      );

      await expectLater(
        service.fetch('   '),
        throwsA(isA<AppException>()),
      );
      expect(calls, 0);
    });

    test('HTTP 失败时错误信息里带状态码', () async {
      final service = OpenMeteoWeatherService(
        dio: dioWith((_) => json(<String, Object?>{}, status: 503)),
      );

      await expectLater(
        service.fetch('上海'),
        throwsA(
          isA<AppException>().having(
            (AppException e) => e.message,
            'message',
            contains('503'),
          ),
        ),
      );
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

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
