import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_countdown_repository.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCountdownRepository repository;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  CountdownItem buildItem({
    required String id,
    required DateTime target,
    String title = '倒计时',
    bool isPinned = false,
    int sortOrder = 0,
    CountdownDisplayStyle style = CountdownDisplayStyle.fullText,
  }) {
    return CountdownItem(
      id: id,
      title: title,
      targetTime: target,
      color: const Color(0xFF5A6BF0),
      isPinned: isPinned,
      displayStyle: style,
      sortOrder: sortOrder,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftCountdownRepository(database, clock: clock);
  });

  tearDown(() => database.close());

  test('创建 / 读取 / 更新 / 删除', () async {
    await repository.upsert(
      buildItem(
        id: 'c1',
        target: DateTime(2026, 10, 19, 15),
        style: CountdownDisplayStyle.bigNumber,
      ),
    );

    final loaded = (await repository.findById('c1'))!;
    expect(loaded.title, '倒计时');
    expect(loaded.targetTime, DateTime(2026, 10, 19, 15));
    expect(loaded.displayStyle, CountdownDisplayStyle.bigNumber);

    await repository.upsert(
      buildItem(id: 'c1', target: DateTime(2026, 10, 20, 15), title: '改名'),
    );
    expect(await repository.count(), 1);
    expect((await repository.findById('c1'))!.title, '改名');

    await repository.deleteById('c1');
    expect(await repository.count(), 0);
  });

  test('置顶与排序：置顶优先，其次 sortOrder', () async {
    await repository.upsertAll(<CountdownItem>[
      buildItem(id: 'a', target: DateTime(2026, 11, 1), sortOrder: 0),
      buildItem(id: 'b', target: DateTime(2026, 11, 2), sortOrder: 1),
      buildItem(
        id: 'c',
        target: DateTime(2026, 11, 3),
        sortOrder: 2,
        isPinned: true,
      ),
    ]);

    var all = await repository.getAll();
    expect(all.map((CountdownItem item) => item.id), <String>['c', 'a', 'b']);

    await repository.setPinned(id: 'b', isPinned: true);
    all = await repository.getAll();
    expect(all.first.isPinned, isTrue);
    expect(
      all.where((CountdownItem item) => item.isPinned).length,
      2,
    );

    final pinned = await repository.watchPinned().first;
    expect(pinned.every((CountdownItem item) => item.isPinned), isTrue);
  });

  test('reorder 写回拖动排序结果', () async {
    await repository.upsertAll(<CountdownItem>[
      buildItem(id: 'a', target: DateTime(2026, 11, 1), sortOrder: 0),
      buildItem(id: 'b', target: DateTime(2026, 11, 2), sortOrder: 1),
      buildItem(id: 'c', target: DateTime(2026, 11, 3), sortOrder: 2),
    ]);

    await repository.reorder(<String>['c', 'a', 'b']);

    final all = await repository.getAll();
    expect(all.map((CountdownItem item) => item.id), <String>['c', 'a', 'b']);
  });
}
