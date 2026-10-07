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

    // 从 v1 快照建库，再迁移到当前版本并校验结构一致。
    await verifier.migrateAndValidate(database, 5);
  });

  test('v1 → v2 迁移会补上 chat_messages.tool_call_id', () async {
    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await database.customStatement('PRAGMA foreign_keys = OFF');
    await verifier.migrateAndValidate(database, 5);

    final columns = await database
        .customSelect('PRAGMA table_info(chat_messages)')
        .map((QueryRow row) => row.read<String>('name'))
        .get();
    expect(columns, contains('tool_call_id'));
  });

  test('v2 → v3 迁移会补上 theme_configs.shadow_strength', () async {
    final connection = await verifier.startAt(2);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 5);

    final columns = await database
        .customSelect('PRAGMA table_info(theme_configs)')
        .map((QueryRow row) => row.read<String>('name'))
        .get();
    expect(columns, contains('shadow_strength'));
  });

  test('v3 → v4 迁移会补上会话服务商 / 倒计时背景色 / 重复结束日期 / 每日计划表', () async {
    final connection = await verifier.startAt(3);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 5);

    Future<List<String>> columnsOf(String table) => database
        .customSelect('PRAGMA table_info($table)')
        .map((QueryRow row) => row.read<String>('name'))
        .get();

    expect(await columnsOf('chat_sessions'), contains('provider_id'));
    expect(await columnsOf('countdowns'), contains('background_color'));
    expect(await columnsOf('calendar_events'), contains('repeat_until'));

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'daily_digests'",
        )
        .get();
    expect(tables, hasLength(1));
  });

  test('v4 → v5 迁移会补上主题的区域配色列', () async {
    final connection = await verifier.startAt(4);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 5);

    final columns = await database
        .customSelect('PRAGMA table_info(theme_configs)')
        .map((QueryRow row) => row.read<String>('name'))
        .get();
    expect(
      columns,
      containsAll(<String>[
        'navigation_bar_color',
        'sidebar_color',
        'event_color',
        'countdown_color',
      ]),
    );
  });

  test('从空库创建后，10 张表全部存在', () async {
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
        'daily_digests',
        'reminders',
        'theme_configs',
      ]),
    );
  });
}
