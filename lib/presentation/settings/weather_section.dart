import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/weather/weather_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/weather.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「天气」区块。
///
/// * 免密钥（Open-Meteo）；
/// * 可以按城市添加，也可以直接用 GPS 定位；
/// * 历史位置会记住（最近使用在前，最多 8 个）。
class WeatherSection extends ConsumerStatefulWidget {
  const WeatherSection({super.key});

  @override
  ConsumerState<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends ConsumerState<WeatherSection> {
  final TextEditingController _city = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _addCity() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final name = _city.text.trim();
    if (name.isEmpty) return;
    final controller = ref.read(weatherLocationsProvider.notifier);
    await controller.rememberCity(name);
    _city.clear();
    ref.invalidate(weatherProvider);
    if (!mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.weatherCitySaved)),
    );
  }

  Future<void> _useCurrentLocation() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      await ref.read(weatherLocationsProvider.notifier).useCurrentLocation();
      ref.invalidate(weatherProvider);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.weatherLocationUsed)),
      );
    } on WeatherLocationException catch (error) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
            content: Text('${l10n.weatherLocationFailed}：${error.message}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(WeatherLocation location) async {
    await ref.read(weatherLocationsProvider.notifier).forget(location.id);
    ref.invalidate(weatherProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locations = ref.watch(weatherLocationsProvider);
    final active = ref.watch(activeWeatherLocationProvider);
    final snapshot = ref.watch(weatherProvider).valueOrNull;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.weatherSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 10),

          // 历史位置：点一下切换，X 删除。
          if (locations.isEmpty)
            Text(
              l10n.weatherNoLocations,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          else
            for (final location in locations)
              ListTile(
                key: ValueKey<String>('weather-location-${location.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  location.isGps ? Icons.my_location : Icons.location_city,
                  size: 18,
                  color: location.id == active?.id
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                title: Text(
                  location.isGps &&
                          snapshot != null &&
                          location.id == active?.id
                      ? '${location.label} · ${snapshot.temperature.round()}°C'
                      : location.label,
                  style: TextStyle(
                    fontWeight: location.id == active?.id
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: IconButton(
                  key: ValueKey<String>('weather-remove-${location.id}'),
                  tooltip: l10n.calendarDelete,
                  onPressed: () => _remove(location),
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                ),
                onTap: () async {
                  // 重新置顶 = 切换到它。
                  await ref
                      .read(weatherLocationsProvider.notifier)
                      .remember(location.touch(DateTime.now()));
                  ref.invalidate(weatherProvider);
                },
              ),

          const SizedBox(height: 8),
          TextField(
            key: const ValueKey<String>('weather-city'),
            controller: _city,
            decoration: InputDecoration(
              labelText: l10n.weatherCity,
              hintText: l10n.weatherCityHint,
            ),
            onSubmitted: (_) => _addCity(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                key: const ValueKey<String>('weather-save'),
                onPressed: _busy ? null : _addCity,
                child: Text(l10n.weatherSave),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('weather-use-gps'),
                onPressed: _busy ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: Text(l10n.weatherUseCurrentLocation),
              ),
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (snapshot != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '${snapshot.temperature.round()}°C · ${snapshot.city} · '
              '${snapshot.tempMin?.round() ?? '—'}° / ${snapshot.tempMax?.round() ?? '—'}°',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
