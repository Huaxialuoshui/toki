import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/weather.dart';
import '../../domain/services/weather_service.dart';

/// Open-Meteo 实现：**不需要 API Key**，适合本地优先的应用。
///
/// * 城市名 → 经纬度：`geocoding-api.open-meteo.com`（支持中文城市名）
/// * 经纬度 → 当前天气：`api.open-meteo.com/v1/forecast`
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({
    Dio? dio,
    this.languageCode = 'zh',
    Duration timeout = const Duration(seconds: 10),
    DateTime Function()? now,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: timeout,
                receiveTimeout: timeout,
              ),
            ),
        _now = now ?? DateTime.now;

  final Dio _dio;

  /// 取"当前时间"的方式（测试里可以注入固定时间）。
  final DateTime Function() _now;

  /// 城市搜索结果的语言（跟界面语言走）。
  final String languageCode;

  static const String geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<WeatherSnapshot> fetch(String city) async {
    final name = city.trim();
    if (name.isEmpty) {
      throw const AppException('天气：请先在设置里填写城市');
    }

    final place = await _geocode(name);
    final weather = await _current(
      latitude: place.latitude,
      longitude: place.longitude,
      label: place.name,
      withCoordinates: false,
    );

    return weather.snapshot;
  }

  @override
  Future<WeatherSnapshot> fetchByCoordinates({
    required double latitude,
    required double longitude,
    String label = '当前位置',
  }) async {
    final weather = await _current(
      latitude: latitude,
      longitude: longitude,
      label: label,
      withCoordinates: true,
    );
    return weather.snapshot;
  }

  Future<_Place> _geocode(String city) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        geocodingUrl,
        queryParameters: <String, Object?>{
          'name': city,
          'count': 1,
          'language': languageCode,
          'format': 'json',
        },
      );
    } on DioException catch (error) {
      throw AppException(_describe(error, '查询城市失败'));
    }

    final data = response.data;
    final results = data is Map ? data['results'] : null;
    if (results is! List || results.isEmpty) {
      throw AppException('天气：找不到城市「$city」');
    }
    final first = results.first;
    if (first is! Map) {
      throw const AppException('天气：城市数据格式异常');
    }
    final latitude = (first['latitude'] as num?)?.toDouble();
    final longitude = (first['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw const AppException('天气：城市数据缺少经纬度');
    }
    return _Place(
      name: '${first['name'] ?? city}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<_Reading> _current({
    required double latitude,
    required double longitude,
    required String label,
    required bool withCoordinates,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        forecastUrl,
        queryParameters: <String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,weather_code',
          'hourly': 'temperature_2m,weather_code',
          'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
          'forecast_days': 5,
          'forecast_hours': 24,
          'timezone': 'auto',
        },
      );
    } on DioException catch (error) {
      throw AppException(_describe(error, '获取天气失败'));
    }

    final data = response.data;
    if (data is! Map) throw const AppException('天气：返回格式异常');

    final current = data['current'];
    final temperature =
        current is Map ? (current['temperature_2m'] as num?)?.toDouble() : null;
    final code =
        current is Map ? (current['weather_code'] as num?)?.toInt() : null;
    if (temperature == null) throw const AppException('天气：返回里没有温度');

    final days = _parseDays(data['daily']);
    final hours = _parseHours(data['hourly']);
    final now = _now();
    final upcoming = hours
        .where((WeatherHour h) =>
            !h.time.isBefore(now.subtract(const Duration(hours: 1))))
        .take(12)
        .toList(growable: false);

    return _Reading(
      snapshot: WeatherSnapshot(
        city: label,
        condition: WeatherCondition.fromCode(code),
        temperature: temperature,
        tempMax: days.isEmpty ? null : days.first.tempMax,
        tempMin: days.isEmpty ? null : days.first.tempMin,
        hourly: upcoming,
        daily: days,
        latitude: withCoordinates ? latitude : null,
        longitude: withCoordinates ? longitude : null,
        fetchedAt: _now(),
      ),
    );
  }

  /// 解析 `daily`：时间数组 + 天气码数组 + 高低温数组（索引对齐）。
  static List<WeatherDay> _parseDays(Object? raw) {
    if (raw is! Map) return const <WeatherDay>[];
    final times = raw['time'];
    if (times is! List) return const <WeatherDay>[];
    final codes = raw['weather_code'];
    final maxes = raw['temperature_2m_max'];
    final mins = raw['temperature_2m_min'];

    T? at<T>(Object? list, int index) {
      if (list is! List || index >= list.length) return null;
      return list[index] as T?;
    }

    final days = <WeatherDay>[];
    for (var i = 0; i < times.length; i++) {
      final date = DateTime.tryParse('${times[i]}');
      if (date == null) continue;
      days.add(
        WeatherDay(
          date: date,
          condition: WeatherCondition.fromCode(at<num>(codes, i)?.toInt()),
          tempMax: at<num>(maxes, i)?.toDouble(),
          tempMin: at<num>(mins, i)?.toDouble(),
        ),
      );
    }
    return days;
  }

  /// 解析 `hourly`（时间 / 温度 / 天气码）。
  static List<WeatherHour> _parseHours(Object? raw) {
    if (raw is! Map) return const <WeatherHour>[];
    final times = raw['time'];
    if (times is! List) return const <WeatherHour>[];
    final temps = raw['temperature_2m'];
    final codes = raw['weather_code'];

    T? at<T>(Object? list, int index) {
      if (list is! List || index >= list.length) return null;
      return list[index] as T?;
    }

    final hours = <WeatherHour>[];
    for (var i = 0; i < times.length; i++) {
      final time = DateTime.tryParse('${times[i]}');
      final temp = at<num>(temps, i)?.toDouble();
      if (time == null || temp == null) continue;
      hours.add(
        WeatherHour(
          time: time,
          temperature: temp,
          condition: WeatherCondition.fromCode(at<num>(codes, i)?.toInt()),
        ),
      );
    }
    return hours;
  }

  String _describe(DioException error, String fallback) {
    final status = error.response?.statusCode;
    if (status != null) return '天气：HTTP $status';
    return '天气：$fallback（检查网络）';
  }
}

class _Place {
  const _Place({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

class _Reading {
  const _Reading({required this.snapshot});

  final WeatherSnapshot snapshot;
}
