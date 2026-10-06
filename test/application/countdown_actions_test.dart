import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/countdown/countdown_actions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_countdown_repository.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCountdownRepository repository;
  late CountdownActions actions;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftCountdownRepository(database, clock: clock);
    actions = CountdownActions(repository: repository, clock: clock);
  });

  tearDown(() => database.close());

  test('创建：自动生成 id、时间戳，并排在列表末尾', () async {
    final first = await actions.create(
      title: '毕业答辩',
      targetTime: DateTime(2026, 10, 19, 15),
      color: const Color(0xFF5A6BF0),
      displayStyle: CountdownDisplayStyle.bigNumber,
      isPinned: true,
    );
    final second = await actions.create(
      title: '生日',
      targetTime: DateTime(2026, 12, 2, 0),
    );

    expect(first.id, startsWith('countdown-'));
    expect(first.sortOrder, 0);
    expect(second.sortOrder, 1);
    expect(first.isPinned, isTrue);
    expect(second.displayStyle, CountdownDisplayStyle.fullText);

    final stored = (await repository.findById(first.id))!;
    expect(stored.title, '毕业答辩');
    expect(stored.targetTime, DateTime(2026, 10, 19, 15));
    expect(stored.createdAt, clock.now());
    expect(await repository.count(), 2);
  });

  test('更新：保留 id 与 createdAt', () async {
    final created = await actions.create(
      title: '旧标题',
      targetTime: DateTime(2026, 10, 19, 15),
    );

    clock.advance(const Duration(days: 2));
    await actions.update(created.copyWith(title: '新标题'));

    final stored = (await repository.findById(created.id))!;
    expect(stored.title, '新标题');
    expect(stored.createdAt, created.createdAt);
    expect(stored.updatedAt.isAfter(stored.createdAt), isTrue);
  });

  test('置顶 / 取消置顶会在分组之间移动', () async {
    final pinned = await actions.create(
      title: '置顶项',
      targetTime: DateTime(2026, 11, 1),
      isPinned: true,
    );
    final normal = await actions.create(
      title: '普通项',
      targetTime: DateTime(2026, 11, 2),
    );

    expect(
      (await repository.watchPinned().first).map((CountdownItem i) => i.id),
      <String>[pinned.id],
    );

    await actions.setPinned(id: normal.id, isPinned: true);
    final pinnedIds = (await repository.watchPinned().first)
        .map((CountdownItem i) => i.id)
        .toSet();
    expect(pinnedIds, <String>{pinned.id, normal.id});

    await actions.setPinned(id: pinned.id, isPinned: false);
    expect(
      (await repository.watchPinned().first).map((CountdownItem i) => i.id),
      <String>[normal.id],
    );
  });

  test('拖动排序：写回顺序后列表按新顺序返回', () async {
    final a =
        await actions.create(title: 'A', targetTime: DateTime(2026, 11, 1));
    final b =
        await actions.create(title: 'B', targetTime: DateTime(2026, 11, 2));
    final c =
        await actions.create(title: 'C', targetTime: DateTime(2026, 11, 3));

    await actions.reorder(<String>[c.id, a.id, b.id]);

    expect(
      (await repository.getAll()).map((CountdownItem item) => item.id),
      <String>[c.id, a.id, b.id],
    );
  });

  test('删除', () async {
    final created = await actions.create(
      title: '待删除',
      targetTime: DateTime(2026, 11, 1),
    );
    await actions.delete(created.id);

    expect(await repository.findById(created.id), isNull);
    expect(await repository.count(), 0);
  });
}
