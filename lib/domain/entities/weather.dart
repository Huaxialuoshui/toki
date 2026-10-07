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
    this.hourly = const <WeatherHour>[],
    this.daily = const <WeatherDay>[],
    this.latitude,
    this.longitude,
  });

  final String city;
  final WeatherCondition condition;

  /// 当前温度（摄氏度）。
  final double temperature;
  final double? tempMax;
  final double? tempMin;
  final DateTime fetchedAt;

  /// 未来若干小时的预报（通常 12 条）。
  final List<WeatherHour> hourly;

  /// 未来若干天的预报（通常 5 条，含今天）。
  final List<WeatherDay> daily;

  /// GPS 定位得到的坐标（按城市名查询时为 null）。
  final double? latitude;
  final double? longitude;

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
        'latitude': latitude,
        'longitude': longitude,
        'hourly': hourly.map((WeatherHour h) => h.toJson()).toList(),
        'daily': daily.map((WeatherDay d) => d.toJson()).toList(),
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hourly: _listOf(json['hourly'], WeatherHour.fromJson),
      daily: _listOf(json['daily'], WeatherDay.fromJson),
    );
  }

  static List<T> _listOf<T>(
    Object? raw,
    T? Function(Map<String, Object?>) parse,
  ) {
    if (raw is! List) return const <Never>[];
    final result = <T>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = parse(item.cast<String, Object?>());
      if (parsed != null) result.add(parsed);
    }
    return result;
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
        other.latitude == latitude &&
        other.longitude == longitude &&
        listEquals(other.hourly, hourly) &&
        listEquals(other.daily, daily) &&
        other.fetchedAt == fetchedAt;
  }

  @override
  int get hashCode => Object.hash(
        city,
        condition,
        temperature,
        tempMax,
        tempMin,
        fetchedAt,
        latitude,
        longitude,
        Object.hashAll(hourly),
        Object.hashAll(daily),
      );
}

/// 逐小时预报。
@immutable
class WeatherHour {
  const WeatherHour({
    required this.time,
    required this.temperature,
    required this.condition,
  });

  final DateTime time;
  final double temperature;
  final WeatherCondition condition;

  Map<String, Object?> toJson() => <String, Object?>{
        'time': time.toIso8601String(),
        'temperature': temperature,
        'condition': condition.name,
      };

  static WeatherHour? fromJson(Map<String, Object?> json) {
    final time = DateTime.tryParse('${json['time']}');
    if (time == null) return null;
    return WeatherHour(
      time: time,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      condition: _conditionOf(json['condition']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherHour &&
      other.time == time &&
      other.temperature == temperature &&
      other.condition == condition;

  @override
  int get hashCode => Object.hash(time, temperature, condition);
}

/// 多日预报。
@immutable
class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.condition,
    this.tempMax,
    this.tempMin,
  });

  final DateTime date;
  final WeatherCondition condition;
  final double? tempMax;
  final double? tempMin;

  Map<String, Object?> toJson() => <String, Object?>{
        'date': date.toIso8601String(),
        'condition': condition.name,
        'tempMax': tempMax,
        'tempMin': tempMin,
      };

  static WeatherDay? fromJson(Map<String, Object?> json) {
    final date = DateTime.tryParse('${json['date']}');
    if (date == null) return null;
    return WeatherDay(
      date: date,
      condition: _conditionOf(json['condition']),
      tempMax: (json['tempMax'] as num?)?.toDouble(),
      tempMin: (json['tempMin'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherDay &&
      other.date == date &&
      other.condition == condition &&
      other.tempMax == tempMax &&
      other.tempMin == tempMin;

  @override
  int get hashCode => Object.hash(date, condition, tempMax, tempMin);
}

WeatherCondition _conditionOf(Object? raw) =>
    WeatherCondition.values.firstWhere(
      (WeatherCondition value) => value.name == raw,
      orElse: () => WeatherCondition.unknown,
    );

/// 一个已保存的天气位置（规格：天气要能记住历史位置）。
///
/// * 按城市名查：`city` 非空、经纬度为空；
/// * 按 GPS 定位：`city` 为空（界面显示 [label]），带经纬度。
@immutable
class WeatherLocation {
  const WeatherLocation({
    required this.id,
    required this.label,
    required this.lastUsedAt,
    this.city,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final String? city;
  final double? latitude;
  final double? longitude;
  final DateTime lastUsedAt;

  bool get isGps => latitude != null && longitude != null;

  /// 同一个位置的判定：城市名相同，或坐标接近（约 1km）。
  bool sameAs(WeatherLocation other) {
    if (id == other.id) return true;
    if (isGps && other.isGps) {
      final dLat = (latitude! - other.latitude!).abs();
      final dLon = (longitude! - other.longitude!).abs();
      return dLat < 0.01 && dLon < 0.01;
    }
    final left = (city ?? '').trim().toLowerCase();
    final right = (other.city ?? '').trim().toLowerCase();
    return left.isNotEmpty && left == right;
  }

  WeatherLocation touch(DateTime now) => WeatherLocation(
        id: id,
        label: label,
        city: city,
        latitude: latitude,
        longitude: longitude,
        lastUsedAt: now,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  static WeatherLocation? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final label = json['label'];
    final lastUsedAt = DateTime.tryParse('${json['lastUsedAt']}');
    if (id is! String || label is! String || lastUsedAt == null) return null;
    return WeatherLocation(
      id: id,
      label: label,
      city: json['city'] is String ? json['city'] as String : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastUsedAt: lastUsedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherLocation &&
      other.id == id &&
      other.label == label &&
      other.city == city &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.lastUsedAt == lastUsedAt;

  @override
  int get hashCode =>
      Object.hash(id, label, city, latitude, longitude, lastUsedAt);
}
