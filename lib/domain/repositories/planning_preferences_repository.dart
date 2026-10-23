import '../entities/planning_preferences.dart';

/// 规划偏好的数据访问契约。
abstract interface class PlanningPreferencesRepository {
  /// 没有保存过时返回默认偏好。
  Future<PlanningPreferences> load();

  Future<void> save(PlanningPreferences preferences);

  /// 清除已保存偏好，下一次 [load] 回到默认值。
  Future<void> clear();
}
