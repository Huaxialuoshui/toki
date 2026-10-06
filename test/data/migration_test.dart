import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../generated_migrations/schema.dart';
import '../helpers/sqlite_bootstrap.dart';

/// 数据库迁移测试。
///
/// `drift_schemas/drift_schema_v1.json` 是 v1 的快照；以后每次改表结构都要：
///
/// ```powershell
/// dart run drift_dev schema dump lib/infrastructure/database/app_database.dart drift_schemas/
/// dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
/// ```
///
/// 然后在这里补上"从 vN 迁移到 vN+1"的用例。
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    ensureSqliteLibraryAvailable();
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 结构可以创建，且与当前代码定义一致', () async {
    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 1);
  });

  test('从空库创建后，9 张表全部存在', () async {
    final database = AppDatabase.memory();
    addTearDown(database.close);

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%' "
          'ORDER BY name',
        )
        .map((QueryRow row) => row.read<String>('name'))
        .get();

    expect(
      tables,
      containsAll(<String>[
        'ai_personas',
        'ai_providers',
        'calendar_categories',
        'calendar_events',
        'chat_messages',
        'chat_sessions',
        'countdowns',
        'reminders',
        'theme_configs',
      ]),
    );
  });
}
