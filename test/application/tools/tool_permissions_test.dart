import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/ai/tool_permissions.dart';
import 'package:toki/application/ai/tools/ai_tool.dart';
import 'package:toki/application/ai/tools/tool_registry.dart';
import 'package:toki/application/calendar/calendar_actions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_countdown_repository.dart';
import 'package:toki/data/repositories/drift_reminder_repository.dart';
import 'package:toki/domain/entities/ai_persona.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late AiToolRegistry registry;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  setUp(() {
    database = AppDatabase.memory();
    final events = DriftCalendarRepository(database, clock: clock);
    final reminders = DriftReminderRepository(database);
    registry = AiToolRegistry.standard(
      bundle: ToolDependencies(
        calendar: events,
        countdowns: DriftCountdownRepository(database, clock: clock),
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

  List<String> names(ToolPermissions permissions, {AiPersona? persona}) =>
      registry
          .allowedTools(permissions: permissions, persona: persona)
          .map((AiTool tool) => tool.name)
          .toList(growable: false);

  test('默认权限：允许查询/创建/修改，不允许删除', () {
    const permissions = ToolPermissions();

    expect(permissions.allows(AiToolCategory.read), isTrue);
    expect(permissions.allows(AiToolCategory.create), isTrue);
    expect(permissions.allows(AiToolCategory.update), isTrue);
    expect(permissions.allows(AiToolCategory.delete), isFalse);

    final allowed = names(permissions);
    expect(allowed, contains('create_event'));
    expect(allowed, contains('get_today_events'));
    expect(allowed, isNot(contains('delete_event')));
    expect(allowed, isNot(contains('delete_countdown')));
    expect(allowed, isNot(contains('delete_reminder')));
  });

  test('关闭创建权限后，创建类工具不再暴露给模型', () {
    const permissions = ToolPermissions(allowCreate: false);
    final allowed = names(permissions);

    expect(allowed, isNot(contains('create_event')));
    expect(allowed, isNot(contains('create_countdown')));
    expect(allowed, isNot(contains('create_reminder')));
    expect(allowed, contains('update_event'));
  });

  test('打开删除权限后，删除类工具才可用', () {
    const permissions = ToolPermissions(allowDelete: true);
    final allowed = names(permissions);

    expect(
        allowed,
        containsAll(<String>[
          'delete_event',
          'delete_countdown',
          'delete_reminder',
        ]));
  });

  test('人设的 enabledTools 不为空时，只暴露列出的工具', () {
    final persona = AiPersona(
      id: 'p1',
      name: '只读助手',
      enabledTools: const <String>['get_today_events', 'get_countdowns'],
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );

    final allowed = names(const ToolPermissions(), persona: persona);
    expect(allowed, <String>['get_today_events', 'get_countdowns']);
  });

  test('工具定义包含 function 名称与 JSON Schema', () {
    final definitions = registry.definitions(
      permissions: const ToolPermissions(),
    );
    final create = definitions.firstWhere(
      (definition) => definition.name == 'create_event',
    );

    final json = create.toJson();
    final function = json['function']! as Map<String, Object?>;
    expect(function['name'], 'create_event');
    expect((function['parameters']! as Map<String, Object?>)['type'], 'object');
    expect(json['type'], 'function');
  });
}
