import '../../../core/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/countdown_item.dart';
import '../../../domain/entities/countdown_remaining.dart';
import '../../../domain/repositories/countdown_repository.dart';
import 'ai_tool.dart';

/// 倒计时相关工具。
List<AiTool> buildCountdownTools({
  required CountdownRepository countdowns,
  required Clock clock,
}) {
  Map<String, Object?> toJson(CountdownItem item) {
    final remaining = CountdownRemaining.between(
      target: item.targetTime,
      now: clock.now(),
    );
    return <String, Object?>{
      'id': item.id,
      'title': item.title,
      if (item.description != null) 'description': item.description,
      'target_time': isoWithOffset(item.targetTime),
      'is_pinned': item.isPinned,
      'is_past': remaining.isPast,
      'remaining_days': remaining.days,
      'remaining_hours': remaining.hours,
      'remaining_minutes': remaining.minutes,
    };
  }

  return <AiTool>[
    SimpleAiTool(
      name: 'get_countdowns',
      description: '查询所有倒计时，包含距离目标时间还有多久。',
      category: AiToolCategory.read,
      parameters: _object(),
      handler: (Map<String, Object?> args) async {
        final items = await countdowns.getAll();
        return AiToolResult.success(<String, Object?>{
          'count': items.length,
          'countdowns': items.map(toJson).toList(growable: false),
        });
      },
    ),
    SimpleAiTool(
      name: 'create_countdown',
      description:
          '创建倒计时。target_time 必须是明确的 ISO-8601 时间（例如 2026-10-20T15:00:00）。',
      category: AiToolCategory.create,
      parameters: _object(
        properties: <String, Object?>{
          'title': _string('倒计时标题'),
          'target_time': _string('目标时间（ISO-8601）'),
          'description': _string('备注，可选'),
          'is_pinned': <String, Object?>{
            'type': 'boolean',
            'description': '是否置顶',
          },
        },
        required: <String>['title', 'target_time'],
      ),
      handler: (Map<String, Object?> args) async {
        final title = args.requiredString('title');
        if (title == null) return const AiToolResult.failure('缺少参数 title');

        final target = args.optionalDateTime('target_time');
        if (target == null) {
          return const AiToolResult.failure(
            'target_time 必须是 ISO-8601 时间，例如 2026-10-20T15:00:00',
          );
        }

        final now = clock.now();
        final existing = await countdowns.getAll();
        final nextSortOrder = existing.isEmpty
            ? 0
            : existing
                    .map((CountdownItem item) => item.sortOrder)
                    .reduce((int a, int b) => a > b ? a : b) +
                1;
        final item = CountdownItem(
          id: generateId('countdown', now: now),
          title: title,
          targetTime: target,
          description: args.optionalString('description'),
          isPinned: args.optionalBool('is_pinned'),
          sortOrder: nextSortOrder,
          createdAt: now,
          updatedAt: now,
        );
        await countdowns.upsert(item);
        return AiToolResult.success(toJson(item));
      },
    ),
    SimpleAiTool(
      name: 'update_countdown',
      description: '修改已有倒计时（标题 / 目标时间 / 备注 / 是否置顶）。',
      category: AiToolCategory.update,
      parameters: _object(
        properties: <String, Object?>{
          'countdown_id': _string('倒计时 id'),
          'title': _string('新标题'),
          'target_time': _string('新目标时间（ISO-8601）'),
          'description': _string('新备注'),
          'is_pinned': <String, Object?>{
            'type': 'boolean',
            'description': '是否置顶',
          },
        },
        required: <String>['countdown_id'],
      ),
      confirm: true,
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('countdown_id');
        if (id == null) {
          return const AiToolResult.failure('缺少参数 countdown_id');
        }
        final existing = await countdowns.findById(id);
        if (existing == null) {
          return AiToolResult.failure('没有找到 id=$id 的倒计时');
        }

        final target = args.optionalDateTime('target_time');
        if (args.containsKey('target_time') && target == null) {
          return const AiToolResult.failure(
            'target_time 必须是 ISO-8601 时间，例如 2026-10-20T15:00:00',
          );
        }

        final updated = existing.copyWith(
          title: args.optionalString('title'),
          targetTime: target,
          description: args.optionalString('description'),
          isPinned: args.containsKey('is_pinned')
              ? args.optionalBool('is_pinned')
              : null,
          updatedAt: clock.now(),
        );
        await countdowns.upsert(updated);
        return AiToolResult.success(toJson(updated));
      },
    ),
    SimpleAiTool(
      name: 'delete_countdown',
      description: '删除一个倒计时。这是危险操作，需要用户确认。',
      category: AiToolCategory.delete,
      parameters: _object(
        properties: <String, Object?>{
          'countdown_id': _string('倒计时 id'),
        },
        required: <String>['countdown_id'],
      ),
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('countdown_id');
        if (id == null) {
          return const AiToolResult.failure('缺少参数 countdown_id');
        }
        final existing = await countdowns.findById(id);
        if (existing == null) {
          return AiToolResult.failure('没有找到 id=$id 的倒计时');
        }
        await countdowns.deleteById(id);
        return AiToolResult.success(<String, Object?>{
          'deleted': true,
          'id': id,
          'title': existing.title,
        });
      },
    ),
  ];
}

Map<String, Object?> _object({
  Map<String, Object?> properties = const <String, Object?>{},
  List<String> required = const <String>[],
}) =>
    <String, Object?>{
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };

Map<String, Object?> _string(String description) => <String, Object?>{
      'type': 'string',
      'description': description,
    };
