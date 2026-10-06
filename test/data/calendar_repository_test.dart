import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/domain/entities/calendar_category.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository repository;
  late DriftCalendarCategoryRepository categoryRepository;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  CalendarEvent buildEvent({
    required String id,
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    String title = '事件',
    String? categoryId,
    Color color = const Color(0xFF5A6BF0),
    int? reminderMinutes,
  }) {
    return CalendarEvent(
      id: id,
      title: title,
      startTime: start,
      endTime: start.add(duration),
      categoryId: categoryId,
      color: color,
      reminderMinutes: reminderMinutes,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftCalendarRepository(database, clock: clock);
    categoryRepository = DriftCalendarCategoryRepository(database);
  });

  tearDown(() => database.close());

  test('创建 / 读取 / 更新 / 删除', () async {
    await repository.upsert(
      buildEvent(id: 'e1', start: DateTime(2026, 10, 6, 15), title: '答辩'),
    );
    expect(await repository.count(), 1);

    final loaded = await repository.findById('e1');
    expect(loaded, isNotNull);
    expect(loaded!.title, '答辩');
    expect(loaded.startTime, DateTime(2026, 10, 6, 15));
    expect(loaded.color, const Color(0xFF5A6BF0));

    await repository.upsert(
      buildEvent(id: 'e1', start: DateTime(2026, 10, 6, 16), title: '答辩（改）'),
    );
    expect(await repository.count(), 1, reason: '同一 id 应该是更新而不是插入');
    expect((await repository.findById('e1'))!.title, '答辩（改）');

    await repository.deleteById('e1');
    expect(await repository.count(), 0);
    expect(await repository.findById('e1'), isNull);
  });

  test('watchRange 只返回与区间相交的事件（含跨天事件）', () async {
    await repository.upsertAll(<CalendarEvent>[
      buildEvent(id: 'before', start: DateTime(2026, 10, 4, 9)),
      buildEvent(id: 'inside', start: DateTime(2026, 10, 6, 15)),
      buildEvent(
        id: 'crossing',
        start: DateTime(2026, 10, 6, 23),
        duration: const Duration(hours: 3),
      ),
      buildEvent(id: 'after', start: DateTime(2026, 10, 9, 9)),
    ]);

    final result = await repository
        .watchRange(
          from: DateTime(2026, 10, 6),
          to: DateTime(2026, 10, 7),
        )
        .first;

    expect(
      result.map((CalendarEvent event) => event.id),
      <String>['inside', 'crossing'],
    );
  });

  test('watchUpcoming 从指定时间开始按开始时间排序并限制条数', () async {
    await repository.upsertAll(<CalendarEvent>[
      buildEvent(id: 'past', start: DateTime(2026, 10, 5, 9)),
      buildEvent(id: 'soon', start: DateTime(2026, 10, 6, 12)),
      buildEvent(id: 'later', start: DateTime(2026, 10, 8, 9)),
      buildEvent(id: 'latest', start: DateTime(2026, 10, 20, 9)),
    ]);

    final result = await repository
        .watchUpcoming(after: DateTime(2026, 10, 6, 10), limit: 2)
        .first;

    expect(
      result.map((CalendarEvent event) => event.id),
      <String>['soon', 'later'],
    );
  });

  test('时间以绝对时刻保存：UTC 写入，按本地时间读回同一瞬间', () async {
    final utcStart = DateTime.utc(2026, 10, 6, 7, 30);
    await repository.upsert(buildEvent(id: 'e-tz', start: utcStart));

    final loaded = (await repository.findById('e-tz'))!;
    expect(loaded.startTime.toUtc(), utcStart);
  });

  test('分类读写与事件外键', () async {
    await categoryRepository.upsert(
      CalendarCategory(
        id: 'cat-1',
        name: '学习',
        color: const Color(0xFF12B5A5),
        sortOrder: 1,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
    await repository.upsert(
      buildEvent(
        id: 'e-cat',
        start: DateTime(2026, 10, 6, 9),
        categoryId: 'cat-1',
      ),
    );

    final categories = await categoryRepository.getAll();
    expect(categories, hasLength(1));
    expect(categories.single.name, '学习');
    expect((await repository.findById('e-cat'))!.categoryId, 'cat-1');
  });

  test('watch 在数据变化后推送新值', () async {
    final emissions = <List<CalendarEvent>>[];
    final subscription = repository.watchAll().listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    await repository.upsert(
      buildEvent(id: 'e-watch', start: DateTime(2026, 10, 6, 11)),
    );
    await pumpEventQueue();

    expect(emissions, isNotEmpty);
    expect(emissions.last.single.id, 'e-watch');
  });
}
