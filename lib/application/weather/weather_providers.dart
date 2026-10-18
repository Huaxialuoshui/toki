import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/weather.dart';
import '../../domain/services/weather_service.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/device/device_channel.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../../infrastructure/weather/open_meteo_weather_service.dart';
import '../../infrastructure/weather/prefs_weather_location_store.dart';
import '../ai/daily_digest_service.dart' show systemLocaleProvider;
import '../device/device_providers.dart';
import '../settings/settings_controller.dart';

/// 天气数据源（测试里 override 成假实现）。
final weatherServiceProvider = Provider<WeatherService>(
  (ref) => OpenMeteoWeatherService(
    languageCode: ref.watch(weatherLocaleProvider).languageCode,
    now: () => ref.read(clockProvider).now(),
  ),
);

/// 当前界面语言，用来决定城市搜索返回的语言。
final weatherLocaleProvider = Provider<Locale>((ref) {
  final selected = ref.watch(localeControllerProvider);
  if (selected != null) return selected;
  return ref.watch(systemLocaleProvider);
});

final weatherLocationStoreProvider = Provider<WeatherLocationStore>(
  (ref) => PrefsWeatherLocationStore(ref.watch(appSettingsStoreProvider)),
);

/// 定位失败时的可读错误。
class WeatherLocationException implements Exception {
  const WeatherLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 历史位置 + 当前选中的位置。
///
/// 位置列表存在 shared_preferences；第一次运行会把老版本（Phase 12）的
/// 单个城市设置迁移进来。
class WeatherLocationsController extends Notifier<List<WeatherLocation>> {
  @override
  List<WeatherLocation> build() {
    final store = ref.watch(weatherLocationStoreProvider);
    final settings = ref.watch(appSettingsStoreProvider);
    final existing = store.load();
    if (existing.isNotEmpty) return existing;

    final legacy = settings.readWeatherCity();
    if (legacy == null || legacy.trim().isEmpty) {
      return const <WeatherLocation>[];
    }
    final name = legacy.trim();
    return <WeatherLocation>[
      WeatherLocation(
        id: 'city-$name',
        label: name,
        city: name,
        lastUsedAt: ref.read(clockProvider).now(),
      ),
    ];
  }

  Future<void> remember(WeatherLocation location) async {
    state = await ref.read(weatherLocationStoreProvider).remember(location);
  }

  Future<void> forget(String id) async {
    state = await ref.read(weatherLocationStoreProvider).forget(id);
  }

  /// 记住一个城市（重复的会去重并置顶，最多保留 8 个）。
  Future<WeatherLocation> rememberCity(String city) async {
    final name = city.trim();
    final location = WeatherLocation(
      id: 'city-$name',
      label: name,
      city: name,
      lastUsedAt: ref.read(clockProvider).now(),
    );
    await remember(location);
    return location;
  }

