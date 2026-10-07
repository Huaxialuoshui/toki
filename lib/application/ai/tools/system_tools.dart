import '../../../core/clock.dart';
import 'ai_tool.dart';

/// 与时间相关的基础工具。
///
/// 规格 §20 要求模型基于"当前时间"推算相对时间，因此必须能拿到准确的现在。
List<AiTool> buildSystemTools({required Clock clock}) {
  return <AiTool>[
    SimpleAiTool(
      name: 'get_current_time',
      description: '获取当前日期与时间（含时区偏移与星期）。推算"明天下午"这类相对时间前必须先调用它。',
      category: AiToolCategory.read,
      parameters: <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{},
      },
      handler: (Map<String, Object?> args) async {
        final now = clock.now();
        const weekdays = <String>[
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        return AiToolResult.success(<String, Object?>{
          'now': isoWithOffset(now),
          'date': '${now.year.toString().padLeft(4, '0')}-'
              '${now.month.toString().padLeft(2, '0')}-'
              '${now.day.toString().padLeft(2, '0')}',
          'time': '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}',
          'weekday': weekdays[now.weekday - 1],
          'utc_offset_minutes': now.timeZoneOffset.inMinutes,
          'timezone': now.timeZoneName,
        });
      },
    ),
  ];
}
