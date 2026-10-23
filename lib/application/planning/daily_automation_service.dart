import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/daily_digest.dart';
import '../../domain/entities/daily_plan.dart';
import '../../infrastructure/clock_provider.dart';
import '../ai/daily_digest_service.dart';
import 'daily_planning_service.dart';
import 'daily_review_service.dart';
import 'planning_context.dart';

class DailyAutomationService {
  DailyAutomationService(this._ref);

  final Ref _ref;
  bool _running = false;

  Future<void> runCatchUp() async {
    if (_running) return;
    _running = true;
    try {
      final now = _ref.read(clockProvider).now();
      if (now.hour < 12) {
        await _maybePlan(now);
      }
      if (now.hour >= 18) {
        await _maybeReview(now);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _maybePlan(DateTime now) async {
    final digestService = _ref.read(dailyDigestServiceProvider);
    if (!digestService.isEnabled(DailyDigestKind.morning)) return;
    final dayKey = DailyDigest.keyFor(now);
    final planRepository = _ref.read(dailyPlanRepositoryProvider);
    if (await planRepository.findCurrent(dayKey) != null) return;
    if (await planRepository.findLatestDraft(dayKey) != null) return;
    try {
      final generated =
          await _ref.read(dailyPlanningServiceProvider).generateDraft(
                PlanningRequest(day: now),
                generationSource: PlanGenerationSource.auto,
              );
      await _ref.read(dailyDigestRepositoryProvider).upsert(
            DailyDigest(
              id: generateId('digest', now: now),
              kind: DailyDigestKind.morning,
              dayKey: dayKey,
              content: '## ${generated.plan.summary}',
              createdAt: now,
              planId: generated.plan.id,
              updatedAt: now,
            ),
          );
    } on Object catch (error) {
      debugPrint('自动生成计划草稿失败：$error');
    }
  }

  Future<void> _maybeReview(DateTime now) async {
    final digestService = _ref.read(dailyDigestServiceProvider);
    if (!digestService.isEnabled(DailyDigestKind.evening)) return;
    try {
      await _ref.read(dailyReviewServiceProvider).ensureToday();
    } on Object catch (error) {
      debugPrint('自动生成晚间复盘失败：$error');
    }
  }
}

final dailyAutomationServiceProvider = Provider<DailyAutomationService>(
  (ref) => DailyAutomationService(ref),
);

/// 应用启动和回到前台时补做；关闭应用后的系统后台执行不作保证。
final dailyAutomationLifecycleProvider = Provider<void>((ref) {
  unawaited(ref.read(dailyAutomationServiceProvider).runCatchUp());
  final timer = Timer.periodic(
    const Duration(minutes: 15),
    (_) => unawaited(ref.read(dailyAutomationServiceProvider).runCatchUp()),
  );
  final lifecycle = AppLifecycleListener(
    onResume: () =>
        unawaited(ref.read(dailyAutomationServiceProvider).runCatchUp()),
  );
  ref.onDispose(() {
    timer.cancel();
    lifecycle.dispose();
  });
});
