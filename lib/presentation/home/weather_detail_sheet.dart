import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/weather/weather_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/weather.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

/// 天气详情：当前 + 未来几小时 + 未来几天。
///
/// 从首页的天气卡点进来。
Future<void> showWeatherDetail(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => const _WeatherDetail(),
    );

class _WeatherDetail extends ConsumerWidget {
  const _WeatherDetail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final snapshot = ref.watch(weatherProvider).valueOrNull;

    if (snapshot == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.weatherNoForecast),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_icon(snapshot.condition),
                    size: 34, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${snapshot.temperature.round()}°C · '
                        '${_label(l10n, snapshot.condition)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.homeWeatherDetail(
                          snapshot.city,
                          snapshot.tempMin?.round().toString() ?? '—',
                          snapshot.tempMax?.round().toString() ?? '—',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (snapshot.hourly.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                l10n.weatherHourly,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.hourly.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final hour = snapshot.hourly[index];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _clock(hour.time),
                            style: theme.textTheme.labelSmall,
                          ),
                          Icon(_icon(hour.condition), size: 20),
                          Text(
                            '${hour.temperature.round()}°',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (snapshot.daily.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                l10n.weatherDaily,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              for (final (int index, WeatherDay day) in snapshot.daily.indexed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_icon(day.condition), size: 20),
                  title: Text(
                    index == 0
                        ? l10n.weatherToday
                        : '${day.date.month}/${day.date.day}',
                  ),
                  trailing: Text(
                    '${day.tempMin?.round() ?? '—'}° / '
                    '${day.tempMax?.round() ?? '—'}°',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _clock(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}';
  }

  static IconData _icon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return Icons.wb_sunny_outlined;
      case WeatherCondition.partlyCloudy:
        return Icons.wb_cloudy_outlined;
      case WeatherCondition.cloudy:
        return Icons.cloud_outlined;
      case WeatherCondition.fog:
        return Icons.foggy;
      case WeatherCondition.drizzle:
      case WeatherCondition.rain:
        return Icons.water_drop_outlined;
      case WeatherCondition.snow:
        return Icons.ac_unit;
      case WeatherCondition.thunder:
        return Icons.thunderstorm_outlined;
      case WeatherCondition.unknown:
        return Icons.wb_cloudy_outlined;
    }
  }

  static String _label(AppLocalizations l10n, WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return l10n.weatherClear;
      case WeatherCondition.partlyCloudy:
        return l10n.weatherPartlyCloudy;
      case WeatherCondition.cloudy:
        return l10n.weatherCloudy;
      case WeatherCondition.fog:
        return l10n.weatherFog;
      case WeatherCondition.drizzle:
        return l10n.weatherDrizzle;
      case WeatherCondition.rain:
        return l10n.weatherRain;
      case WeatherCondition.snow:
        return l10n.weatherSnow;
      case WeatherCondition.thunder:
        return l10n.weatherThunder;
      case WeatherCondition.unknown:
        return l10n.weatherUnknown;
    }
  }
}
