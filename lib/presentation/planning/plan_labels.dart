import 'package:flutter/material.dart';

import '../../application/planning/plan_progress.dart';
import '../../domain/entities/daily_plan.dart';
import '../../l10n/generated/app_localizations.dart';

String planStatusLabel(AppLocalizations l10n, PlanStatus status) =>
    switch (status) {
      PlanStatus.draft => l10n.planStatusDraft,
      PlanStatus.confirmed => l10n.planStatusConfirmed,
      PlanStatus.inProgress => l10n.planStatusInProgress,
      PlanStatus.completed => l10n.planStatusCompleted,
      PlanStatus.cancelled => l10n.planStatusCancelled,
      PlanStatus.superseded => l10n.planStatusSuperseded,
    };

Color planStatusColor(ThemeData theme, PlanStatus status) => switch (status) {
      PlanStatus.draft => theme.colorScheme.tertiary,
      PlanStatus.confirmed => theme.colorScheme.primary,
      PlanStatus.inProgress => theme.colorScheme.secondary,
      PlanStatus.completed => Colors.green,
      PlanStatus.cancelled || PlanStatus.superseded => theme.colorScheme.error,
    };

String planIssueLabel(AppLocalizations l10n, PlanQualityCode code) =>
    switch (code) {
      PlanQualityCode.overbooked => l10n.planIssueOverbooked,
      PlanQualityCode.noBreak => l10n.planIssueNoBreak,
      PlanQualityCode.allDayContext => l10n.planIssueAllDay,
      PlanQualityCode.unscheduledDueSoon => l10n.planIssueUnscheduledDueSoon,
      PlanQualityCode.completedTaskWithFutureEvent =>
        l10n.planIssueCompletedFuture,
      PlanQualityCode.deadlineRisk => l10n.planIssueDeadlineRisk,
      PlanQualityCode.repeatedPostpone => l10n.planIssueRepeatedPostpone,
      PlanQualityCode.detachedEvent => l10n.planIssueDetached,
    };
