import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/countdown/countdown_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/countdown_item.dart';
import '../widgets/async_hint.dart';
import '../widgets/countdown_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';

/// 倒计时页。
///
/// 数据来自数据库；创建 / 编辑 / 拖动排序在 Phase 4（仓储层的写方法已就绪）。
class CountdownPage extends ConsumerWidget {
  const CountdownPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final countdownsAsync = ref.watch(countdownsProvider);
    final items = countdownsAsync.valueOrNull ?? const <CountdownItem>[];
    final pinned =
        items.where((CountdownItem item) => item.isPinned).toList(growable: false);
    final others =
        items.where((CountdownItem item) => !item.isPinned).toList(growable: false);

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
          final cardWidth = (width - spacing * (columns - 1)) / columns;

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
              if (countdownsAsync.isLoading && items.isEmpty) ...<Widget>[
                SectionHeader(
                  title: l10n.navCountdown,
                  icon: Icons.timelapse_outlined,
                ),
                const LoadingHint(),
              ] else if (items.isEmpty) ...<Widget>[
                SectionHeader(
                  title: l10n.navCountdown,
                  icon: Icons.timelapse_outlined,
                ),
                EmptyHint(
                  text: l10n.countdownEmpty,
                  icon: Icons.timelapse_outlined,
                ),
              ] else ...<Widget>[
                if (pinned.isNotEmpty) ...<Widget>[
                  SectionHeader(
                    title: l10n.countdownPinned,
                    icon: Icons.push_pin_outlined,
                  ),
                  grid(pinned),
                  const SizedBox(height: 24),
                ],
                if (others.isNotEmpty) ...<Widget>[
                  SectionHeader(
                    title: l10n.navCountdown,
                    icon: Icons.timelapse_outlined,
                  ),
                  grid(others),
                ],
              ],
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
