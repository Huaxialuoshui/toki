import '../../../core/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/repositories/reminder_repository.dart';
import 'ai_tool.dart';

/// 提醒相关工具。
List<AiTool> buildReminderTools({
  required ReminderRepository reminders,
  required Clock clock,
}) {
  Map<String, Object?> toJson(Reminder reminder) => <String, Object?>{
        'id': reminder.id,
        'title': reminder.title,
        'trigger_time': isoWithOffset(reminder.triggerTime),
        'enabled': reminder.enabled,
        if (reminder.eventId != null) 'event_id': reminder.eventId,
      };

  return <AiTool>[
    SimpleAiTool(
      name: 'create_reminder',
      description:
          '创建一个独立提醒（trigger_time 必须是 ISO-8601）。如果只是给某个日程加提醒，优先用 create_event/update_event 的 reminder_minutes。',
      category: AiToolCategory.create,
      parameters: <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'title': <String, Object?>{
            'type': 'string',
            'description': '提醒标题',
          },
          'trigger_time': <String, Object?>{
            'type': 'string',
            'description': '触发时间（ISO-8601）',
          },
          'event_id': <String, Object?>{
            'type': 'string',
            'description': '关联的日程 id，可选',
          },
        },
        'required': <String>['title', 'trigger_time'],
      },
      handler: (Map<String, Object?> args) async {
        final title = args.requiredString('title');
        if (title == null) return const AiToolResult.failure('缺少参数 title');

        final trigger = args.optionalDateTime('trigger_time');
        if (trigger == null) {
          return const AiToolResult.failure(
            'trigger_time 必须是 ISO-8601 时间，例如 2026-10-20T14:30:00',
          );
        }

        final reminder = Reminder(
          id: generateId('reminder', now: clock.now()),
          title: title,
          triggerTime: trigger,
          eventId: args.optionalString('event_id'),
          createdAt: clock.now(),
        );
        await reminders.upsert(reminder);
        return AiToolResult.success(toJson(reminder));
      },
    ),
    SimpleAiTool(
      name: 'update_reminder',
      description: '修改提醒（标题 / 触发时间 / 是否启用）。',
      category: AiToolCategory.update,
      parameters: <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'reminder_id': <String, Object?>{
            'type': 'string',
            'description': '提醒 id',
          },
          'title': <String, Object?>{
            'type': 'string',
            'description': '新标题',
          },
          'trigger_time': <String, Object?>{
            'type': 'string',
            'description': '新的触发时间（ISO-8601）',
          },
          'enabled': <String, Object?>{
            'type': 'boolean',
            'description': '是否启用',
          },
        },
        'required': <String>['reminder_id'],
      },
      confirm: true,
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('reminder_id');
        if (id == null) return const AiToolResult.failure('缺少参数 reminder_id');

        final existing = await reminders.findById(id);
        if (existing == null) {
          return AiToolResult.failure('没有找到 id=$id 的提醒');
        }

        final trigger = args.optionalDateTime('trigger_time');
        if (args.containsKey('trigger_time') && trigger == null) {
          return const AiToolResult.failure(
            'trigger_time 必须是 ISO-8601 时间，例如 2026-10-20T14:30:00',
          );
        }

        final updated = existing.copyWith(
          title: args.optionalString('title'),
          triggerTime: trigger,
          enabled: args.containsKey('enabled')
              ? args.optionalBool('enabled', fallback: existing.enabled)
              : null,
        );
        await reminders.upsert(updated);
        return AiToolResult.success(toJson(updated));
      },
    ),
    SimpleAiTool(
      name: 'delete_reminder',
      description: '删除一个提醒。这是危险操作，需要用户确认。',
      category: AiToolCategory.delete,
      parameters: <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'reminder_id': <String, Object?>{
            'type': 'string',
            'description': '提醒 id',
          },
        },
        'required': <String>['reminder_id'],
      },
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('reminder_id');
        if (id == null) return const AiToolResult.failure('缺少参数 reminder_id');

        final existing = await reminders.findById(id);
        if (existing == null) {
          return AiToolResult.failure('没有找到 id=$id 的提醒');
        }
        await reminders.deleteById(id);
        return AiToolResult.success(<String, Object?>{
          'deleted': true,
          'id': id,
          'title': existing.title,
        });
      },
    ),
  ];
}
