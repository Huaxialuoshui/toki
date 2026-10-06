import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar/calendar_actions.dart';
import '../../application/calendar/calendar_providers.dart';
import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/calendar_category.dart';
import '../../domain/entities/calendar_event.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';

/// 打开日程编辑器。
///
/// * [event] 为空 → 新建（用 [initialDate] 作为默认日期）
/// * [event] 不为空 → 编辑，并可删除
///
/// 返回 true 表示数据库有变更。
Future<bool?> showEventEditor(
  BuildContext context, {
  CalendarEvent? event,
  DateTime? initialDate,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => EventEditorDialog(
      event: event,
      initialDate: initialDate,
    ),
  );
}

class EventEditorDialog extends ConsumerStatefulWidget {
  const EventEditorDialog({super.key, this.event, this.initialDate});

  final CalendarEvent? event;
  final DateTime? initialDate;

  @override
  ConsumerState<EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends ConsumerState<EventEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;

  late bool _allDay;
  late DateTime _start;
  late DateTime _end;
  String _categoryId = '';
  int? _colorValue;
  int? _reminderMinutes;
  String? _errorText;
  bool _busy = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _title = TextEditingController(text: event?.title ?? '');
    _description = TextEditingController(text: event?.description ?? '');
    _location = TextEditingController(text: event?.location ?? '');
    _allDay = event?.allDay ?? false;
    _categoryId = event?.categoryId ?? '';
    _colorValue = event?.color == null ? null : _argb(event!.color!);
    _reminderMinutes = event?.reminderMinutes;

