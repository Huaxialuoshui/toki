import 'package:drift/drift.dart';

import 'calendar_tables.dart';

/// 提醒（规格 §5）。
@DataClassName('ReminderRow')
@TableIndex(name: 'idx_reminders_trigger_time', columns: <Symbol>{#triggerTime})
class Reminders extends Table {
  TextColumn get id => text()();

  /// 关联日程；为空表示独立提醒。
  TextColumn get eventId => text().nullable().references(CalendarEvents, #id)();

  TextColumn get title => text()();
  DateTimeColumn get triggerTime => dateTime()();
  TextColumn get repeatRule => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
