import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar/calendar_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/async_hint.dart';
import '../widgets/event_tile.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';
import 'day_agenda_view.dart';
import 'event_editor_dialog.dart';
import 'week_agenda_view.dart';

enum CalendarViewMode { month, week, day }

/// 日历页：月 / 周 / 日视图 + 日程增删改。
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  CalendarViewMode _mode = CalendarViewMode.month;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider).now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateUtils.dateOnly(now);
  }

  DateTime get _weekStart {
    final monday = _selectedDay
        .subtract(Duration(days: _selectedDay.weekday - DateTime.monday));
    return DateUtils.dateOnly(monday);
  }

  DateTimeRange get _range {
    switch (_mode) {
      case CalendarViewMode.month:
        return DateTimeRange(
          start: DateTime(_visibleMonth.year, _visibleMonth.month),
          end: DateTime(_visibleMonth.year, _visibleMonth.month + 1),
        );
      case CalendarViewMode.week:
        return DateTimeRange(
          start: _weekStart,
          end: _weekStart.add(const Duration(days: 7)),
        );
      case CalendarViewMode.day:
        final day = DateUtils.dateOnly(_selectedDay);
        return DateTimeRange(start: day, end: day.add(const Duration(days: 1)));
    }
  }

  void _shift(int delta) {
    setState(() {
      switch (_mode) {
        case CalendarViewMode.month:
          _visibleMonth =
              DateTime(_visibleMonth.year, _visibleMonth.month + delta);
          break;
        case CalendarViewMode.week:
          _selectedDay = _selectedDay.add(Duration(days: 7 * delta));
          _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);
          break;
        case CalendarViewMode.day:
          _selectedDay = _selectedDay.add(Duration(days: delta));
          _visibleMonth = DateTime(_selectedDay.year, _selectedDay.month);
          break;
      }
    });
  }

  void _goToToday() {
    final now = ref.read(clockProvider).now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDay = DateUtils.dateOnly(now);
    });
  }

  String _subtitle(String locale) {
    switch (_mode) {
      case CalendarViewMode.month:
        return DateFormats.monthTitle(_visibleMonth, locale);
      case CalendarViewMode.week:
        return '${DateFormats.shortDate(_weekStart, locale)} – '
            '${DateFormats.shortDate(_weekStart.add(const Duration(days: 6)), locale)}';
      case CalendarViewMode.day:
        return DateFormats.fullDate(_selectedDay, locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final now = ref.watch(clockProvider).now();

    final eventsAsync = ref.watch(eventsForRangeProvider(_range));
    final events = eventsAsync.valueOrNull ?? const <EventOccurrence>[];
    final dayEvents = events
        .where(
          (EventOccurrence occurrence) =>
              DateUtils.isSameDay(occurrence.start, _selectedDay),
        )
        .toList(growable: false);

    return PageScaffold(
      title: l10n.navCalendar,
      subtitle: _subtitle(locale),
      actions: <Widget>[
        IconButton(
          onPressed: () => _shift(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.calendarMonthView,
        ),
        IconButton(
          onPressed: () => _shift(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.calendarMonthView,
        ),
        TextButton(onPressed: _goToToday, child: Text(l10n.calendarToday)),
        const SizedBox(width: 4),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _modeChip(CalendarViewMode.month, l10n.calendarMonthView),
                    _modeChip(CalendarViewMode.week, l10n.calendarWeekView),
                    _modeChip(CalendarViewMode.day, l10n.calendarDayView),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openEditor(day: _selectedDay),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.calendarNewEvent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_mode == CalendarViewMode.month) ...<Widget>[
            _MonthGrid(
              month: _visibleMonth,
              selectedDay: _selectedDay,
              today: now,
              events: events,
              onSelectDay: (DateTime day) => setState(() => _selectedDay = day),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: l10n.calendarEventsOn(
                DateFormats.fullDate(_selectedDay, locale),
              ),
              icon: Icons.event_note_outlined,
              trailing: TextButton.icon(
                onPressed: () => _openEditor(day: _selectedDay),
                icon: const Icon(Icons.add, size: 16),
                label: Text(l10n.calendarNewEvent),
              ),
            ),
            if (eventsAsync.isLoading && events.isEmpty)
              const LoadingHint()
            else if (dayEvents.isEmpty)
              EmptyHint(
                text: l10n.calendarNoEvents,
                icon: Icons.event_busy_outlined,
              )
            else
              for (final occurrence in dayEvents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EventTile(
                    event: occurrence.event,
                    startTime: occurrence.start,
                    endTime: occurrence.end,
                    onTap: () => _openDetail(occurrence.event),
                  ),
                ),
          ] else if (_mode == CalendarViewMode.week) ...<Widget>[
            SectionHeader(
              title: l10n.calendarEventsThisWeek,
              icon: Icons.view_week_outlined,
            ),
            if (eventsAsync.isLoading && events.isEmpty)
              const LoadingHint()
            else if (events.isEmpty)
              EmptyHint(
                text: l10n.calendarNoEventsThisWeek,
                icon: Icons.event_busy_outlined,
              )
            else
              WeekAgendaView(
                weekStart: _weekStart,
                events: events,
                today: now,
                onSelectEvent: _openDetail,
                onAddForDay: (DateTime day) => _openEditor(day: day),
              ),
          ] else ...<Widget>[
            if (eventsAsync.isLoading && events.isEmpty)
              const LoadingHint()
            else
              DayAgendaView(
                day: _selectedDay,
                events: dayEvents,
                onSelectEvent: _openDetail,
                onAddForDay: (DateTime day) => _openEditor(day: day),
              ),
          ],
        ],
      ),
    );
  }

  Widget _modeChip(CalendarViewMode mode, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _mode == mode,
      onSelected: (_) => setState(() => _mode = mode),
    );
  }

  Future<void> _openDetail(CalendarEvent event) async {
    final edit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => _EventDetailDialog(event: event),
    );
    if (edit == true && mounted) {
      await _openEditor(event: event);
    }
  }

  Future<void> _openEditor({CalendarEvent? event, DateTime? day}) async {
    await showEventEditor(
      context,
      event: event,
      initialDate: day ?? _selectedDay,
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
  final List<EventOccurrence> events;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final firstDay = DateTime(month.year, month.month);
    final leading = (firstDay.weekday - DateTime.monday) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((leading + daysInMonth) / 7).ceil() * 7;

    // 宽屏下限制月历宽度：否则 7 列正方形格子会撑成巨大的方块。
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassCard(
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
                  final isToday = DateUtils.isSameDay(date, today);
                  final colors = <Color>[
                    for (final occurrence in events)
                      if (DateUtils.isSameDay(occurrence.start, date))
                        occurrence.event.color ?? theme.colorScheme.primary,
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
        ),
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
    final foreground =
        isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Material(
      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
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
                  fontWeight:
                      isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
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

/// 只读详情；点"编辑"返回 true，由调用方打开编辑器。
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
              if (event.description != null)
                _DetailRow(
                  icon: Icons.notes_outlined,
                  value: event.description!,
                ),
              _DetailRow(
                icon: Icons.notifications_none,
                label: l10n.calendarReminder,
                value: l10n.reminderLabel(event.reminderMinutes),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.calendarClose),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.calendarEdit),
                  ),
                ],
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
