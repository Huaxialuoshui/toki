import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar/holiday_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/calendar_holiday.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';

class HolidaySection extends ConsumerWidget {
  const HolidaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final preferences = ref.watch(holidayPreferencesProvider);
    final controller = ref.read(holidayPreferencesProvider.notifier);
    final now = ref.watch(clockProvider).now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = ref
        .watch(holidayServiceProvider)
        .occurrencesInRange(today, today.add(const Duration(days: 400)));
    final next = upcoming.isEmpty ? null : upcoming.first;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.calendarHolidayHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          if (next != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    next.kind == HolidayKind.solarTerm
                        ? Icons.wb_sunny_outlined
                        : Icons.celebration_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.calendarNextHoliday(
                        next.name(
                          chinese:
                              Localizations.localeOf(context).languageCode ==
                                  'zh',
                        ),
                        DateFormats.shortDate(
                          next.date,
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey<String>('holiday-show-in-calendar'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarHolidayShow),
            value: preferences.showInCalendar,
            onChanged: controller.setShowInCalendar,
          ),
          SwitchListTile(
            key: const ValueKey<String>('holiday-reminders-enabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.calendarHolidayReminder),
            subtitle: Text(l10n.calendarHolidayReminderHint),
            value: preferences.remindersEnabled,
            onChanged: controller.setRemindersEnabled,
          ),
          if (preferences.remindersEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: DropdownButtonFormField<int>(
                key: const ValueKey<String>('holiday-reminder-days'),
                value: preferences.reminderDaysAhead,
                decoration: InputDecoration(
                  labelText: l10n.calendarHolidayReminderLead,
                  border: const OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<int>>[
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text(l10n.calendarHolidaySameDay),
                  ),
                  for (final days in <int>[1, 2, 3, 7])
                    DropdownMenuItem<int>(
                      value: days,
                      child: Text(l10n.calendarHolidayDaysAhead(days)),
                    ),
                ],
                onChanged: (int? value) {
                  if (value != null) controller.setReminderDaysAhead(value);
                },
              ),
            ),
        ],
      ),
    );
  }
}
