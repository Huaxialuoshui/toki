import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/daily_digest_service.dart';
import '../../application/planning/plan_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/daily_digest.dart';
import '../../domain/entities/planning_preferences.dart';
import '../../domain/entities/task_item.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「AI 每日简报」开关和规划偏好。
class DigestSection extends ConsumerWidget {
  const DigestSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final service = ref.watch(dailyDigestServiceProvider);
    final preferences = ref.watch(planningPreferencesProvider).valueOrNull;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.digestSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const ValueKey<String>('digest-morning'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.digestMorningToggle),
            value: service.isEnabled(DailyDigestKind.morning),
            onChanged: (bool value) async {
              await service.setEnabled(DailyDigestKind.morning, value);
              ref.invalidate(todayDigestProvider);
            },
          ),
          SwitchListTile(
            key: const ValueKey<String>('digest-evening'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.digestEveningToggle),
            value: service.isEnabled(DailyDigestKind.evening),
            onChanged: (bool value) async {
              await service.setEnabled(DailyDigestKind.evening, value);
              ref.invalidate(todayDigestProvider);
            },
          ),
          const Divider(height: 24),
          Text(
            l10n.planningPreferencesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.planningPreferencesHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.64),
            ),
          ),
          if (preferences != null) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _TimeChip(
                  label: l10n.planningWorkdayStart,
                  minutes: preferences.workdayStartMinute,
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(workdayStartMinute: value),
                  ),
                ),
                _TimeChip(
                  label: l10n.planningWorkdayEnd,
                  minutes: preferences.workdayEndMinute,
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(workdayEndMinute: value),
                  ),
                ),
                _TimeChip(
                  label: l10n.planningLunchStart,
                  minutes: preferences.lunchStartMinute,
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(lunchStartMinute: value),
                  ),
                ),
                _TimeChip(
                  label: l10n.planningLunchEnd,
                  minutes: preferences.lunchEndMinute,
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(lunchEndMinute: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: <Widget>[
                _NumberDropdown(
                  label: l10n.planningFocusMinutes,
                  value: preferences.focusMinutes,
                  values: const <int>[25, 30, 45, 50, 60, 90],
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(focusMinutes: value),
                  ),
                ),
                _NumberDropdown(
                  label: l10n.planningBreakMinutes,
                  value: preferences.breakMinutes,
                  values: const <int>[5, 10, 15, 20, 30],
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(breakMinutes: value),
                  ),
                ),
                _NumberDropdown(
                  label: l10n.planningSlotMinutes,
                  value: preferences.slotMinutes,
                  values: const <int>[15, 30, 60],
                  onChanged: (int value) => _save(
                    ref,
                    preferences.copyWith(slotMinutes: value),
                  ),
                ),
                DropdownButtonFormField<TaskPriority>(
                  value: preferences.defaultPriority,
                  decoration: InputDecoration(
                    labelText: l10n.planningDefaultPriority,
                    isDense: true,
                  ),
                  items: <DropdownMenuItem<TaskPriority>>[
                    for (final priority in TaskPriority.values)
                      DropdownMenuItem<TaskPriority>(
                        value: priority,
                        child: Text(_priorityLabel(l10n, priority)),
                      ),
                  ],
                  onChanged: (TaskPriority? value) => _save(
                    ref,
                    preferences.copyWith(
                      defaultPriority: value ?? TaskPriority.normal,
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.planningWeekdaysOnly),
              value: preferences.weekdaysOnly,
              onChanged: (bool value) => _save(
                ref,
                preferences.copyWith(weekdaysOnly: value),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await ref.read(planningPreferencesRepositoryProvider).clear();
                  ref.invalidate(planningPreferencesProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(content: Text(l10n.planningResetDone)),
                  );
                },
                child: Text(l10n.planningReset),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(WidgetRef ref, PlanningPreferences preferences) async {
    await ref.read(planningPreferencesRepositoryProvider).save(preferences);
    ref.invalidate(planningPreferencesProvider);
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
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$label ${_clock(minutes)}'),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: minutes ~/ 60,
            minute: minutes % 60,
          ),
        );
        if (picked != null) {
          onChanged(picked.hour * 60 + picked.minute);
        }
      },
    );
  }

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final effective = values.contains(value) ? value : values.first;
    return DropdownButtonFormField<int>(
      value: effective,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: <DropdownMenuItem<int>>[
        for (final item in values)
          DropdownMenuItem<int>(value: item, child: Text('$item')),
      ],
      onChanged: (int? next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
