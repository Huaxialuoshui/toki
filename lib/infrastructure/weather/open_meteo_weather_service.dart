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
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: timeout,
                receiveTimeout: timeout,
              ),
            );

  final Dio _dio;

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
    );

    return WeatherSnapshot(
      city: place.name,
      condition: WeatherCondition.fromCode(weather.code),
      temperature: weather.temperature,
      tempMax: weather.max,
      tempMin: weather.min,
      fetchedAt: DateTime.now(),
    );
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
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        forecastUrl,
        queryParameters: <String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,weather_code',
          'daily': 'temperature_2m_max,temperature_2m_min',
          'forecast_days': 1,
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

    final daily = data['daily'];
    double? firstOf(String key) {
      if (daily is! Map) return null;
      final list = daily[key];
      if (list is! List || list.isEmpty) return null;
      return (list.first as num?)?.toDouble();
    }

    return _Reading(
      temperature: temperature,
      code: code,
      max: firstOf('temperature_2m_max'),
      min: firstOf('temperature_2m_min'),
    );
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
  const _Reading({
    required this.temperature,
    required this.code,
    this.max,
    this.min,
  });

  final double temperature;
  final int? code;
  final double? max;
  final double? min;
}
