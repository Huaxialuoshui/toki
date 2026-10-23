import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/tasks/task_actions.dart';
import '../../core/errors/task_exception.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/task_item.dart';
import '../../infrastructure/clock_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

Future<bool?> showTaskEditor(
  BuildContext context, {
  TaskItem? task,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => TaskEditorDialog(task: task),
  );
}

class TaskEditorDialog extends ConsumerStatefulWidget {
  const TaskEditorDialog({super.key, this.task});

  final TaskItem? task;

  @override
  ConsumerState<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends ConsumerState<TaskEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _estimate;
  late final TextEditingController _actual;
  late TaskPriority _priority;
  DateTime? _dueAt;
  String? _errorText;
  bool _busy = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _estimate = TextEditingController(
      text: task?.estimatedMinutes?.toString() ?? '',
    );
    _actual = TextEditingController(
      text: task?.actualMinutes?.toString() ?? '',
    );
    _priority = task?.priority ?? TaskPriority.normal;
    _dueAt = task?.dueAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _estimate.dispose();
    _actual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
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
                        _isEditing ? l10n.taskEdit : l10n.taskNew,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.taskCancel,
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
                            labelText: l10n.taskFieldTitle,
                          ),
                          validator: (String? value) =>
                              value == null || value.trim().isEmpty
                                  ? l10n.taskTitleRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: l10n.taskFieldNotes,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.taskFieldPriority,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TaskPriority>(
                          value: _priority,
                          decoration: const InputDecoration(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: <DropdownMenuItem<TaskPriority>>[
                            for (final priority in TaskPriority.values)
                              DropdownMenuItem<TaskPriority>(
                                value: priority,
                                child: Text(_priorityLabel(l10n, priority)),
                              ),
                          ],
                          onChanged: _busy
                              ? null
                              : (TaskPriority? value) => setState(
                                    () => _priority =
                                        value ?? TaskPriority.normal,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.taskFieldDue,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _pickDueDate,
                                icon:
                                    const Icon(Icons.event_outlined, size: 18),
                                label: Text(
                                  _dueAt == null
                                      ? l10n.taskNoDue
                                      : _taskDueLabel(context),
                                ),
                              ),
                            ),
                            if (_dueAt != null)
                              IconButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() => _dueAt = null),
                                icon: const Icon(Icons.clear, size: 18),
                                tooltip: l10n.taskClearDue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _estimate,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.taskFieldEstimate,
                            suffixText: l10n.taskMinutesUnit,
                          ),
                          validator: (String? value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final minutes = int.tryParse(text);
                            return minutes == null || minutes < 0
                                ? l10n.taskEstimateInvalid
                                : null;
                          },
                        ),
                        if (_isEditing) ...<Widget>[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _actual,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.taskFieldActual,
                              suffixText: l10n.taskMinutesUnit,
                            ),
                            validator: (String? value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final minutes = int.tryParse(text);
                              return minutes == null || minutes < 0
                                  ? l10n.taskEstimateInvalid
                                  : null;
                            },
                          ),
                        ],
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.taskCancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(l10n.taskSave),
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

  Future<void> _pickDueDate() async {
    final now = ref.read(clockProvider).now();
    final initial = _dueAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(initial),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final estimateText = _estimate.text.trim();
    final estimate = estimateText.isEmpty ? null : int.tryParse(estimateText);
    final actualText = _actual.text.trim();
    final actual = actualText.isEmpty ? null : int.tryParse(actualText);
    final actions = ref.read(taskActionsProvider);
    final description = _description.text.trim();

    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final existing = widget.task;
      if (existing == null) {
        await actions.create(
          title: _title.text,
          description: description,
          priority: _priority,
          dueAt: _dueAt,
          estimatedMinutes: estimate,
        );
      } else {
        await actions.update(
          existing.copyWith(
            title: _title.text,
            description: description,
            clearDescription: description.isEmpty,
            priority: _priority,
            dueAt: _dueAt,
            clearDueAt: _dueAt == null,
            estimatedMinutes: estimate,
            clearEstimatedMinutes: estimate == null,
            actualMinutes: actual,
            clearActualMinutes: actual == null,
          ),
        );
      }
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(l10n.taskSaved)));
      navigator.pop(true);
    } on TaskException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = _taskErrorText(l10n, error.code);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = '${l10n.taskSaveFailed}：$error';
      });
    }
  }

  String _taskDueLabel(BuildContext context) {
    final due = _dueAt!;
    return '${context.l10n.taskDueOn(_shortDate(context, due))} '
        '${TimeOfDay.fromDateTime(due).format(context)}';
  }

  static String _shortDate(BuildContext context, DateTime date) {
    return context.localeCode == 'zh'
        ? '${date.month}月${date.day}日'
        : '${date.month}/${date.day}';
  }

  static String _priorityLabel(
    AppLocalizations l10n,
    TaskPriority priority,
  ) =>
      switch (priority) {
        TaskPriority.low => l10n.taskPriorityLow,
        TaskPriority.normal => l10n.taskPriorityNormal,
        TaskPriority.high => l10n.taskPriorityHigh,
        TaskPriority.urgent => l10n.taskPriorityUrgent,
      };

  static String _taskErrorText(
    AppLocalizations l10n,
    TaskErrorCode code,
  ) =>
      switch (code) {
        TaskErrorCode.emptyTitle => l10n.taskTitleRequired,
        TaskErrorCode.invalidEstimatedMinutes ||
        TaskErrorCode.invalidActualMinutes =>
          l10n.taskEstimateInvalid,
        TaskErrorCode.invalidDueAt => l10n.taskSaveFailed,
        TaskErrorCode.notFound => l10n.taskMissing,
        TaskErrorCode.notActive => l10n.taskNotActive,
        TaskErrorCode.notCompleted => l10n.taskNotCompleted,
      };
}
