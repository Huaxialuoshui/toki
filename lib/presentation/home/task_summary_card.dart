import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/tasks/task_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/task_item.dart';
import '../../shared/widgets/glass_card.dart';
import '../tasks/task_editor_dialog.dart';

class TaskSummaryCard extends ConsumerWidget {
  const TaskSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = ref.watch(taskSummaryProvider);
    final tasks =
        ref.watch(activeTasksProvider).valueOrNull ?? const <TaskItem>[];
    final first = tasks.isEmpty ? null : tasks.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: () => context.push('/home/tasks'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.task_alt_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.taskSection,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => showTaskEditor(context),
                  child: Text(l10n.taskNew),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.taskSummaryCounts(
                summary.active,
                summary.completed,
                summary.overdue,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (summary.total > 0) ...<Widget>[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: summary.completionRate,
                  minHeight: 6,
                ),
              ),
            ],
            if (first != null) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      first.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    l10n.commonViewAll,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ] else ...<Widget>[
              const SizedBox(height: 10),
              Text(
                l10n.taskEmptyActive,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
