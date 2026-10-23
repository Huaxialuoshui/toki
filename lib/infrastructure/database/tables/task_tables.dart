import 'package:drift/drift.dart';

import '../../../domain/entities/task_item.dart';

/// 独立任务。任务不必有日程，日程通过可空 `taskId` 反向关联。
@DataClassName('TaskRow')
@TableIndex(name: 'idx_tasks_status_due', columns: <Symbol>{#status, #dueAt})
@TableIndex(
  name: 'idx_tasks_archived_updated',
  columns: <Symbol>{#archivedAt, #updatedAt},
)
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get priority =>
      textEnum<TaskPriority>().withDefault(const Constant('normal'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  IntColumn get actualMinutes => integer().nullable()();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(const Constant('open'))();
  TextColumn get source =>
      textEnum<TaskSource>().withDefault(const Constant('manual'))();

  /// 从日程拆分时的来源；只作历史追踪，不设外键，避免任务 / 日程循环依赖。
  TextColumn get sourceEventId => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get completionNote => text().nullable()();
  IntColumn get postponeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPostponedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 每日计划的一个 revision。
///
/// 同一天可以有多个历史 revision；正常情况下只有一个开放 `draft`，
/// 已确认 / 执行中计划不会因为生成新草稿而被覆盖。
@DataClassName('DailyPlanRow')
@TableIndex(
  name: 'idx_daily_plans_day_revision',
  columns: <Symbol>{#dayKey, #revision},
  unique: true,
)
class DailyPlans extends Table {
  TextColumn get id => text()();
  TextColumn get dayKey => text()();
  IntColumn get revision => integer()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get goalsJson => text().withDefault(const Constant('[]'))();
  TextColumn get constraintsJson => text().withDefault(const Constant('{}'))();
  TextColumn get generationSource =>
      text().withDefault(const Constant('manual'))();
  TextColumn get generationDiagnosticsJson => text().nullable()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 计划条目。
///
/// `taskId = null` 只允许用于 `newTask + proposed` 草稿；应用事务先创建正式
/// 任务并写回 `taskId`，任何 `applied` 条目都必须有有效任务。
@DataClassName('DailyPlanItemRow')
@TableIndex(
  name: 'idx_daily_plan_items_plan_sort',
  columns: <Symbol>{#planId, #sortOrder},
)
@TableIndex(
  name: 'idx_daily_plan_items_task_status',
  columns: <Symbol>{#taskId, #status},
)
class DailyPlanItems extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(DailyPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get taskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.setNull)();
  TextColumn get titleSnapshot => text()();
  TextColumn get descriptionSnapshot => text().nullable()();
  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();
  IntColumn get estimateMinutes => integer().nullable()();
  TextColumn get priority =>
      textEnum<TaskPriority>().withDefault(const Constant('normal'))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('existingTask'))();
  TextColumn get sourceEventId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('proposed'))();

  /// 历史指针，不设外键：日程被用户删除后必须能识别为 detached。
  TextColumn get appliedEventId => text().nullable()();
  DateTimeColumn get appliedAt => dateTime().nullable()();
  TextColumn get failureReason => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 规划偏好的单行配置（固定 ID `default`）。
@DataClassName('PlanningPreferenceRow')
class PlanningPreferenceSettings extends Table {
  @override
  String get tableName => 'planning_preferences';

  TextColumn get id => text()();
  IntColumn get workdayStartMinute =>
      integer().withDefault(const Constant(9 * 60))();
  IntColumn get workdayEndMinute =>
      integer().withDefault(const Constant(18 * 60))();
  IntColumn get lunchStartMinute =>
      integer().withDefault(const Constant(12 * 60))();
  IntColumn get lunchEndMinute =>
      integer().withDefault(const Constant(13 * 60 + 30))();
  IntColumn get focusMinutes => integer().withDefault(const Constant(60))();
  IntColumn get breakMinutes => integer().withDefault(const Constant(10))();
  TextColumn get defaultPriority =>
      textEnum<TaskPriority>().withDefault(const Constant('normal'))();
  IntColumn get slotMinutes => integer().withDefault(const Constant(30))();
  BoolColumn get weekdaysOnly => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
