import 'package:flutter_test/flutter_test.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  final DateTime now = DateTime(2026, 10, 6, 10);

  setUp(() => database = AppDatabase.memory());
  tearDown(() => database.close());

  test('空库时写入示例数据', () async {
    await seedDemoDataIfEmpty(database, now: now);

    expect(await database.select(database.calendarEvents).get(), isNotEmpty);
    expect(await database.select(database.countdowns).get(), isNotEmpty);
    expect(await database.select(database.reminders).get(), isNotEmpty);
    expect(await database.select(database.calendarCategories).get(), hasLength(3));
    expect(await database.select(database.aiPersonas).get(), hasLength(1));
    expect(await database.select(database.themeConfigs).get(), hasLength(1));
  });

  test('数据库非空时不重复写入（幂等）', () async {
    await seedDemoDataIfEmpty(database, now: now);
    final firstCount = (await database.select(database.calendarEvents).get()).length;

    await seedDemoDataIfEmpty(database, now: now.add(const Duration(days: 1)));
    final secondCount = (await database.select(database.calendarEvents).get()).length;

    expect(secondCount, firstCount);
  });
}
