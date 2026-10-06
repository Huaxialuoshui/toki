import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/countdown/countdown_controller.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/calendar_event.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/event_tile.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';

/// 日历页：月视图 + 当日日程列表。
///
/// 第一版按规格只做月视图（周 / 日视图在 Phase 3），点击日期切换列表，点击事件
/// 打开只读详情；创建 / 编辑 / 删除同样属于 Phase 3。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider).now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToToday() {
    final now = ref.read(clockProvider).now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final now = ref.watch(clockProvider).now();
    final events = buildMockEvents(now: now, l10n: l10n);
    final dayEvents = events.where((event) => event.occursOn(_selectedDay)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return PageScaffold(
      title: l10n.navCalendar,
      subtitle: DateFormats.monthTitle(_visibleMonth, locale),
      actions: <Widget>[
        IconButton(
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: DateFormats.monthTitle(
            DateTime(_visibleMonth.year, _visibleMonth.month - 1),
            locale,
          ),
        ),
        IconButton(
          onPressed: () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: DateFormats.monthTitle(
            DateTime(_visibleMonth.year, _visibleMonth.month + 1),
            locale,
          ),
        ),
        const SizedBox(width: 4),
        TextButton(onPressed: _goToToday, child: Text(l10n.calendarToday)),
        const SizedBox(width: 4),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _ViewSwitcher(),
          const SizedBox(height: 16),
          _MonthGrid(
            month: _visibleMonth,
            selectedDay: _selectedDay,
            today: now,
            events: events,
            onSelectDay: (day) => setState(() => _selectedDay = day),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: l10n.calendarEventsOn(
              DateFormats.fullDate(_selectedDay, locale),
            ),
            icon: Icons.event_note_outlined,
          ),
          if (dayEvents.isEmpty)
            _CalendarEmptyHint(text: l10n.calendarNoEvents)
          else
            for (final event in dayEvents)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EventTile(
                  event: event,
                  onTap: () => _showEventDetail(context, event),
                ),
              ),
          const SizedBox(height: 16),
          Text(
            l10n.calendarReadOnlyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  void _showEventDetail(BuildContext context, CalendarEvent event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EventDetailDialog(event: event),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ChoiceChip(
          label: Text(l10n.calendarMonthView),
          selected: true,
          onSelected: (_) {},
        ),
        ChoiceChip(
          label: Text(l10n.calendarWeekView),
          selected: false,
          onSelected: null,
        ),
        ChoiceChip(
          label: Text(l10n.calendarDayView),
          selected: false,
          onSelected: null,
        ),
        Text(
          l10n.calendarWeekDayComingSoon,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.events,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final DateTime today;
  final List<CalendarEvent> events;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final firstDay = DateTime(month.year, month.month);
    final leading = (firstDay.weekday - DateTime.monday) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((leading + daysInMonth) / 7).ceil() * 7;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final label in DateFormats.weekdayHeaders(locale))
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(month.year, month.month, dayNumber);
              final isSelected = date == selectedDay;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final colors = <Color>[
                for (final event in events)
                  if (event.occursOn(date))
                    event.color ?? theme.colorScheme.primary,
              ];

              return _DayCell(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                eventColors: colors,
                onTap: () => onSelectDay(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.eventColors,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final List<Color> eventColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(12);
    final foreground = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Material(
      color: isSelected
          ? theme.colorScheme.primary
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: isToday && !isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 1.4)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${date.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (final color in eventColors.take(3))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? foreground : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarEmptyHint extends StatelessWidget {
  const _CalendarEmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Row(
        children: <Widget>[
          Icon(
            Icons.event_busy_outlined,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailDialog extends StatelessWidget {
  const _EventDetailDialog({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final theme = Theme.of(context);
    final accent = event.color ?? theme.colorScheme.primary;
    final timeText = event.allDay
        ? l10n.calendarAllDay
        : '${DateFormats.time(event.startTime, locale)} – '
            '${DateFormats.time(event.endTime, locale)}';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.calendarEventDetail,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DetailRow(
                icon: Icons.schedule,
                value:
                    '${DateFormats.fullDate(event.startTime, locale)} · $timeText',
              ),
              if (event.location != null)
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: l10n.calendarLocation,
                  value: event.location!,
                ),
              _DetailRow(
                icon: Icons.notifications_none,
                label: l10n.calendarReminder,
                value: event.reminderMinutes == null
                    ? l10n.calendarNoReminder
                    : l10n.calendarReminderMinutes(event.reminderMinutes!),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.calendarClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value, this.label});

  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label == null ? value : '$label: $value',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
