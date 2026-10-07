import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/countdown/countdown_actions.dart';
import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/countdown_item.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';

/// 打开倒计时编辑器（新建 / 编辑 + 删除）。
Future<bool?> showCountdownEditor(
  BuildContext context, {
  CountdownItem? item,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => CountdownEditorDialog(item: item),
  );
}

class CountdownEditorDialog extends ConsumerStatefulWidget {
  const CountdownEditorDialog({super.key, this.item});

  final CountdownItem? item;

  @override
  ConsumerState<CountdownEditorDialog> createState() =>
      _CountdownEditorDialogState();
}

class _CountdownEditorDialogState extends ConsumerState<CountdownEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;

  late DateTime _target;
  late CountdownDisplayStyle _style;
  late bool _isPinned;
  int? _colorValue;
  int? _backgroundColorValue;
  String? _errorText;
  bool _busy = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _style = item?.displayStyle ?? CountdownDisplayStyle.fullText;
    _isPinned = item?.isPinned ?? false;
    _colorValue = item?.color == null ? null : _argb(item!.color!);
    _backgroundColorValue =
        item?.backgroundColor == null ? null : _argb(item!.backgroundColor!);

    final now = ref.read(clockProvider).now();
    _target = item?.targetTime ?? now.add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
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
                        _isEditing ? l10n.countdownEdit : l10n.countdownNew,
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
                          decoration: InputDecoration(
                            labelText: l10n.calendarFieldTitle,
                          ),
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.calendarFieldTitleRequired
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.countdownFieldTarget,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _pickDate,
                                icon:
                                    const Icon(Icons.event_outlined, size: 16),
                                label: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    DateFormats.fullDate(_target, locale),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _pickTime,
                              icon: const Icon(Icons.schedule, size: 16),
                              label: Text(DateFormats.time(_target, locale)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _description,
                          minLines: 2,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.calendarFieldDescription,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.countdownFieldStyle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(l10n.countdownStyleBigNumber),
                              selected:
                                  _style == CountdownDisplayStyle.bigNumber,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(
                                        () => _style =
                                            CountdownDisplayStyle.bigNumber,
                                      ),
                            ),
                            ChoiceChip(
                              label: Text(l10n.countdownStyleFullText),
                              selected:
                                  _style == CountdownDisplayStyle.fullText,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(
                                        () => _style =
                                            CountdownDisplayStyle.fullText,
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.calendarFieldColor,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(l10n.calendarColorDefault),
                              selected: _colorValue == null,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() => _colorValue = null),
                            ),
                            for (final color in EventPalette.colors)
                              _ColorDot(
                                color: color,
                                selected: _colorValue == _argb(color),
                                onTap: _busy
                                    ? null
                                    : () => setState(
                                          () => _colorValue = _argb(color),
                                        ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.countdownFieldBackground,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(l10n.calendarColorDefault),
                              selected: _backgroundColorValue == null,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(
                                        () => _backgroundColorValue = null,
                                      ),
                            ),
                            for (final color in EventPalette.colors)
                              _ColorDot(
                                color: color,
                                selected: _backgroundColorValue == _argb(color),
                                onTap: _busy
                                    ? null
                                    : () => setState(
                                          () => _backgroundColorValue =
                                              _argb(color),
                                        ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.countdownFieldPinned),
                          value: _isPinned,
                          onChanged: _busy
                              ? null
                              : (bool value) =>
                                  setState(() => _isPinned = value),
                        ),
                        if (_errorText != null) ...<Widget>[
                          const SizedBox(height: 8),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_target),
      firstDate: DateTime(2000),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _target = DateTime(
          picked.year, picked.month, picked.day, _target.hour, _target.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_target),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _target = DateTime(
        _target.year,
        _target.month,
        _target.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final existing = widget.item;
    final color = _colorValue == null ? null : Color(_colorValue!);
    final backgroundColor =
        _backgroundColorValue == null ? null : Color(_backgroundColorValue!);

    setState(() {
      _busy = true;
      _errorText = null;
    });

    try {
      final actions = ref.read(countdownActionsProvider);
      if (existing == null) {
        await actions.create(
          title: _title.text.trim(),
          targetTime: _target,
          description: _emptyToNull(_description.text),
          color: color,
          backgroundColor: backgroundColor,
          displayStyle: _style,
          isPinned: _isPinned,
        );
      } else {
        await actions.update(
          existing.copyWith(
            title: _title.text.trim(),
            targetTime: _target,
            description: _emptyToNull(_description.text),
            color: color,
            backgroundColor: backgroundColor,
            displayStyle: _style,
            isPinned: _isPinned,
          ),
        );
      }
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.countdownSaved)),
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
    final item = widget.item;
    if (item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.countdownDeleteConfirmTitle),
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
      await ref.read(countdownActionsProvider).delete(item.id);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.countdownDeleted)),
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

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
