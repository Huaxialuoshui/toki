import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/countdown/countdown_controller.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/countdown_item.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../widgets/countdown_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';

/// 倒计时页。
///
/// Phase 1 只做展示（含实时刷新与两种样式）；创建 / 编辑 / 拖动排序在 Phase 4。
class CountdownPage extends ConsumerWidget {
  const CountdownPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).now();
    final items = buildMockCountdowns(now: now, l10n: l10n);
    final pinned = items.where((item) => item.isPinned).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final others = items.where((item) => !item.isPinned).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return PageScaffold(
      title: l10n.navCountdown,
      subtitle: l10n.appTagline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900
              ? 3
              : width >= 620
                  ? 2
                  : 1;
          const spacing = 12.0;
          final cardWidth =
              (width - spacing * (columns - 1)) / columns;

          Widget grid(List<CountdownItem> list) => Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: <Widget>[
                  for (final item in list)
                    SizedBox(
                      width: cardWidth,
                      child: CountdownCard(item: item),
                    ),
                ],
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (pinned.isNotEmpty) ...<Widget>[
                SectionHeader(
                  title: l10n.countdownPinned,
                  icon: Icons.push_pin_outlined,
                ),
                grid(pinned),
                const SizedBox(height: 24),
              ],
              SectionHeader(
                title: l10n.navCountdown,
                icon: Icons.timelapse_outlined,
              ),
              grid(others),
              const SizedBox(height: 20),
              Text(
                l10n.countdownReadOnlyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
