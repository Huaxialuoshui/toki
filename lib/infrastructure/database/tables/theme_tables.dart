import 'package:drift/drift.dart';

/// 用户自建 / 导入的主题（规格 §11）。
///
/// 内置预设仍然在代码里（ThemePresets），这张表只保存用户自己的主题；
/// 与 shared_preferences 里的「当前主题 id」是两件事。
@DataClassName('ThemeConfigRow')
class ThemeConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// light / dark，避免数据库层依赖 Flutter 的 Brightness。
  TextColumn get brightness => text()();
  IntColumn get primaryColor => integer()();
  IntColumn get secondaryColor => integer()();
  IntColumn get backgroundColor => integer()();
  IntColumn get surfaceColor => integer()();
  IntColumn get textColor => integer()();
  RealColumn get borderRadius => real().withDefault(const Constant(18))();
  RealColumn get cardOpacity => real().withDefault(const Constant(1))();
  RealColumn get blurAmount => real().withDefault(const Constant(0))();
  RealColumn get fontScale => real().withDefault(const Constant(1))();
  BoolColumn get animationEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
