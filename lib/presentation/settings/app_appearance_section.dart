import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/appearance/app_appearance_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/background_editor.dart';

/// 设置页的「界面外观」：应用背景（含背景图片）+ 图标风格。
///
/// 这两项是**应用级**外观（存在 shared_preferences），和主题编辑器里
/// 的 ThemeConfig 是两类东西：主题管配色，这里管背景图与图标形态。
class AppAppearanceSection extends ConsumerWidget {
  const AppAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final background = ref.watch(appBackgroundProvider);
    final iconStyle = ref.watch(appIconStyleProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.appBackground,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          BackgroundEditor(
            config: background,
            imageKeyPrefix: 'app-bg',
            onChanged: (config) =>
                ref.read(appBackgroundProvider.notifier).update(config),
          ),
          const Divider(height: 28),
          Text(
            l10n.iconStyle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppIconStyle>(
            key: const ValueKey<String>('icon-style'),
            segments: <ButtonSegment<AppIconStyle>>[
              ButtonSegment<AppIconStyle>(
                value: AppIconStyle.outlined,
                label: Text(l10n.iconStyleOutlined),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
              ),
              ButtonSegment<AppIconStyle>(
                value: AppIconStyle.filled,
                label: Text(l10n.iconStyleFilled),
                icon: const Icon(Icons.dashboard, size: 18),
              ),
            ],
            selected: <AppIconStyle>{iconStyle},
            onSelectionChanged: (Set<AppIconStyle> selection) =>
                ref.read(appIconStyleProvider.notifier).update(selection.first),
          ),
        ],
      ),
    );
  }
}
