import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/tasks/task_actions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/errors/task_exception.dart';
import 'package:toki/data/repositories/drift_task_repository.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftTaskRepository repository;
  late TaskActions actions;
  late FixedClock clock;

  setUp(() {
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 18, 9));
    repository = DriftTaskRepository(database);
    actions = TaskActions(repository: repository, clock: clock);
  });

  tearDown(() => database.close());

  test('创建任务：校验标题与耗时，默认 open / manual', () async {
    final task = await actions.create(
      title: '  整理资料  ',
      estimatedMinutes: 30,
      dueAt: DateTime(2026, 10, 18, 18),
    );

    expect(task.title, '整理资料');
    expect(task.status, TaskStatus.open);
    expect(task.source, TaskSource.manual);
    expect(task.postponeCount, 0);
    expect((await repository.findById(task.id))!.id, task.id);

    await expectLater(
      actions.create(title: '   '),
      throwsA(
        isA<TaskException>().having(
          (TaskException e) => e.code,
          'code',
          TaskErrorCode.emptyTitle,
        ),
      ),
    );
    await expectLater(
      actions.create(title: '任务', estimatedMinutes: -1),
      throwsA(
        isA<TaskException>().having(
          (TaskException e) => e.code,
          'code',
          TaskErrorCode.invalidEstimatedMinutes,
        ),
      ),
    );
  });

  test('完成与撤销完成同步 completedAt / actualMinutes', () async {
    final task = await actions.create(title: '写文档');
    clock.advance(const Duration(hours: 2));

    final completed = await actions.complete(
      task.id,
      actualMinutes: 80,
      completionNote: '完成初稿',
    );
    expect(completed.status, TaskStatus.completed);
    expect(completed.completedAt, clock.now());
    expect(completed.actualMinutes, 80);
    expect(completed.completionNote, '完成初稿');

    final reopened = await actions.uncomplete(task.id);
    expect(reopened.status, TaskStatus.open);
    expect(reopened.completedAt, null);
    expect(reopened.actualMinutes, null);
    expect(reopened.completionNote, null);
  });

  test('阻塞 / 恢复、延后与软归档', () async {
    final task = await actions.create(
      title: '复习',
      dueAt: DateTime(2026, 10, 18, 20),
    );

    final blocked = await actions.setBlocked(task.id, true);
    expect(blocked.status, TaskStatus.blocked);
    final resumed = await actions.setBlocked(task.id, false);
    expect(resumed.status, TaskStatus.open);

    final postponed = await actions.postpone(
      task.id,
      DateTime(2026, 10, 19),
    );
    expect(postponed.dueAt, DateTime(2026, 10, 19, 20));
    expect(postponed.postponeCount, 1);
    expect(postponed.lastPostponedAt, clock.now());

    final archived = await actions.archive(task.id);
    expect(archived.isArchived, isTrue);
    final restored = await actions.restore(task.id);
    expect(restored.isArchived, isFalse);
  });

  test('没有截止时间的任务延期不虚构时间', () async {
    final task = await actions.create(title: '无截止任务');
    final postponed = await actions.postpone(
      task.id,
      DateTime(2026, 10, 19),
    );
    expect(postponed.dueAt, null);
    expect(postponed.postponeCount, 1);
  });

  test('任务不存在时返回明确错误', () async {
    await expectLater(
      actions.complete('missing'),
      throwsA(
        isA<TaskException>().having(
          (TaskException e) => e.code,
          'code',
          TaskErrorCode.notFound,
        ),
      ),
    );
  });
}
