import 'package:flutter/material.dart';

import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/calendar_event.dart';
import '../../shared/widgets/glass_card.dart';

/// 日程条目：左侧色条 + 标题 + 时间 / 地点。
class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    this.onTap,
    this.showDate = false,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;

  /// 在标题前显示日期（用于"未来事件"列表）。
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.localeCode;
    final color = event.color ?? theme.colorScheme.primary;

    final timeText = event.allDay
        ? l10n.calendarAllDay
        : '${DateFormats.time(event.startTime, locale)} – '
            '${DateFormats.time(event.endTime, locale)}';

    final details = <String>[
      if (showDate) DateFormats.shortDate(event.startTime, locale),
      timeText,
      if (event.location != null) event.location!,
    ].join(' · ');

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: event.isCancelled
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
          if (event.reminderMinutes != null)
            Icon(
              Icons.notifications_none,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }
}
