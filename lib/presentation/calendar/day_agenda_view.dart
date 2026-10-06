import 'package:flutter/material.dart';

import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/calendar_event.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/event_tile.dart';

/// 日视图（议程式）：只显示选中的那一天。
class DayAgendaView extends StatelessWidget {
  const DayAgendaView({
    super.key,
    required this.day,
    required this.events,
    required this.onSelectEvent,
    required this.onAddForDay,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onSelectEvent;
  final ValueChanged<DateTime> onAddForDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GlassCard(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      DateFormats.fullDate(day, locale),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onAddForDay(day),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.calendarNewEvent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (events.isEmpty)
                Text(
                  l10n.calendarNoEvents,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: EventTile(
                      event: event,
                      onTap: () => onSelectEvent(event),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
