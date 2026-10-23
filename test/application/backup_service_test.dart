import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/backup/backup_service.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/backup/backup_store.dart';
import 'package:toki/data/repositories/drift_planning_preferences_repository.dart';
import 'package:toki/data/repositories/drift_task_repository.dart';
import 'package:toki/domain/entities/backup.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/domain/entities/planning_preferences.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/backup/backup_file_store.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

/// Phase 12：备份 / 恢复。
///
/// 这些用例直接打数据库，不走 UI，方便逐条核对"到底写了什么"。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late BackupService service;
  late Directory directory;
  late FixedClock clock;

  setUp(() async {
    database = AppDatabase.memory();
    directory = await Directory.systemTemp.createTemp('toki-backup-test');
    clock = FixedClock(DateTime(2026, 10, 6, 21, 30));
    service = BackupService(
      store: BackupStore(database),
      files: BackupFileStore(directory: directory),
      clock: clock,
      currentSchemaVersion: AppDatabase.currentSchemaVersion,
    );
  });

  tearDown(() async {
    await database.close();
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  Future<void> seed() async {
    await database.into(database.calendarCategories).insert(
          CalendarCategoriesCompanion.insert(
            id: 'cat-1',
            name: '工作',
            color: 0xFF5A6BF0,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: 'event-1',
            title: '毕业答辩',
            startTime: DateTime(2026, 10, 19, 15),
            endTime: DateTime(2026, 10, 19, 17),
            status: EventStatus.scheduled,
            categoryId: const Value<String>('cat-1'),
            reminderMinutes: const Value<int>(30),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.countdowns).insert(
          CountdownsCompanion.insert(
            id: 'cd-1',
            title: '项目截止',
            targetTime: DateTime(2026, 10, 9, 20),
            displayStyle: CountdownDisplayStyle.bigNumber,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.aiProviders).insert(
          AiProvidersCompanion.insert(
            id: 'prov-1',
            name: 'DeepSeek',
            baseUrl: 'https://api.deepseek.com',
            model: 'deepseek-chat',
            apiKey: const Value<String>('sk-secret-value'),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.aiPersonas).insert(
          AiPersonasCompanion.insert(
            id: 'persona-1',
            name: 'Toki',
            enabledTools: const <String>[],
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.chatSessions).insert(
          ChatSessionsCompanion.insert(
            id: 'session-1',
            title: '默认会话',
            personaId: const Value<String>('persona-1'),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.chatMessages).insert(
          ChatMessagesCompanion.insert(
            id: 'msg-1',
            sessionId: 'session-1',
            role: ChatRole.user,
            content: '明天有什么安排？',
            createdAt: clock.now(),
          ),
        );
    await database.into(database.themeConfigs).insert(
          ThemeConfigsCompanion.insert(
            id: 'theme-1',
            name: 'Ocean',
            brightness: 'light',
            primaryColor: 0xFF12B5A5,
            secondaryColor: 0xFF3DBF7A,
            backgroundColor: 0xFFF2FBF8,
            surfaceColor: 0xFFFFFFFF,
            textColor: 0xFF12211C,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
  }

  Future<Map<String, int>> counts() async {
    final result = <String, int>{};
    for (final table in BackupTables.ordered) {
      final row = await database
          .customSelect('SELECT COUNT(*) AS c FROM $table')
          .getSingle();
      result[table] = row.read<int>('c');
    }
    return result;
  }

  test('导出会落盘，文件里带格式版本与各表条数', () async {
    await seed();

    final result = await service.export(includeApiKeys: false);

    expect(result.file.existsSync(), isTrue);
    expect(result.file.path, contains('toki-backup-20261006-213000.json'));

    final payload = jsonDecode(result.json) as Map<String, dynamic>;
    expect(payload['format'], kBackupFormatTag);
    expect(payload['formatVersion'], kBackupFormatVersion);
    expect(payload['schemaVersion'], AppDatabase.currentSchemaVersion);
    expect(payload['includesApiKeys'], isFalse);
    expect((payload['counts'] as Map)['calendar_events'], 1);
    expect((payload['tables'] as Map)['calendar_events'], hasLength(1));

    final listed = await service.listFiles();
    expect(listed, hasLength(1));
    expect(listed.single.name,
        result.file.path.split(Platform.pathSeparator).last);
  });

  test('API Key 默认不导出，打开开关才带上', () async {
    await seed();

    final withoutKeys = await service.export(includeApiKeys: false);
    final hidden = service.parse(withoutKeys.json);
    expect(hidden.tables['ai_providers']!.single['apiKey'], isNull);

    final withKeys = await service.export(includeApiKeys: true);
    final visible = service.parse(withKeys.json);
    expect(visible.tables['ai_providers']!.single['apiKey'], 'sk-secret-value');
    expect(visible.summary.includeApiKeys, isTrue);
  });

  test('覆盖恢复：清库后整份写回，条数与内容一致', () async {
    await seed();
    final backup = await service.export(includeApiKeys: true);
    final before = await counts();

    await database.delete(database.chatMessages).go();
    await database.delete(database.chatSessions).go();
    await database.delete(database.calendarEvents).go();
    await database.delete(database.calendarCategories).go();
    await database.delete(database.countdowns).go();
    await database.delete(database.aiPersonas).go();
    await database.delete(database.aiProviders).go();
    await database.delete(database.themeConfigs).go();
    expect((await counts()).values.every((int c) => c == 0), isTrue);

    final summary = await service.restore(
      backup.json,
      mode: RestoreMode.replace,
    );

    expect(summary.total, before.values.reduce((int a, int b) => a + b));
    expect(await counts(), before);
    final event = await database.select(database.calendarEvents).getSingle();
    expect(event.title, '毕业答辩');
    expect(event.categoryId, 'cat-1');
    expect(event.reminderMinutes, 30);
    final provider = await database.select(database.aiProviders).getSingle();
    expect(provider.apiKey, 'sk-secret-value');
  });

  test('合并恢复：同 id 覆盖、新 id 追加、其余保留', () async {
    await seed();
    final backup = await service.export(includeApiKeys: true);

    // 本机已有一条别的倒计时，且把备份里的那条标题改掉。
    await database.into(database.countdowns).insert(
          CountdownsCompanion.insert(
            id: 'cd-local',
            title: '本机倒计时',
            targetTime: DateTime(2026, 11, 1),
            displayStyle: CountdownDisplayStyle.fullText,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await (database.update(database.countdowns)
          ..where(($CountdownsTable t) => t.id.equals('cd-1')))
        .write(const CountdownsCompanion(title: Value<String>('被改坏了')));

    await service.restore(backup.json, mode: RestoreMode.merge);

    final rows = await database.select(database.countdowns).get();
    expect(rows.map((CountdownRow r) => r.id),
        containsAll(<String>['cd-1', 'cd-local']));
    // 备份里的 cd-1 覆盖掉被改坏的标题，本机的 cd-local 原样保留。
    expect(
      rows.firstWhere((CountdownRow r) => r.id == 'cd-1').title,
      '项目截止',
    );
    expect(
      rows.firstWhere((CountdownRow r) => r.id == 'cd-local').title,
      '本机倒计时',
    );
  });

  test('格式校验：非 JSON / 非 Toki 备份 / 更高版本都会被拒绝', () async {
    expect(
      () => service.parse('not-json'),
      throwsA(
        isA<BackupException>().having(
            (BackupException e) => e.code, 'code', BackupErrorCode.notJson),
      ),
    );
    expect(
      () => service.parse('{"hello":"world"}'),
      throwsA(
        isA<BackupException>().having(
          (BackupException e) => e.code,
          'code',
          BackupErrorCode.notTokiBackup,
        ),
      ),
    );
    expect(
      () => service.parse(
        '{"format":"toki-backup","formatVersion":99,"schemaVersion":3,"tables":{}}',
      ),
      throwsA(
        isA<BackupException>().having(
          (BackupException e) => e.code,
          'code',
          BackupErrorCode.unsupportedFormatVersion,
        ),
      ),
    );
    expect(
      () => service.parse(
        '{"format":"toki-backup","formatVersion":1,"schemaVersion":99,"tables":{}}',
      ),
      throwsA(
        isA<BackupException>().having(
          (BackupException e) => e.code,
          'code',
          BackupErrorCode.unsupportedSchemaVersion,
        ),
      ),
    );
    expect(
      () => service.parse(
          '{"format":"toki-backup","formatVersion":1,"schemaVersion":3}'),
      throwsA(
        isA<BackupException>().having(
          (BackupException e) => e.code,
          'code',
          BackupErrorCode.missingTables,
        ),
      ),
    );
  });

  test('损坏的行会让整次恢复失败，且不会写坏现有数据', () async {
    await seed();
    final before = await counts();

    const broken = '{"format":"toki-backup","formatVersion":1,'
        '"schemaVersion":3,"tables":{"calendar_events":[{"id":"bad"}]}}';

    await expectLater(
      service.restore(broken, mode: RestoreMode.replace),
      throwsA(
        isA<BackupException>().having(
          (BackupException e) => e.code,
          'code',
          BackupErrorCode.corrupted,
        ),
      ),
    );

    // 事务回滚：数据还是原来的样子，没有被清空也没有半份写入。
    expect(await counts(), before);
  });

  test('恢复到的条数就是 summary.total', () async {
    await seed();
    final backup = await service.export(includeApiKeys: false);
    final document = service.parse(backup.json);

    expect(document.summary.counts['calendar_events'], 1);
    expect(document.summary.counts['chat_messages'], 1);
    expect(document.summary.total, 8);
    expect(document.summary.exportedAt, clock.now());
    expect(document.summary.appVersion, isNotEmpty);
  });

  test('v7 旧备份缺少新表 / 新列时仍可恢复，旧数据不被覆盖', () async {
    const legacy = '{"format":"toki-backup","formatVersion":1,'
        '"schemaVersion":7,"tables":{'
        '"calendar_events":[{"id":"event-legacy","title":"旧日程",'
        '"description":null,"startTime":"2026-10-18T09:00:00.000",'
        '"endTime":"2026-10-18T10:00:00.000","allDay":false,'
        '"location":null,"categoryId":null,"color":null,"repeatRule":null,'
        '"repeatUntil":null,"reminderMinutes":null,"status":"scheduled",'
        '"createdAt":"2026-10-18T08:00:00.000",'
        '"updatedAt":"2026-10-18T08:00:00.000"}],'
        '"daily_digests":[{"id":"digest-legacy","kind":"morning",'
        '"dayKey":"2026-10-18","content":"旧版计划摘要",'
        '"createdAt":"2026-10-18T08:00:00.000"}]}}';

    await service.restore(legacy, mode: RestoreMode.merge);

    final event = await database
        .customSelect(
          "SELECT task_id FROM calendar_events WHERE id = 'event-legacy'",
        )
        .getSingle();
    expect(event.read<String?>('task_id'), null);

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

  test('任务、计划、条目与规划偏好会进入备份并完整恢复', () async {
    final taskRepository = DriftTaskRepository(database);
    await taskRepository.upsert(
      TaskItem(
        id: 'task-1',
        title: '备份任务',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        source: TaskSource.manual,
        estimatedMinutes: 45,
        postponeCount: 0,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );

    final preferencesRepository = DriftPlanningPreferencesRepository(
      database,
      clock: clock,
    );
    await preferencesRepository.save(
      PlanningPreferences(
        createdAt: clock.now(),
        updatedAt: clock.now(),
        focusMinutes: 90,
      ),
    );

    await database.into(database.dailyPlans).insert(
          DailyPlansCompanion.insert(
            id: 'plan-1',
            dayKey: '2026-10-18',
            revision: 1,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await database.into(database.dailyPlanItems).insert(
          DailyPlanItemsCompanion.insert(
            id: 'item-1',
            planId: 'plan-1',
            titleSnapshot: '备份任务',
            taskId: const Value<String>('task-1'),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );

    final backup = await service.export(includeApiKeys: false);
    final document = service.parse(backup.json);
    expect(document.summary.counts['tasks'], 1);
    expect(document.summary.counts['daily_plans'], 1);
    expect(document.summary.counts['daily_plan_items'], 1);
    expect(document.summary.counts['planning_preferences'], 1);

    await database.delete(database.dailyPlanItems).go();
    await database.delete(database.dailyPlans).go();
    await database.delete(database.planningPreferenceSettings).go();
    await database.delete(database.tasks).go();

    await service.restore(backup.json, mode: RestoreMode.merge);

    expect((await taskRepository.findById('task-1'))!.title, '备份任务');
    expect((await preferencesRepository.load()).focusMinutes, 90);
    final planItem = await database.select(database.dailyPlanItems).getSingle();
    expect(planItem.planId, 'plan-1');
    expect(planItem.taskId, 'task-1');
  });
}
