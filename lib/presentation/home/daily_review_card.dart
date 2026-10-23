import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/daily_digest_service.dart';
import '../../application/planning/daily_review_service.dart';
import '../../core/errors/planning_exception.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/daily_digest.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/markdown_text.dart';

class DailyReviewCard extends ConsumerStatefulWidget {
  const DailyReviewCard({super.key});

  @override
  ConsumerState<DailyReviewCard> createState() => _DailyReviewCardState();
}

class _DailyReviewCardState extends ConsumerState<DailyReviewCard> {
  DailyDigest? _digest;
  DailyReviewMetrics? _metrics;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(dailyReviewServiceProvider);
    final digest = await service.today();
    final metrics = await service.buildMetrics();
    if (!mounted) return;
    setState(() {
      _digest = digest;
      _metrics = metrics;
    });
  }

  Future<void> _generate() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final result = await ref.read(dailyReviewServiceProvider).generate();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _digest = result.digest;
        _metrics = result.metrics;
      });
    } on PlanningException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            error.code == PlanningErrorCode.noProvider
                ? l10n.planNoProvider
                : l10n.reviewFailed,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.reviewFailed)),
      );
    }
  }

  Future<void> _edit() async {
    final digest = _digest;
    if (digest == null) return;
    final l10n = context.l10n;
    final content = TextEditingController(text: digest.content);
    final feedback = TextEditingController(text: digest.feedback ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.reviewEditTitle),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: content,
                minLines: 6,
                maxLines: 12,
                decoration: InputDecoration(labelText: l10n.reviewContent),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedback,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.reviewFeedback),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.planApplyCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.reviewSave),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    await ref.read(dailyReviewServiceProvider).saveEdited(
          digest: digest,
          content: content.text,
          feedback: feedback.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.reviewSaved)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final enabled = ref
        .watch(dailyDigestServiceProvider)
        .isEnabled(DailyDigestKind.evening);
    if (!enabled) return const SizedBox.shrink();

    final metrics = _digest == null
        ? _metrics
        : (DailyReviewMetrics.fromJsonString(_digest!.metricsJson) ?? _metrics);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.nightlight_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.digestEveningTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_digest != null)
                  IconButton(
                    onPressed: _busy ? null : _edit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: l10n.reviewEdit,
                  ),
                IconButton(
                  onPressed: _busy ? null : _generate,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: _digest == null
                      ? l10n.reviewGenerate
                      : l10n.reviewRegenerate,
                ),
              ],
            ),
            if (metrics != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                l10n.reviewMetricsLine(
                  metrics.totalTasks,
                  metrics.completedTaskIds.length,
                  metrics.openTaskIds.length,
                  metrics.unknownEventCount,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (_busy)
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.reviewGenerating),
                ],
              )
            else if (_digest == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    (metrics?.totalTasks ?? 0) == 0
                        ? l10n.reviewNoTasks
                        : l10n.reviewLocalOnly,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.66),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(l10n.reviewGenerate),
                    ),
                  ),
                ],
              )
            else ...<Widget>[
              MarkdownText(
                _digest!.content,
                copyLabel: l10n.aiMessageCopied,
              ),
              if ((_digest!.feedback ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  l10n.reviewFeedback,
                  style: theme.textTheme.labelMedium,
                ),
                Text(
                  _digest!.feedback!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
