import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/ai/chat_controller.dart';
import '../../application/calendar/calendar_providers.dart';
import '../../application/countdown/countdown_providers.dart';
import '../../application/settings/settings_controller.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/async_hint.dart';
import '../widgets/countdown_card.dart';
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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return GlassCard(
      child: Row(
        children: <Widget>[
          Icon(
            Icons.wb_cloudy_outlined,
            size: 30,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.homeWeatherPlaceholder,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeWeatherHint,
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
