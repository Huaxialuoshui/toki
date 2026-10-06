import '../../../core/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/calendar_event.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../../calendar/calendar_actions.dart';
import 'ai_tool.dart';

/// 日历相关工具：查询 / 创建 / 修改 / 删除。
///
/// 写操作统一走 [CalendarActions]，与界面共享同一套逻辑（含提醒行同步）。
List<AiTool> buildCalendarTools({
  required CalendarRepository events,
  required CalendarActions actions,
  required Clock clock,
}) {
  Map<String, Object?> eventToJson(CalendarEvent event) => <String, Object?>{
        'id': event.id,
        'title': event.title,
        'start_time': isoWithOffset(event.startTime),
        'end_time': isoWithOffset(event.endTime),
        'all_day': event.allDay,
        if (event.location != null) 'location': event.location,
        if (event.description != null) 'description': event.description,
        if (event.reminderMinutes != null)
          'reminder_minutes': event.reminderMinutes,
      };

  Future<List<CalendarEvent>> eventsInRange(
    DateTime from,
    DateTime to,
  ) async {
    final all = await events.getAll();
    return all
        .where(
          (CalendarEvent event) =>
              event.startTime.isBefore(to) && !event.endTime.isBefore(from),
        )
        .toList(growable: false)
      ..sort((CalendarEvent a, CalendarEvent b) =>
          a.startTime.compareTo(b.startTime));
  }

  return <AiTool>[
    SimpleAiTool(
      name: 'get_today_events',
      description: '查询今天的日程安排。',
      category: AiToolCategory.read,
      parameters: _schema(),
      handler: (Map<String, Object?> args) async {
        final now = clock.now();
        final start = DateTime(now.year, now.month, now.day);
        final list = await eventsInRange(
          start,
          start.add(const Duration(days: 1)),
        );
        return AiToolResult.success(<String, Object?>{
          'date': isoWithOffset(start),
          'count': list.length,
          'events': list.map(eventToJson).toList(growable: false),
        });
      },
    ),
    SimpleAiTool(
      name: 'get_events',
      description:
          '查询指定时间范围内的日程。不传范围时默认返回未来 7 天。时间格式为 ISO-8601，例如 2026-10-20T00:00:00。',
      category: AiToolCategory.read,
      parameters: _schema(
        properties: <String, Object?>{
          'from': _stringSchema('范围开始时间（ISO-8601）'),
          'to': _stringSchema('范围结束时间（ISO-8601）'),
        },
      ),
      handler: (Map<String, Object?> args) async {
        final now = clock.now();
        final from = args.optionalDateTime('from') ?? now;
        final to = args.optionalDateTime('to') ?? from.add(const Duration(days: 7));
        if (!to.isAfter(from)) {
          return const AiToolResult.failure(
            'to 必须晚于 from（请使用 ISO-8601 时间）',
          );
        }
        final list = await eventsInRange(from, to);
        return AiToolResult.success(<String, Object?>{
          'from': isoWithOffset(from),
          'to': isoWithOffset(to),
          'count': list.length,
          'events': list.map(eventToJson).toList(growable: false),
        });
      },
    ),
    SimpleAiTool(
      name: 'search_events',
      description: '按关键词搜索日程（匹配标题、描述、地点）。',
      category: AiToolCategory.read,
      parameters: _schema(
        properties: <String, Object?>{
          'query': _stringSchema('关键词'),
        },
        required: <String>['query'],
      ),
      handler: (Map<String, Object?> args) async {
        final query = args.requiredString('query');
        if (query == null) {
          return const AiToolResult.failure('缺少参数 query');
        }
        final keyword = query.toLowerCase();
        final all = await events.getAll();
        final matches = all.where((CalendarEvent event) {
          return event.title.toLowerCase().contains(keyword) ||
              (event.description ?? '').toLowerCase().contains(keyword) ||
              (event.location ?? '').toLowerCase().contains(keyword);
        }).toList(growable: false);
        return AiToolResult.success(<String, Object?>{
          'query': query,
          'count': matches.length,
          'events': matches.map(eventToJson).toList(growable: false),
        });
      },
    ),
    SimpleAiTool(
      name: 'get_calendar_summary',
      description: '统计某个时间范围内的日程数量与列表，例如"下周有几件事"。',
      category: AiToolCategory.read,
      parameters: _schema(
        properties: <String, Object?>{
          'from': _stringSchema('范围开始时间（ISO-8601）'),
          'to': _stringSchema('范围结束时间（ISO-8601）'),
        },
      ),
      handler: (Map<String, Object?> args) async {
        final now = clock.now();
        final from = args.optionalDateTime('from') ?? now;
        final to = args.optionalDateTime('to') ?? from.add(const Duration(days: 7));
        final list = await eventsInRange(from, to);
        return AiToolResult.success(<String, Object?>{
          'from': isoWithOffset(from),
          'to': isoWithOffset(to),
          'count': list.length,
          'titles': list.map((CalendarEvent event) => event.title).toList(),
        });
      },
    ),
    SimpleAiTool(
      name: 'create_event',
      description:
          '创建日程。start_time 必须是明确的 ISO-8601 时间（例如 2026-10-20T15:00:00）；如果用户只说"明天下午"这类模糊时间，请先按当前时间推算或向用户确认。reminder_minutes 可选，表示提前多少分钟提醒。',
      category: AiToolCategory.create,
      parameters: _schema(
        properties: <String, Object?>{
          'title': _stringSchema('日程标题'),
          'start_time': _stringSchema('开始时间（ISO-8601）'),
          'end_time': _stringSchema('结束时间（ISO-8601），可选'),
          'all_day': <String, Object?>{
            'type': 'boolean',
            'description': '是否全天事件',
          },
          'location': _stringSchema('地点，可选'),
          'description': _stringSchema('备注，可选'),
          'reminder_minutes': <String, Object?>{
            'type': 'integer',
            'description': '提前提醒的分钟数，可选',
          },
        },
        required: <String>['title', 'start_time'],
      ),
      handler: (Map<String, Object?> args) async {
        final title = args.requiredString('title');
        if (title == null) return const AiToolResult.failure('缺少参数 title');

        final start = args.optionalDateTime('start_time');
        if (start == null) {
          return const AiToolResult.failure(
            'start_time 必须是 ISO-8601 时间，例如 2026-10-20T15:00:00',
          );
        }
        final allDay = args.optionalBool('all_day');
        final end = args.optionalDateTime('end_time') ??
            (allDay
                ? DateTime(start.year, start.month, start.day)
                    .add(const Duration(days: 1))
                : start.add(const Duration(hours: 1)));
        if (!end.isAfter(start)) {
          return const AiToolResult.failure('end_time 必须晚于 start_time');
        }

        final now = clock.now();
        final event = CalendarEvent(
          id: generateId('event', now: now),
          title: title,
          description: args.optionalString('description'),
          startTime: start,
          endTime: end,
          allDay: allDay,
          location: args.optionalString('location'),
          reminderMinutes: args.optionalInt('reminder_minutes'),
          createdAt: now,
          updatedAt: now,
        );
        await actions.saveEvent(event);
        return AiToolResult.success(eventToJson(event));
      },
    ),
    SimpleAiTool(
      name: 'update_event',
      description: '修改已有日程。需要 event_id；可以只传要改的字段。',
      category: AiToolCategory.update,
      parameters: _schema(
        properties: <String, Object?>{
          'event_id': _stringSchema('日程 id'),
          'title': _stringSchema('新标题'),
          'start_time': _stringSchema('新开始时间（ISO-8601）'),
          'end_time': _stringSchema('新结束时间（ISO-8601）'),
          'location': _stringSchema('新地点'),
          'description': _stringSchema('新备注'),
          'reminder_minutes': <String, Object?>{
            'type': 'integer',
            'description': '新的提前提醒分钟数；传 0 表示不提醒',
          },
        },
        required: <String>['event_id'],
      ),
      confirm: true,
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('event_id');
        if (id == null) return const AiToolResult.failure('缺少参数 event_id');

        final existing = await events.findById(id);
        if (existing == null) {
          return AiToolResult.failure('没有找到 id=$id 的日程');
        }

        final start = args.optionalDateTime('start_time') ?? existing.startTime;
        final end = args.optionalDateTime('end_time') ??
            (args.optionalDateTime('start_time') == null
                ? existing.endTime
                : start.add(existing.endTime.difference(existing.startTime)));
        if (!end.isAfter(start)) {
          return const AiToolResult.failure('end_time 必须晚于 start_time');
        }

        final reminderMinutes = args.containsKey('reminder_minutes')
            ? args.optionalInt('reminder_minutes')
            : existing.reminderMinutes;

        final updated = existing.copyWith(
          title: args.optionalString('title'),
          description: args.optionalString('description'),
          startTime: start,
          endTime: end,
          location: args.optionalString('location'),
          reminderMinutes: reminderMinutes,
          updatedAt: clock.now(),
        );
        await actions.saveEvent(updated);
        return AiToolResult.success(eventToJson(updated));
      },
    ),
    SimpleAiTool(
      name: 'delete_event',
      description: '删除一个日程（会连带删除它的提醒）。这是危险操作，需要用户确认。',
      category: AiToolCategory.delete,
      parameters: _schema(
        properties: <String, Object?>{
          'event_id': _stringSchema('日程 id'),
        },
        required: <String>['event_id'],
      ),
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('event_id');
        if (id == null) return const AiToolResult.failure('缺少参数 event_id');

        final existing = await events.findById(id);
        if (existing == null) {
          return AiToolResult.failure('没有找到 id=$id 的日程');
        }
        await actions.deleteEvent(id);
        return AiToolResult.success(<String, Object?>{
          'deleted': true,
          'id': id,
          'title': existing.title,
        });
      },
    ),
  ];
}

Map<String, Object?> _schema({
  Map<String, Object?> properties = const <String, Object?>{},
  List<String> required = const <String>[],
}) {
  return <String, Object?>{
    'type': 'object',
    'properties': properties,
    if (required.isNotEmpty) 'required': required,
  };
}

Map<String, Object?> _stringSchema(String description) => <String, Object?>{
      'type': 'string',
      'description': description,
    };
