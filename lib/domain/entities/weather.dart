import 'package:flutter/foundation.dart';

/// 天气状况（把 WMO code 归并成几类，方便配图标和文案）。
enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  thunder,
  unknown;

  /// WMO weather code → 归类（Open-Meteo 用这套编码）。
  static WeatherCondition fromCode(int? code) {
    if (code == null) return WeatherCondition.unknown;
    if (code == 0) return WeatherCondition.clear;
    if (code == 1 || code == 2) return WeatherCondition.partlyCloudy;
    if (code == 3) return WeatherCondition.cloudy;
    if (code == 45 || code == 48) return WeatherCondition.fog;
    if (code >= 51 && code <= 57) return WeatherCondition.drizzle;
    if (code >= 61 && code <= 67) return WeatherCondition.rain;
    if (code >= 71 && code <= 77) return WeatherCondition.snow;
    if (code >= 80 && code <= 82) return WeatherCondition.rain;
    if (code == 85 || code == 86) return WeatherCondition.snow;
    if (code >= 95 && code <= 99) return WeatherCondition.thunder;
    return WeatherCondition.unknown;
  }
}

/// 一次天气快照（规格 §6 首页顶部）。
@immutable
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.condition,
    required this.temperature,
    required this.fetchedAt,
    this.tempMax,
    this.tempMin,
  });

  final String city;
  final WeatherCondition condition;

  /// 当前温度（摄氏度）。
  final double temperature;
  final double? tempMax;
  final double? tempMin;
  final DateTime fetchedAt;

  /// 缓存是否还新鲜（默认 30 分钟）。
  bool isFresh(DateTime now, {Duration ttl = const Duration(minutes: 30)}) =>
      now.difference(fetchedAt) < ttl;

  Map<String, Object?> toJson() => <String, Object?>{
        'city': city,
        'condition': condition.name,
        'temperature': temperature,
        'tempMax': tempMax,
        'tempMin': tempMin,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  static WeatherSnapshot? fromJson(Map<String, Object?> json) {
    final city = json['city'];
    final fetchedAt = DateTime.tryParse('${json['fetchedAt']}');
    if (city is! String || fetchedAt == null) return null;
    return WeatherSnapshot(
      city: city,
      condition: WeatherCondition.values.firstWhere(
        (WeatherCondition value) => value.name == json['condition'],
        orElse: () => WeatherCondition.unknown,
      ),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      tempMax: (json['tempMax'] as num?)?.toDouble(),
      tempMin: (json['tempMin'] as num?)?.toDouble(),
      fetchedAt: fetchedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherSnapshot &&
        other.city == city &&
        other.condition == condition &&
        other.temperature == temperature &&
        other.tempMax == tempMax &&
        other.tempMin == tempMin &&
        other.fetchedAt == fetchedAt;
  }

  @override
  int get hashCode =>
      Object.hash(city, condition, temperature, tempMax, tempMin, fetchedAt);
}
