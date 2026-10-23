import 'package:flutter/material.dart';

import '../../application/planning/plan_actions.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

Future<bool> showPlanApplyDialog(
  BuildContext context,
  PlanApplyPreview preview,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => _PlanApplyDialog(
      preview: preview,
    ),
  );
  return result == true;
}

class _PlanApplyDialog extends StatelessWidget {
  const _PlanApplyDialog({required this.preview});

  final PlanApplyPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeCode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.planApplyPreviewTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.planApplyPreviewBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final change in preview.changes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _changeLabel(l10n, change, locale),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      if (preview.skippedItemIds.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          l10n.planApplySkipped(
                            preview.skippedItemIds.length,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.66),
                          ),
                        ),
                      ],
                      if (preview.conflicts.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        for (final conflict in preview.conflicts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              conflict,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
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
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.planApplyCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: preview.canApply
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    child: Text(l10n.planApplyConfirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _changeLabel(
    AppLocalizations l10n,
    PlanApplyChange change,
    String locale,
  ) {
    final time = change.start == null || change.end == null
        ? ''
        : '${DateFormats.shortDate(change.start!, locale)} '
            '${DateFormats.time(change.start!, locale)}-'
            '${DateFormats.time(change.end!, locale)}';
    return switch (change.action) {
      PlanApplyAction.createTask => l10n.planApplyCreateTask(change.title),
      PlanApplyAction.matchTask => l10n.planApplyMatchTask(change.title),
      PlanApplyAction.createEvent ||
      PlanApplyAction.scheduleTask =>
        l10n.planApplyScheduleTask(change.title, time),
    };
  }
}
