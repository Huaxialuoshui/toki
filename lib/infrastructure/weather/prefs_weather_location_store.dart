import 'dart:convert';

import '../../domain/entities/weather.dart';
import '../../domain/services/weather_service.dart';
import '../storage/app_settings_store.dart';

/// 用 shared_preferences 保存天气历史位置。
class PrefsWeatherLocationStore implements WeatherLocationStore {
  PrefsWeatherLocationStore(this._settings);

  final AppSettingsStore _settings;

  @override
  List<WeatherLocation> load() {
    final raw = _settings.readWeatherLocations();
    final locations = <WeatherLocation>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final parsed =
                WeatherLocation.fromJson(item.cast<String, Object?>());
            if (parsed != null) locations.add(parsed);
          }
        }
      } on FormatException {
        // 存坏了就当没有，不阻塞天气功能。
      }
    }
    locations.sort(
      (WeatherLocation a, WeatherLocation b) =>
          b.lastUsedAt.compareTo(a.lastUsedAt),
    );
    return locations;
  }

  @override
  Future<List<WeatherLocation>> remember(WeatherLocation location) async {
    final current = load();
    final merged = <WeatherLocation>[
      location,
      ...current.where((WeatherLocation item) => !item.sameAs(location)),
    ];
    final trimmed = merged.take(maxWeatherLocations).toList(growable: false);
    await _save(trimmed);
    return trimmed;
  }

  @override
  Future<List<WeatherLocation>> forget(String id) async {
    final remaining = load()
        .where((WeatherLocation item) => item.id != id)
        .toList(growable: false);
    await _save(remaining);
    return remaining;
  }

  Future<void> _save(List<WeatherLocation> locations) =>
      _settings.writeWeatherLocations(
        jsonEncode(
          locations.map((WeatherLocation item) => item.toJson()).toList(),
        ),
      );
}
