import 'package:drift/drift.dart';

import '../../../domain/entities/countdown_item.dart';

/// 倒计时。
///
/// 注意：`remainingSeconds` 这类派生值不入库，永远由 `targetTime - now` 实时算。
@DataClassName('CountdownRow')
@TableIndex(name: 'idx_countdowns_target_time', columns: <Symbol>{#targetTime})
class Countdowns extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get targetTime => dateTime()();
  TextColumn get description => text().nullable()();
  IntColumn get color => integer().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get displayStyle => textEnum<CountdownDisplayStyle>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
