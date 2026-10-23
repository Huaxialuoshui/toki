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
    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );
  });

  test('v1 → v2 迁移会补上 chat_messages.tool_call_id', () async {
    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await database.customStatement('PRAGMA foreign_keys = OFF');
    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

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

    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

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

    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

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

    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

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

  test('v5 → v6 迁移会补上思考内容与人设头像底色', () async {
    final connection = await verifier.startAt(5);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

    Future<List<String>> columnsOf(String table) => database
        .customSelect('PRAGMA table_info($table)')
        .map((QueryRow row) => row.read<String>('name'))
        .get();

    expect(await columnsOf('chat_messages'), contains('reasoning_content'));
    expect(await columnsOf('ai_personas'), contains('avatar_color'));
  });

  test('v6 → v7 迁移会补上人设的"作为日历助手"，且老数据默认打开', () async {
    final connection = await verifier.startAt(6);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    // 先在 v6 库里放一个人设（这时还没有这一列）。
    await database.customStatement(
      'INSERT INTO ai_personas '
      '(id, name, system_prompt, enabled_tools, created_at, updated_at) '
      "VALUES ('p-legacy', '小雪', '你是用户的私人日程助手。', '[]', 0, 0)",
    );

    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

    final rows = await database
        .customSelect(
          'SELECT calendar_assistant_enabled FROM ai_personas '
          "WHERE id = 'p-legacy'",
        )
        .map((QueryRow row) => row.read<int>('calendar_assistant_enabled'))
        .get();
    // 升级不能让老库里的人设突然变成纯聊天。
    expect(rows.single, 1);
  });

  test('v7 → v8 迁移会新增任务 / 计划表并保留旧摘要', () async {
    final connection = await verifier.startAt(7);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await database.customStatement(
      'INSERT INTO daily_digests '
      '(id, kind, day_key, content, created_at) '
      "VALUES ('digest-legacy', 'morning', '2026-10-18', "
      "'旧版计划摘要', 0)",
    );

    await verifier.migrateAndValidate(
      database,
      AppDatabase.currentSchemaVersion,
    );

    Future<List<String>> columnsOf(String table) => database
        .customSelect('PRAGMA table_info($table)')
        .map((QueryRow row) => row.read<String>('name'))
        .get();

    expect(await columnsOf('calendar_events'), contains('task_id'));
    expect(
      await columnsOf('daily_digests'),
      containsAll(<String>[
        'plan_id',
        'feedback',
        'metrics_json',
        'updated_at',
        'user_edited',
      ]),
    );

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('tasks', 'daily_plans', 'daily_plan_items', "
          "'planning_preferences') ORDER BY name",
        )
        .map((QueryRow row) => row.read<String>('name'))
        .get();
    expect(
      tables,
      <String>[
        'daily_plan_items',
        'daily_plans',
        'planning_preferences',
        'tasks',
      ],
    );

    final digest = await database
        .customSelect(
          'SELECT content, plan_id, user_edited FROM daily_digests '
          "WHERE id = 'digest-legacy'",
        )
        .getSingle();
    expect(digest.read<String>('content'), '旧版计划摘要');
    expect(digest.read<String?>('plan_id'), null);
    expect(digest.read<int>('user_edited'), 0);
  });

  test('从空库创建后，14 张表全部存在', () async {
    // 注意：这里只是确认表都在，列级校验交给 migrateAndValidate。
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
        'daily_plan_items',
        'daily_plans',
        'planning_preferences',
        'reminders',
        'tasks',
        'theme_configs',
      ]),
    );
  });
}
