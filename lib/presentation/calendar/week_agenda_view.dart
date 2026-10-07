import 'package:flutter/material.dart';

import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/services/recurrence.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/event_tile.dart';

/// 周视图（议程式）。
///
/// 以天为单位纵向排列一周的日程，窄屏（手机）也可读；
/// 真正的"时间网格"排布留到后续阶段按需再做。
class WeekAgendaView extends StatelessWidget {
  const WeekAgendaView({
    super.key,
    required this.weekStart,
    required this.events,
    required this.today,
    required this.onSelectEvent,
    required this.onAddForDay,
  });

  /// 周一。
  final DateTime weekStart;
  final List<EventOccurrence> events;
  final DateTime today;
  final ValueChanged<CalendarEvent> onSelectEvent;
  final ValueChanged<DateTime> onAddForDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < 7; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DaySection(
              day: weekStart.add(Duration(days: index)),
              today: today,
              events: events
                  .where(
                    (EventOccurrence occurrence) => DateUtils.isSameDay(
                      occurrence.start,
                      weekStart.add(Duration(days: index)),
                    ),
                  )
                  .toList(growable: false),
              onSelectEvent: onSelectEvent,
              onAddForDay: onAddForDay,
            ),
          ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.today,
    required this.events,
    required this.onSelectEvent,
    required this.onAddForDay,
  });

  final DateTime day;
  final DateTime today;
  final List<EventOccurrence> events;
  final ValueChanged<CalendarEvent> onSelectEvent;
  final ValueChanged<DateTime> onAddForDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(day, today);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                DateFormats.shortDate(day, locale),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isToday ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(width: 8),
              if (isToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.calendarToday,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => onAddForDay(day),
                icon: const Icon(Icons.add, size: 18),
                tooltip: l10n.calendarNewEvent,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (events.isEmpty)
            Text(
              l10n.calendarNoEvents,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            )
          else
            for (final occurrence in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: EventTile(
                  event: occurrence.event,
                  startTime: occurrence.start,
                  endTime: occurrence.end,
                  onTap: () => onSelectEvent(occurrence.event),
                ),
              ),
        ],
      ),
    );
  }
}
