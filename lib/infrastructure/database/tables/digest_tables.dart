import 'package:drift/drift.dart';

import 'task_tables.dart';

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

  /// 关联的结构化计划；计划删除时保留摘要本身。
  TextColumn get planId => text()
      .nullable()
      .references(DailyPlans, #id, onDelete: KeyAction.setNull)();

  /// 用户补充的困难 / 反馈。
  TextColumn get feedback => text().nullable()();

  /// 由本地数据库计算出的复盘指标 JSON；旧记录为空。
  TextColumn get metricsJson => text().nullable()();

  /// 用户是否编辑过正文；自动生成不得覆盖用户编辑内容。
  BoolColumn get userEdited => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
