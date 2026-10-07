import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/ai/tools/ai_tool.dart';
import 'package:toki/application/ai/tools/tool_registry.dart';
import 'package:toki/application/calendar/calendar_actions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_countdown_repository.dart';
import 'package:toki/data/repositories/drift_reminder_repository.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository events;
  late DriftCountdownRepository countdowns;
  late DriftReminderRepository reminders;
  late AiToolRegistry registry;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  setUp(() {
    database = AppDatabase.memory();
    events = DriftCalendarRepository(database, clock: clock);
    countdowns = DriftCountdownRepository(database, clock: clock);
    reminders = DriftReminderRepository(database);
    registry = AiToolRegistry.standard(
      bundle: ToolDependencies(
        calendar: events,
        countdowns: countdowns,
        reminders: reminders,
        calendarActions: CalendarActions(
          events: events,
          reminders: reminders,
          clock: clock,
        ),
        clock: clock,
      ),
    );
  });

  tearDown(() => database.close());

  /// 执行工具并解析回灌给模型的 JSON。
  Future<Map<String, Object?>> run(
      String name, Map<String, Object?> args) async {
    final tool = registry.byName(name);
    expect(tool, isNotNull, reason: '工具 $name 应当已注册');
    final result = await tool!.execute(args);
    final decoded = jsonDecode(result.toJsonString()) as Map<String, Object?>;
    decoded['__isError'] = result.isError;
    return decoded;
  }

  test('工具集包含规格要求的全部 15 个工具', () {
    expect(
      registry.all.map((AiTool tool) => tool.name).toSet(),
      <String>{
        'get_current_time',
        'get_today_events',
        'get_events',
        'search_events',
        'get_calendar_summary',
        'create_event',
        'update_event',
        'delete_event',
        'get_countdowns',
        'create_countdown',
        'update_countdown',
        'delete_countdown',
        'create_reminder',
        'update_reminder',
        'delete_reminder',
      },
    );
  });

  test('get_current_time 用注入的时钟', () async {
    final result = await run('get_current_time', <String, Object?>{});
    final payload = result['result']! as Map<String, Object?>;
    expect(payload['date'], '2026-10-06');
    expect(payload['time'], '10:00');
    expect(payload['weekday'], 'Tuesday');
  });

  test('create_event 落库，并按 reminder_minutes 生成提醒', () async {
    final result = await run('create_event', <String, Object?>{
      'title': '毕业答辩',
      'start_time': '2026-10-20T15:00:00',
      'reminder_minutes': 30,
      'location': '教学楼 A-302',
    });

    expect(result['__isError'], isFalse);
    final payload = result['result']! as Map<String, Object?>;
    expect(payload['title'], '毕业答辩');
    expect(payload['start_time'], '2026-10-20T15:00:00.000');

    final stored = await events.getAll();
    expect(stored, hasLength(1));
    expect(stored.single.startTime, DateTime(2026, 10, 20, 15));
    expect(stored.single.endTime, DateTime(2026, 10, 20, 16));

    final createdReminders = await reminders.getForEvent(stored.single.id);
    expect(createdReminders, hasLength(1));
    expect(
      createdReminders.single.triggerTime,
      DateTime(2026, 10, 20, 14, 30),
    );
  });

  test('create_event 对模糊/非法时间给出可读错误', () async {
    final missing = await run('create_event', <String, Object?>{
      'title': '答辩',
    });
    expect(missing['__isError'], isTrue);
    expect(missing['error'].toString(), contains('ISO-8601'));

    final invalid = await run('create_event', <String, Object?>{
      'title': '答辩',
      'start_time': '明天下午三点',
    });
    expect(invalid['__isError'], isTrue);
    expect(invalid['error'].toString(), contains('ISO-8601'));
    expect(await events.count(), 0, reason: '非法参数不应写入数据');
  });

  test('update_event 修改字段，delete_event 连提醒一起删', () async {
    await run('create_event', <String, Object?>{
      'title': '答辩',
      'start_time': '2026-10-20T15:00:00',
      'reminder_minutes': 60,
    });
    final event = (await events.getAll()).single;

    final updated = await run('update_event', <String, Object?>{
      'event_id': event.id,
      'title': '毕业答辩（改）',
      'start_time': '2026-10-21T09:30:00',
    });
    expect(updated['__isError'], isFalse);

    final afterUpdate = (await events.findById(event.id))!;
    expect(afterUpdate.title, '毕业答辩（改）');
    expect(afterUpdate.startTime, DateTime(2026, 10, 21, 9, 30));
    expect(afterUpdate.endTime, DateTime(2026, 10, 21, 10, 30));
    // 提醒时间跟着新开始时间走
    expect(
      (await reminders.getForEvent(event.id)).single.triggerTime,
      DateTime(2026, 10, 21, 8, 30),
    );

    final deleted = await run('delete_event', <String, Object?>{
      'event_id': event.id,
    });
    expect(deleted['__isError'], isFalse);
    expect(await events.count(), 0);
    expect(await reminders.count(), 0);
  });

  test('查询类工具：今天 / 范围 / 搜索 / 汇总', () async {
    await run('create_event', <String, Object?>{
      'title': '晨间计划',
      'start_time': '2026-10-06T09:00:00',
    });
    await run('create_event', <String, Object?>{
      'title': '课程项目截止',
      'start_time': '2026-10-08T20:00:00',
    });

    final today = await run('get_today_events', <String, Object?>{});
    expect((today['result']! as Map<String, Object?>)['count'], 1);

    final range = await run('get_events', <String, Object?>{
      'from': '2026-10-06T00:00:00',
      'to': '2026-10-31T00:00:00',
    });
    expect((range['result']! as Map<String, Object?>)['count'], 2);

    final search = await run('search_events', <String, Object?>{
      'query': '截止',
    });
    expect((search['result']! as Map<String, Object?>)['count'], 1);

    final summary = await run('get_calendar_summary', <String, Object?>{
      'from': '2026-10-01T00:00:00',
      'to': '2026-11-01T00:00:00',
    });
    expect((summary['result']! as Map<String, Object?>)['count'], 2);
  });

  test('倒计时工具：创建 / 查询（含剩余时间）/ 修改 / 删除', () async {
    final created = await run('create_countdown', <String, Object?>{
      'title': '毕业答辩',
      'target_time': '2026-10-19T15:00:00',
    });
    final id = (created['result']! as Map<String, Object?>)['id']! as String;

    final list = await run('get_countdowns', <String, Object?>{});
    final payload = list['result']! as Map<String, Object?>;
    expect(payload['count'], 1);
    final first =
        (payload['countdowns']! as List<Object?>).first as Map<String, Object?>;
    expect(first['remaining_days'], 13);

    await run('update_countdown', <String, Object?>{
      'countdown_id': id,
      'is_pinned': true,
      'title': '毕业答辩（改）',
    });
    expect((await countdowns.findById(id))!.isPinned, isTrue);
    expect((await countdowns.findById(id))!.title, '毕业答辩（改）');

    await run('delete_countdown', <String, Object?>{'countdown_id': id});
    expect(await countdowns.count(), 0);
  });

  test('提醒工具：创建 / 修改（停用）/ 删除', () async {
    final created = await run('create_reminder', <String, Object?>{
      'title': '给妈妈打电话',
      'trigger_time': '2026-10-06T20:00:00',
    });
    final id = (created['result']! as Map<String, Object?>)['id']! as String;
    expect(await reminders.count(), 1);

    await run('update_reminder', <String, Object?>{
      'reminder_id': id,
      'enabled': false,
    });
    expect((await reminders.findById(id))!.enabled, isFalse);

    await run('delete_reminder', <String, Object?>{'reminder_id': id});
    expect(await reminders.count(), 0);
  });

  test('操作不存在的 id 会返回错误而不是抛异常', () async {
    final result = await run('delete_event', <String, Object?>{
      'event_id': 'not-exists',
    });
    expect(result['__isError'], isTrue);
    expect(result['error'].toString(), contains('没有找到'));
  });

  test('删除类工具都标记为需要确认，查询类不需要', () {
    for (final tool in registry.all) {
      if (tool.category == AiToolCategory.delete) {
        expect(tool.requiresConfirmation, isTrue, reason: tool.name);
      } else if (tool.category == AiToolCategory.read) {
        expect(tool.requiresConfirmation, isFalse, reason: tool.name);
      }
    }
  });

  test('CalendarEvent 事件不参与：create_event 的 end_time 早于 start_time 会报错',
      () async {
    final result = await run('create_event', <String, Object?>{
      'title': '错误时间',
      'start_time': '2026-10-20T15:00:00',
      'end_time': '2026-10-20T14:00:00',
    });
    expect(result['__isError'], isTrue);
    expect(await events.count(), 0);
  });
}
