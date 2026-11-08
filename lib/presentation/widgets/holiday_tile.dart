import 'package:flutter/material.dart';

import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/calendar_holiday.dart';

class HolidayTile extends StatelessWidget {
  const HolidayTile({
    super.key,
    required this.holiday,
    this.compact = false,
  });

  final CalendarHoliday holiday;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final theme = Theme.of(context);
    final accent = switch (holiday.kind) {
      HolidayKind.publicHoliday => theme.colorScheme.tertiary,
      HolidayKind.solarTerm => theme.colorScheme.primary,
      HolidayKind.traditional ||
      HolidayKind.observance =>
        theme.colorScheme.secondary,
    };

    return Container(
      key: ValueKey<String>('holiday-${holiday.id}-${holiday.date.year}'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            holiday.kind == HolidayKind.solarTerm
                ? Icons.wb_sunny_outlined
                : Icons.celebration_outlined,
            size: compact ? 18 : 20,
            color: accent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  holiday.name(chinese: locale == 'zh'),
                  style: (compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(fontWeight: FontWeight.w600, color: accent),
                ),
                if (!compact)
                  Text(
                    switch (holiday.kind) {
                      HolidayKind.publicHoliday => l10n.calendarHolidayPublic,
                      HolidayKind.solarTerm => l10n.calendarSolarTerm,
                      HolidayKind.traditional ||
                      HolidayKind.observance =>
                        l10n.calendarHolidayTraditional,
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.62),
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
