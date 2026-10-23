import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/ai/chat_controller.dart';
import '../../application/weather/weather_providers.dart';
import '../../application/calendar/calendar_providers.dart';
import '../../application/countdown/countdown_providers.dart';
import '../../application/settings/settings_controller.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/services/recurrence.dart';
import '../../domain/entities/weather.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/async_hint.dart';
import '../widgets/countdown_card.dart';
import 'daily_review_card.dart';
import 'task_summary_card.dart';
import 'today_plan_card.dart';
import 'weather_detail_sheet.dart';
import '../widgets/event_tile.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/persona_avatar.dart';
import '../widgets/section_header.dart';

/// 首页：日期 / 天气占位、今日事项、倒计时、AI 快捷入口、未来事件。
///
/// 数据来自本地数据库（Drift）；数据库为空时展示空状态。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final now = ref.watch(clockProvider).now();
    final today = DateUtils.dateOnly(now);

    final todayAsync = ref.watch(eventsForDayProvider(today));
    final upcomingAsync = ref.watch(upcomingEventsProvider);
    final countdownsAsync = ref.watch(pinnedCountdownsProvider);
    final showPhaseBanner = ref.watch(firstLaunchProvider);

    final todayEvents = todayAsync.valueOrNull ?? const <EventOccurrence>[];
    final upcoming = upcomingAsync.valueOrNull ?? const <EventOccurrence>[];
    final pinned = countdownsAsync.valueOrNull ?? const <CountdownItem>[];
    final persona = ref.watch(activePersonaProvider) ??
        buildFallbackPersona(now: now, l10n: l10n);

    return PageScaffold(
      title: DateFormats.fullDate(now, locale),
      subtitle: l10n.homeGreeting,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showPhaseBanner)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PhaseBanner(
                onDismiss: () =>
                    ref.read(firstLaunchProvider.notifier).dismiss(),
              ),
            ),
          const _WeatherCard(),
          const TaskSummaryCard(),
          const TodayPlanCard(),
          const DailyReviewCard(),
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.homeTodayEvents,
            icon: Icons.today_outlined,
          ),
          if (todayAsync.isLoading && todayEvents.isEmpty)
            const LoadingHint()
          else if (todayEvents.isEmpty)
            EmptyHint(text: l10n.homeNoEvents)
          else
            for (final occurrence in todayEvents)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EventTile(
                  event: occurrence.event,
                  startTime: occurrence.start,
                  endTime: occurrence.end,
                  onTap: () => context.go('/calendar'),
                ),
              ),
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.homeCountdowns,
            icon: Icons.timelapse_outlined,
            trailing: TextButton(
              onPressed: () => context.go('/countdown'),
              child: Text(l10n.commonViewAll),
            ),
          ),
          if (countdownsAsync.isLoading && pinned.isEmpty)
            const LoadingHint()
          else if (pinned.isEmpty)
            EmptyHint(
              text: l10n.countdownEmpty,
              icon: Icons.timelapse_outlined,
            )
          else
            _CountdownStrip(countdowns: pinned),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.homeUpcoming, icon: Icons.event_outlined),
          if (upcomingAsync.isLoading && upcoming.isEmpty)
            const LoadingHint()
          else if (upcoming.isEmpty)
            EmptyHint(text: l10n.homeNoEvents)
          else
            for (final occurrence in upcoming)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EventTile(
                  event: occurrence.event,
                  startTime: occurrence.start,
                  endTime: occurrence.end,
                  showDate: true,
                  onTap: () => context.go('/calendar'),
                ),
              ),
          const SizedBox(height: 24),
          _AiShortcut(persona: persona),
        ],
      ),
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.construction_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.homePhaseBannerTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homePhaseBannerBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: Text(l10n.homePhaseBannerDismiss),
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return const _WeatherCardBody();
  }
}

/// 天气卡片：设置里填了城市才显示真实天气，否则保留占位说明。
class _WeatherCardBody extends ConsumerWidget {
  const _WeatherCardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final weather = ref.watch(weatherProvider).valueOrNull;

    return GlassCard(
      // 有天气时点开逐小时 / 多日预报；没配置位置时直接去设置。
      onTap: weather == null
          ? () => context.go('/settings')
          : () => showWeatherDetail(context),
      child: Row(
        children: <Widget>[
          Icon(
            weather == null
                ? Icons.wb_cloudy_outlined
                : _conditionIcon(weather.condition),
            size: 30,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  weather == null
                      ? l10n.homeWeatherPlaceholder
                      : '${weather.temperature.round()}°C · '
                          '${_conditionLabel(l10n, weather.condition)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weather == null
                      ? l10n.homeWeatherHint
                      : '${l10n.homeWeatherDetail(
                          weather.city,
                          weather.tempMin?.round().toString() ?? '—',
                          weather.tempMax?.round().toString() ?? '—',
                        )} · ${l10n.homeWeatherUpdated(
                          _shortClock(weather.fetchedAt),
                        )}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _conditionIcon(WeatherCondition condition) {
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

  static String _shortClock(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}';
  }

  static String _conditionLabel(
    AppLocalizations l10n,
    WeatherCondition condition,
  ) {
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

class _CountdownStrip extends StatelessWidget {
  const _CountdownStrip({required this.countdowns});

  final List<CountdownItem> countdowns;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: countdowns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 248,
          child: CountdownCard(item: countdowns[index], compact: true),
        ),
      ),
    );
  }
}

class _AiShortcut extends StatelessWidget {
  const _AiShortcut({required this.persona});

  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return GlassCard(
      onTap: () => context.go('/ai'),
      child: Row(
        children: <Widget>[
          PersonaAvatar(persona: persona, radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.homeAskAi(persona.name),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeAskAiHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => context.go('/ai'),
            child: Text(l10n.homeOpenAi),
          ),
        ],
      ),
    );
  }
}
