import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/planning/plan_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/markdown_text.dart';
import '../planning/plan_generation_dialog.dart';
import '../planning/plan_labels.dart';

class TodayPlanCard extends ConsumerWidget {
  const TodayPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dataAsync = ref.watch(todayPlanDataProvider);
    final data = dataAsync.valueOrNull;

    if (data == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: Row(
            children: <Widget>[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(l10n.planSection),
            ],
          ),
        ),
      );
    }

    final plan = data.displayPlan;
    if (plan == null) {
      final legacy = data.legacyMorningDigest;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Header(
                onGenerate: () => _generate(context, ref),
                status: null,
              ),
              if (legacy != null) ...<Widget>[
                Text(
                  l10n.planLegacyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.planLegacyHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                MarkdownText(
                  legacy.content,
                  copyLabel: l10n.aiMessageCopied,
                ),
              ] else ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  l10n.planNoPlan,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.planNoPlanHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _generate(context, ref),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(l10n.planGenerate),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress = data.progress;
    final issues = data.issues.take(2).toList(growable: false);
    final now = ref.watch(clockProvider).now();
    final next = _nextEvent(data.fixedOccurrences, now);
    final currentTask = _currentTask(data.items, data.tasksById, now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: () => context.push('/home/plan'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              status: plan.status,
              onGenerate: () => _generate(context, ref),
            ),
            if (data.hasPendingDraft) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.planPendingDraft,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.planDraftPendingHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              plan.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (progress != null) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.completionRate,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${progress.completedTasks}/${progress.taskItems}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (next != null) ...<Widget>[
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.schedule,
                text: '${DateFormats.time(next.start, context.localeCode)} '
                    '${next.event.title}',
              ),
            ],
            if (currentTask != null) ...<Widget>[
              const SizedBox(height: 6),
              _InfoLine(
                icon: Icons.play_circle_outline,
                text: currentTask.title,
              ),
            ],
            if (issues.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              for (final issue in issues)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• ${planIssueLabel(l10n, issue.code)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/home/plan'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(l10n.planViewAll),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await showPlanGenerationDialog(context);
    if (result == null || !context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.planGenerated)),
    );
    context.push('/home/plan');
  }

  static EventOccurrence? _nextEvent(
    List<EventOccurrence> occurrences,
    DateTime now,
  ) {
    for (final occurrence in occurrences) {
      if (occurrence.end.isAfter(now)) return occurrence;
    }
    return null;
  }

  static TaskItem? _currentTask(
    List<DailyPlanItem> items,
    Map<String, TaskItem> tasks,
    DateTime now,
  ) {
    for (final item in items) {
      final task = item.taskId == null ? null : tasks[item.taskId];
      if (task == null || task.isCompleted) continue;
      if (item.startAt != null &&
          item.endAt != null &&
          !item.endAt!.isBefore(now) &&
          !item.startAt!.isAfter(now)) {
        return task;
      }
    }
    for (final item in items) {
      final task = item.taskId == null ? null : tasks[item.taskId];
      if (task != null && task.isActive) return task;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onGenerate, this.status});

  final VoidCallback onGenerate;
  final PlanStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(
          Icons.auto_awesome_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.planSection,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (status != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: planStatusColor(theme, status!).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              planStatusLabel(l10n, status!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: planStatusColor(theme, status!),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          onPressed: onGenerate,
          icon: const Icon(Icons.refresh, size: 18),
          tooltip: l10n.planRegenerate,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
