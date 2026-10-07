import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/weather.dart';
import '../../domain/services/weather_service.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../../infrastructure/weather/open_meteo_weather_service.dart';
import '../settings/settings_controller.dart';
import '../ai/daily_digest_service.dart' show systemLocaleProvider;

/// 天气数据源（测试里 override 成假实现）。
final weatherServiceProvider = Provider<WeatherService>(
  (ref) => OpenMeteoWeatherService(
    languageCode: ref.watch(weatherLocaleProvider).languageCode,
  ),
);

/// 当前界面语言，用来决定城市搜索返回的语言。
final weatherLocaleProvider = Provider<Locale>((ref) {
  final selected = ref.watch(localeControllerProvider);
  if (selected != null) return selected;
  final system = ref.watch(systemLocaleProvider);
  return system.languageCode == 'en' ? const Locale('en') : const Locale('zh');
});

/// 首页用的天气：有城市才查，30 分钟内用缓存，失败回落到缓存或空。
final weatherProvider = FutureProvider<WeatherSnapshot?>((ref) async {
  final store = ref.watch(appSettingsStoreProvider);
  final city = store.readWeatherCity();
  if (city == null || city.trim().isEmpty) return null;

  final now = ref.watch(clockProvider).now();
  final cached = _readCache(store);
  if (cached != null && cached.isFresh(now)) return cached;

  try {
    final fresh = await ref.watch(weatherServiceProvider).fetch(city);
    await store.writeWeatherCache(jsonEncode(fresh.toJson()));
    return fresh;
  } on Object {
    // 网络失败不打扰用户：有旧数据就先用旧的。
    return cached;
  }
});

WeatherSnapshot? _readCache(AppSettingsStore store) {
  final raw = store.readWeatherCache();
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return WeatherSnapshot.fromJson(decoded.cast<String, Object?>());
  } on FormatException {
    return null;
  }
}
