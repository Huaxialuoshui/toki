import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/countdown/countdown_controller.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/countdown_item.dart';
import '../../shared/widgets/glass_card.dart';

/// 倒计时卡片。
///
/// 性能约定（规格 §7）：卡片本身只订阅"到分钟"的摘要，秒级刷新被隔离到
/// 叶子组件 [_TickingSeconds] / [_TickingClock]，因此不会出现整页每秒重建。
class CountdownCard extends ConsumerWidget {
  const CountdownCard({
    super.key,
    required this.item,
    this.compact = false,
    this.onTap,
  });

  final CountdownItem item;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.localeCode;
    final provider = countdownRemainingProvider(item.targetTime);
    final summary = ref.watch(
      provider.select((async) => async.valueOrNull?.summary),
    );
    final accent = item.color ?? theme.colorScheme.primary;

    if (summary == null) {
      return const GlassCard(
        child: SizedBox(
          height: 92,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.62);
    final targetText = l10n.countdownTargetAt(
      '${DateFormats.shortDate(item.targetTime, locale)} '
      '${DateFormats.time(item.targetTime, locale)}',
    );

    // 紧凑卡片（首页横向列表）始终用大数字；完整卡片按条目自身的显示样式渲染。
    final useBigNumber =
        compact || item.displayStyle == CountdownDisplayStyle.bigNumber;

    return GlassCard(
      onTap: onTap,
      padding: compact
          ? const EdgeInsets.all(14)
          : const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.isPinned)
                Icon(Icons.push_pin, size: 14, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          if (useBigNumber)
            _CompactReadout(
              item: item,
              accent: accent,
            )
          else
            _FullReadout(
              item: item,
              accent: accent,
              isPast: summary.isPast,
              days: summary.days,
              hours: summary.hours,
              minutes: summary.minutes,
              pastLabel: l10n.countdownTimeSince(item.title),
              untilLabel: l10n.countdownTimeUntil(item.title),
            ),
          const SizedBox(height: 10),
          Text(
            targetText,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _FullReadout extends StatelessWidget {
  const _FullReadout({
    required this.item,
    required this.accent,
    required this.isPast,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.pastLabel,
    required this.untilLabel,
  });

  final CountdownItem item;
  final Color accent;
  final bool isPast;
  final int days;
  final int hours;
  final int minutes;
  final String pastLabel;
  final String untilLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final numberStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: isPast ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : accent,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          isPast ? pastLabel : untilLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: numberStyle,
            children: <InlineSpan>[
              TextSpan(text: '$days${l10n.unitDay} '),
              TextSpan(text: '$hours${l10n.unitHour} '),
              TextSpan(text: '$minutes${l10n.unitMinute} '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: _TickingSeconds(
                  target: item.targetTime,
                  style: numberStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactReadout extends ConsumerWidget {
  const _CompactReadout({
    required this.item,
    required this.accent,
  });

  final CountdownItem item;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // 只订阅到分钟：天数不会因为秒数变化而重建。
    final summary = ref.watch(
      countdownRemainingProvider(item.targetTime)
          .select((async) => async.valueOrNull?.summary),
    );
    final isPast = summary?.isPast ?? false;

    // 卡片宽度由外层决定（首页横向卡片 / 倒计时页网格），这里用 FittedBox
    // 保证窄卡片下不会溢出。
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            '${summary?.days ?? 0}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isPast
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : accent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.unitDayFull,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(width: 12),
          _TickingClock(
            target: item.targetTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// 只订阅秒数：每秒重建的只有这一个小组件。
class _TickingSeconds extends ConsumerWidget {
  const _TickingSeconds({required this.target, required this.style});

  final DateTime target;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final seconds = ref.watch(
      countdownRemainingProvider(target)
          .select((async) => async.valueOrNull?.seconds),
    );
    final text = seconds == null
        ? '--'
        : '${seconds.toString().padLeft(2, '0')}${l10n.unitSecond}';
    return Text(text, style: style);
  }
}

/// 只订阅到秒的 `hh:mm:ss`，用于紧凑样式。
class _TickingClock extends ConsumerWidget {
  const _TickingClock({required this.target, required this.style});

  final DateTime target;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(
      countdownRemainingProvider(target).select((async) => async.valueOrNull),
    );
    if (remaining == null) return const SizedBox.shrink();
    String two(int value) => value.toString().padLeft(2, '0');
    return Text(
      '${two(remaining.hours)}:${two(remaining.minutes)}:${two(remaining.seconds)}',
      style: style,
    );
  }
}
