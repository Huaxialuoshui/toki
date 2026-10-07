import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/daily_digest_service.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/daily_digest.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「AI 每日简报」开关（规格 §14）。
class DigestSection extends ConsumerWidget {
  const DigestSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final service = ref.watch(dailyDigestServiceProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.digestSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            key: const ValueKey<String>('digest-morning'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.digestMorningToggle),
            value: service.isEnabled(DailyDigestKind.morning),
            onChanged: (bool value) async {
              await service.setEnabled(DailyDigestKind.morning, value);
              ref.invalidate(todayDigestProvider);
            },
          ),
          SwitchListTile(
            key: const ValueKey<String>('digest-evening'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.digestEveningToggle),
            value: service.isEnabled(DailyDigestKind.evening),
            onChanged: (bool value) async {
              await service.setEnabled(DailyDigestKind.evening, value);
              ref.invalidate(todayDigestProvider);
            },
          ),
        ],
      ),
    );
  }
}