  /// 申请权限并取一次 GPS 位置；失败时抛出可读错误。
  Future<WeatherLocation> useCurrentLocation() async {
    final DeviceChannel channel = ref.read(deviceChannelProvider);
    if (!channel.isSupported) {
      throw const WeatherLocationException('当前平台不支持定位');
    }
    // 原生侧的定位请求可能因为"没信号""定位开关没开"而一直不回调，
    // 所以这里再加一道客户端超时，避免按钮一直转圈。
    final GeoPoint? point;
    try {
      var granted = await channel.hasLocationPermission();
      if (!granted) {
        granted = await channel.requestLocationPermission();
      }
      if (!granted) {
        throw const WeatherLocationException('没有拿到定位权限');
      }
      point = await channel.getLocation().timeout(kLocationTimeout);
    } on WeatherLocationException {
      rethrow;
    } on TimeoutException {
      throw const WeatherLocationException('定位超时，请确认系统定位已打开');
    } on GeoLocationException catch (error) {
      throw WeatherLocationException(error.message);
    } on PlatformException catch (error) {
      throw WeatherLocationException(error.message ?? '定位失败');
    } on MissingPluginException {
      throw const WeatherLocationException('当前平台不支持定位');
    }
    if (point == null) {
      throw const WeatherLocationException('拿不到当前位置（系统定位可能没开）');
    }
    final location = WeatherLocation(
      id: 'gps-current',
      label: '当前位置',
      latitude: point.latitude,
      longitude: point.longitude,
      lastUsedAt: ref.read(clockProvider).now(),
    );
    await remember(location);
    return location;
  }
}

/// 等待一次定位回调的上限（原生侧也有同样的超时兜底）。
const Duration kLocationTimeout = Duration(seconds: 25);

final weatherLocationsProvider =
    NotifierProvider<WeatherLocationsController, List<WeatherLocation>>(
  WeatherLocationsController.new,
);

/// 当前用来取天气的位置（列表里最近使用的那个）。
final activeWeatherLocationProvider = Provider<WeatherLocation?>((ref) {
  final locations = ref.watch(weatherLocationsProvider);
  return locations.isEmpty ? null : locations.first;
});

/// 首页用的天气：有位置才查，30 分钟内用缓存，失败回落到缓存或空。
final weatherProvider = FutureProvider<WeatherSnapshot?>((ref) async {
  final store = ref.watch(appSettingsStoreProvider);
  final location = ref.watch(activeWeatherLocationProvider);
  if (location == null) return null;

  final now = ref.watch(clockProvider).now();
  final cached = _readCache(store, location);
  if (cached != null && cached.isFresh(now, ttl: kWeatherCacheTtl)) {
    return cached;
  }

  try {
    final service = ref.watch(weatherServiceProvider);
    final fresh = location.isGps
        ? await service.fetchByCoordinates(
            latitude: location.latitude!,
            longitude: location.longitude!,
            label: location.label,
          )
        : await service.fetch(location.city ?? location.label);
    await store.writeWeatherCache(
      jsonEncode(<String, Object?>{
        'locationId': location.id,
        'snapshot': fresh.toJson(),
      }),
    );
    return fresh;
  } on Object catch (error) {
    // 网络失败不打扰用户：有旧数据就先用旧的。
    debugPrint('获取天气失败（${location.label}）：$error');
    return cached;
  }
});

/// 天气自动刷新：应用在前台时定时重查；从后台回来时也补一次。
///
/// Open-Meteo 的 `current` 本身会随时间变化，所以这里不再把缓存当成
/// "固定温度"长期显示。缓存 TTL 比刷新间隔略短，保证每次节拍都会真正
/// 发一次请求（网络失败时仍回落到上一份快照）。
const Duration kWeatherRefreshInterval = Duration(minutes: 10);
const Duration kWeatherCacheTtl = Duration(minutes: 8);

final weatherAutoRefreshProvider = Provider<void>((ref) {
  final Timer timer = Timer.periodic(
    kWeatherRefreshInterval,
    (_) => ref.invalidate(weatherProvider),
  );
  final AppLifecycleListener lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(weatherProvider),
  );
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
  });
});

/// 读取缓存；只有"和当前位置同一条"的缓存才算数。
WeatherSnapshot? _readCache(AppSettingsStore store, WeatherLocation location) {
  final raw = store.readWeatherCache();
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final map = decoded.cast<String, Object?>();
    if (map.containsKey('locationId')) {
      if (map['locationId'] != location.id) return null;
      final snapshot = map['snapshot'];
      if (snapshot is! Map) return null;
      return WeatherSnapshot.fromJson(snapshot.cast<String, Object?>());
    }
    // 兼容旧版本直接存快照的格式。
    final legacy = WeatherSnapshot.fromJson(map);
    if (legacy == null) return null;
    return legacy.city == (location.city ?? location.label) ? legacy : null;
  } on FormatException {
    return null;
  }
}
