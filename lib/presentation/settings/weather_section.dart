import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/weather/weather_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「天气」区块：只填一个城市名，免密钥。
class WeatherSection extends ConsumerStatefulWidget {
  const WeatherSection({super.key});

  @override
  ConsumerState<WeatherSection> createState() => _WeatherSectionState();
}

class _WeatherSectionState extends ConsumerState<WeatherSection> {
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(
      text: ref.read(appSettingsStoreProvider).readWeatherCity() ?? '',
    );
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _save({bool clear = false}) async {
    final l10n = context.l10n;
    final store = ref.read(appSettingsStoreProvider);
    await store.writeWeatherCity(clear ? null : _city.text);
    if (clear) _city.clear();
    // 城市变了：清掉缓存并重新取一次。
    await store.writeWeatherCache(null);
    ref.invalidate(weatherProvider);
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(l10n.weatherCitySaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey<String>('weather-city'),
            controller: _city,
            decoration: InputDecoration(
              labelText: l10n.weatherCity,
              hintText: l10n.weatherCityHint,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                key: const ValueKey<String>('weather-save'),
                onPressed: () => _save(),
                child: Text(l10n.weatherSave),
              ),
              OutlinedButton(
                key: const ValueKey<String>('weather-clear'),
                onPressed: () => _save(clear: true),
                child: Text(l10n.weatherClearCity),
              ),
            ],
          ),
          if (snapshot != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '${snapshot.temperature.round()}°C · ${snapshot.city}',
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
