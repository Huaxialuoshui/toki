import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/ai/context_service.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_countdown_repository.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository events;
  late DriftCountdownRepository countdowns;
  late ContextService service;
  // 2026-10-06 是星期二。
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  setUp(() {
    database = AppDatabase.memory();
    events = DriftCalendarRepository(database, clock: clock);
    countdowns = DriftCountdownRepository(database, clock: clock);
    service = ContextService(
      events: events,
      countdowns: countdowns,
      clock: clock,
    );
  });

  tearDown(() => database.close());

  Future<void> addEvent(String title, DateTime start, {int hours = 1}) {
    return events.upsert(
      CalendarEvent(
        id: 'event-$title-${start.millisecondsSinceEpoch}',
        title: title,
        startTime: start,
        endTime: start.add(Duration(hours: hours)),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
  }

  Future<void> addCountdown(String title, DateTime target,
      {bool pinned = false}) {
    return countdowns.upsert(
      CountdownItem(
        id: 'cd-$title',
        title: title,
        targetTime: target,
        isPinned: pinned,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
  }

  test('总是包含当前时间', () async {
    final context = await service.buildContext('你好');
    expect(context, contains('当前时间：2026-10-06 10:00 周二'));
  });

  test('问"今天"只带今天的日程', () async {
    await addEvent('晨间计划', DateTime(2026, 10, 6, 9));
    await addEvent('下周例会', DateTime(2026, 10, 14, 19));

    final context = await service.buildContext('今天有什么安排？');

    expect(context, contains('今天的日程'));
    expect(context, contains('晨间计划'));
    expect(context, isNot(contains('下周例会')));
  });

  test('问"下周"带下周（周一至周日）的日程', () async {
    await addEvent('本周例会', DateTime(2026, 10, 7, 19)); // 本周三
    await addEvent('下周答辩', DateTime(2026, 10, 14, 15)); // 下周三

    final context = await service.buildContext('我下周有什么安排？');

    expect(context, contains('下周的日程'));
    expect(context, contains('下周答辩'));
    expect(context, isNot(contains('本周例会')));
  });

  test('问具体日期（10月20日）只带那一天的日程', () async {
    await addEvent('答辩', DateTime(2026, 10, 20, 15));
    await addEvent('体检', DateTime(2026, 10, 21, 9));

    final context = await service.buildContext('10月20日有什么安排？');

    expect(context, contains('答辩'));
    expect(context, isNot(contains('体检')));
  });

  test('没有时间关键词时给"今天起 7 天"，并有条数上限', () async {
    for (var i = 0; i < 20; i++) {
      await addEvent('事件 $i', DateTime(2026, 10, 6, 8).add(Duration(hours: i)));
    }

    final context = (await service.buildContext('帮我看看'))!;

    expect(context, contains('共 20 条'));
    expect(context, contains('其余 8 条已省略'));
    // 20 条里最多列 12 条（按列出的行数算，避免与 id 里的标题重复计数）
    final listed = context
        .split('\n')
        .where(
            (String line) => line.startsWith('  - ') && !line.contains('已省略'))
        .length;
    expect(listed, 12);
  });

  test('倒计时：问题提到标题时只带那一条，否则带最近的几条', () async {
    await addCountdown('毕业答辩', DateTime(2026, 10, 19, 15));
    await addCountdown('生日', DateTime(2026, 12, 2, 0));

    final mentioned = (await service.buildContext('距离毕业答辩还有多久？'))!;
    expect(mentioned, contains('毕业答辩'));
    expect(mentioned, isNot(contains('生日')));

    final nearest = (await service.buildContext('最近有什么值得期待的？'))!;
    expect(nearest, contains('毕业答辩'));
    expect(nearest, contains('生日'));
    expect(nearest, contains('还有 13 天'));
  });

  test('总长度受 maxChars 限制（近似 token 控制）', () async {
    for (var i = 0; i < 40; i++) {
      await addEvent(
        '非常长的事件名称用于测试截断 $i',
        DateTime(2026, 10, 6, 6).add(Duration(minutes: 30 * i)),
      );
    }
    final small = ContextService(
      events: events,
      countdowns: countdowns,
      clock: clock,
      maxChars: 500,
    );

    final context = (await small.buildContext('帮我看看'))!;

    expect(context.length, lessThan(600));
    expect(context, contains('已截断'));
  });

  test('空数据库也能给出上下文（不会抛异常）', () async {
    final context = await service.buildContext('今天有什么安排？');
    expect(context, contains('没有日程'));
  });
}
