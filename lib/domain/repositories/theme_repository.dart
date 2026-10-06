import '../entities/theme_config.dart';

/// 用户自建 / 导入主题的数据访问契约。
///
/// 内置预设不在这张表里（它们固定在代码中）。
abstract interface class ThemeRepository {
  Stream<List<ThemeConfig>> watchAll();
  Future<List<ThemeConfig>> getAll();
  Future<ThemeConfig?> findById(String id);
  Future<void> upsert(ThemeConfig config);
  Future<void> deleteById(String id);
  Future<void> deleteAll();
}
