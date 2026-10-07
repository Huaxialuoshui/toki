import 'package:drift/drift.dart';

// AI 每日计划 / 每日总结（规格 §14）。
//
// 一天一条：kind 区分早间计划与晚间总结，dayKey 是 yyyy-MM-dd。
// 用户可以在设置里分别关掉，关掉后不再生成，历史记录仍然保留。
@DataClassName('DailyDigestRow')
class DailyDigests extends Table {
  TextColumn get id => text()();

  // morning / evening
  TextColumn get kind => text()();

  // 本地日期，格式 yyyy-MM-dd
  TextColumn get dayKey => text()();

  // AI 生成的正文（Markdown）
  TextColumn get content => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
