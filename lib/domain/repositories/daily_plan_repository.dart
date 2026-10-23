import '../entities/daily_plan.dart';

abstract interface class DailyPlanRepository {
  Future<DailyPlan?> findById(String id);

  /// 最新开放草稿（同一天正常只有一个）。
  Future<DailyPlan?> findLatestDraft(String dayKey);

  /// 当前已确认 / 执行中 / 已完成的计划；没有时返回 null。
  Future<DailyPlan?> findCurrent(String dayKey);

  /// 某一天的全部 revision，新的在前。
  Future<List<DailyPlan>> findVersions(String dayKey);

  Stream<List<DailyPlan>> watchVersions(String dayKey);

  Future<List<DailyPlanItem>> itemsForPlan(String planId);

  Stream<List<DailyPlanItem>> watchItems(String planId);

  /// 保存一个新草稿 revision。
  ///
  /// 只把已有开放草稿标为 superseded，不修改确认 / 执行中计划。
  /// revision 在事务内计算，唯一冲突时有限重试。
  Future<DailyPlan> saveDraft(
    DailyPlan draft,
    List<DailyPlanItem> items,
  );

  Future<void> updatePlan(DailyPlan plan);

  Future<void> upsertItem(DailyPlanItem item);

  /// 新计划成功应用后，把同一天其他确认 / 执行中计划标为 superseded。
  Future<void> markOtherPlansSuperseded({
    required String dayKey,
    required String exceptPlanId,
    required DateTime updatedAt,
  });

  Future<void> deleteAll();
}
