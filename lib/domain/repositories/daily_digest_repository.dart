import '../entities/daily_digest.dart';

/// AI 每日计划 / 总结的数据访问契约（规格 §14）。
abstract interface class DailyDigestRepository {
  /// 某一天的全部记录（早间 / 晚间）。
  Future<List<DailyDigest>> findByDay(String dayKey);

  /// 某一天某一种是否已经生成过。
  Future<DailyDigest?> find(String dayKey, DailyDigestKind kind);

  /// 最近的若干条（新→旧），用于在首页展示。
  Stream<List<DailyDigest>> watchRecent({int limit = 20});

  Future<void> upsert(DailyDigest digest);
  Future<void> deleteById(String id);
  Future<void> deleteAll();
}