    if (event != null) {
      _start = event.startTime;
      _end = event.endTime;
    } else {
      final day = DateUtils.dateOnly(
        widget.initialDate ?? ref.read(clockProvider).now(),
      );
      _start = day.add(const Duration(hours: 9));
      _end = day.add(const Duration(hours: 10));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  static int _argb(Color color) =>
      ((color.a * 255).round() << 24) |
      ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.localeCode;
    final theme = Theme.of(context);
    final categories = ref.watch(calendarCategoriesProvider).valueOrNull ??
        const <CalendarCategory>[];

    // 分类列表可能还在加载（首帧为空），旧事件也可能引用了一个已被删除的分类。
    // DropdownButton 要求 value 在 items 中唯一匹配，这里补一条占位项兜底。
    final categoryItems = <DropdownMenuItem<String>>[
      DropdownMenuItem<String>(
        value: '',
        child: Text(l10n.calendarCategoryNone),
      ),
      for (final category in categories)
        DropdownMenuItem<String>(
          value: category.id,
          child: Text(category.name),
        ),
    ];
    if (!categoryItems.any(
      (DropdownMenuItem<String> item) => item.value == _categoryId,
    )) {
      categoryItems.insert(
        1,
        DropdownMenuItem<String>(
          value: _categoryId,
          child: Text(_categoryId),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _isEditing
                            ? l10n.calendarEditEvent
                            : l10n.calendarNewEvent,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.calendarCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          controller: _title,
                          autofocus: !_isEditing,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.calendarFieldTitle,
                          ),
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.calendarFieldTitleRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.calendarAllDayEvent),
                          value: _allDay,
                          onChanged: _busy ? null : _setAllDay,
                        ),
                        const SizedBox(height: 4),
                        _DateTimeRow(
                          label: l10n.calendarFieldStart,
                          value: _start,
                          allDay: _allDay,
                          locale: locale,
                          onPickDate: _busy ? null : () => _pickDate(true),
                          onPickTime: _busy ? null : () => _pickTime(true),
                        ),
                        const SizedBox(height: 10),
                        _DateTimeRow(
                          label: l10n.calendarFieldEnd,
                          value: _end,
                          allDay: _allDay,
                          locale: locale,
                          onPickDate: _busy ? null : () => _pickDate(false),
                          onPickTime: _busy ? null : () => _pickTime(false),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _location,
                          decoration: InputDecoration(
                            labelText: l10n.calendarFieldLocation,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.calendarFieldDescription,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: l10n.calendarFieldCategory),
                        DropdownButtonFormField<String>(
                          value: _categoryId,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: <DropdownMenuItem<String>>[
                            ...categoryItems,
                          ],
                          onChanged: _busy
                              ? null
                              : (String? value) => setState(
                                    () => _categoryId = value ?? '',
                                  ),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: l10n.calendarFieldColor),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _ColorDot(
                              color: null,
                              selected: _colorValue == null,
                              label: l10n.calendarColorDefault,
                              onTap: _busy
                                  ? null
                                  : () => setState(() => _colorValue = null),
                            ),
                            for (final color in EventPalette.colors)
                              _ColorDot(
                                color: color,
                                selected: _colorValue == _argb(color),
                                label: '',
                                onTap: _busy
                                    ? null
                                    : () => setState(
                                          () => _colorValue = _argb(color),
                                        ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: l10n.calendarFieldReminder),
                        DropdownButtonFormField<int>(
                          value: _reminderMinutes,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: <DropdownMenuItem<int>>[
                            DropdownMenuItem<int>(
                              child: Text(l10n.reminderLabel(null)),
                            ),
                            for (final minutes in ReminderPresets.minutes)
                              DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(l10n.reminderLabel(minutes)),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (int? value) =>
                                  setState(() => _reminderMinutes = value),
                        ),
                        if (_errorText != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: _busy ? null : _confirmDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(l10n.calendarDelete),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.calendarCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(l10n.calendarSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setAllDay(bool value) {
    setState(() {
      _allDay = value;
      final startDay = DateUtils.dateOnly(_start);
      if (value) {
        _start = startDay;
        final endDay = DateUtils.dateOnly(_end);
        _end = endDay.isAfter(startDay)
            ? endDay
            : startDay.add(const Duration(days: 1));
      } else {
        _start = startDay.add(const Duration(hours: 9));
        _end = _start.add(const Duration(hours: 1));
      }
      _errorText = null;
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final current = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(current),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        final delta = _end.difference(_start);
        _start = _allDay
            ? DateUtils.dateOnly(picked)
            : DateTime(picked.year, picked.month, picked.day, _start.hour,
                _start.minute);
        _end = _start.add(delta.isNegative ? const Duration(hours: 1) : delta);
      } else {
        _end = _allDay
            ? DateUtils.dateOnly(picked)
            : DateTime(
                picked.year, picked.month, picked.day, _end.hour, _end.minute);
      }
      _errorText = null;
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final updated = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        final duration = _end.difference(_start);
        _start = updated;
        _end = _start
            .add(duration.isNegative ? const Duration(hours: 1) : duration);
      } else {
        _end = updated;
      }
      _errorText = null;
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final l10n = context.l10n;
    if (!_end.isAfter(_start)) {
      setState(() => _errorText = l10n.calendarEndBeforeStart);
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final now = ref.read(clockProvider).now();
    final existing = widget.event;

    final event = CalendarEvent(
      id: existing?.id ?? generateId('event', now: now),
      title: _title.text.trim(),
      description: _emptyToNull(_description.text),
      startTime: _start,
      endTime: _end,
      allDay: _allDay,
      location: _emptyToNull(_location.text),
      categoryId: _categoryId.isEmpty ? null : _categoryId,
      color: _colorValue == null ? null : Color(_colorValue!),
      repeatRule: existing?.repeatRule,
      reminderMinutes: _reminderMinutes,
      status: existing?.status ?? EventStatus.scheduled,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    setState(() {
      _busy = true;
      _errorText = null;
    });

    try {
      await ref.read(calendarActionsProvider).saveEvent(event);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.calendarEventSaved)),
      );
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = '$error';
      });
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final event = widget.event;
    if (event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.calendarDeleteConfirmTitle),
        content: Text(l10n.calendarDeleteConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.calendarDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(calendarActionsProvider).deleteEvent(event.id);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.calendarEventDeleted)),
      );
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = '$error';
      });
    }
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.allDay,
    required this.locale,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String label;
  final DateTime value;
  final bool allDay;
  final String locale;
  final VoidCallback? onPickDate;
  final VoidCallback? onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.event_outlined, size: 16),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(DateFormats.shortDate(value, locale)),
            ),
          ),
        ),
        if (!allDay) ...<Widget>[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onPickTime,
            icon: const Icon(Icons.schedule, size: 16),
            label: Text(DateFormats.time(value, locale)),
          ),
        ],
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (color == null) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap!(),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.18),
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
            : null,
      ),
    );
  }
}
