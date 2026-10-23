import 'package:drift/drift.dart';

import '../../../domain/entities/calendar_event.dart';
import 'task_tables.dart';

/// 日历分类。
@DataClassName('CalendarCategoryRow')
class CalendarCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 颜色以 ARGB int 存储，避免数据库层依赖 Flutter。
  IntColumn get color => integer()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 日历事件（规格 §5）。
@DataClassName('CalendarEventRow')
@TableIndex(name: 'idx_events_start_time', columns: <Symbol>{#startTime})
@TableIndex(name: 'idx_events_task_id', columns: <Symbol>{#taskId})
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get location => text().nullable()();
  TextColumn get categoryId =>
      text().nullable().references(CalendarCategories, #id)();

  /// 事件自定义颜色（ARGB int）。
  IntColumn get color => integer().nullable()();

  /// 重复规则：`none` / `daily` / `weekly` / `monthly` / `yearly`（null 等价于不重复）。
  TextColumn get repeatRule => text().nullable()();

  /// 重复的结束日期（含当天）；为空表示一直重复（按查询窗口展开）。
  DateTimeColumn get repeatUntil => dateTime().nullable()();

  /// 提前提醒分钟数。
  IntColumn get reminderMinutes => integer().nullable()();

  /// 关联任务；任务删除时置空，绝不级联删除用户日程。
  TextColumn get taskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.setNull)();
  TextColumn get status => textEnum<EventStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
