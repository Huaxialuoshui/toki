import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/appearance/app_appearance_providers.dart';
import '../../core/constants/brand_assets.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/nav_icon_config.dart';
import '../../infrastructure/storage/local_image_store.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/background_editor.dart';
import '../widgets/brand_icon.dart';

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
    final autoContrast = ref.watch(appAutoContrastProvider);

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
          SwitchListTile(
            key: const ValueKey<String>('app-auto-contrast'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.appAutoContrast),
            subtitle: Text(
              l10n.appAutoContrastHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: autoContrast,
            onChanged: (bool value) =>
                ref.read(appAutoContrastProvider.notifier).update(value),
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
          const Divider(height: 28),
          const _NavIconsEditor(),
        ],
      ),
    );
  }
}

class _NavIconsEditor extends ConsumerStatefulWidget {
  const _NavIconsEditor();

  @override
  ConsumerState<_NavIconsEditor> createState() => _NavIconsEditorState();
}

class _NavIconsEditorState extends ConsumerState<_NavIconsEditor> {
  String? _busyRoute;

  static const Map<String, (IconData, IconData)> _fallbackIcons =
      <String, (IconData, IconData)>{
    '/home': (Icons.dashboard_outlined, Icons.dashboard),
    '/calendar': (Icons.calendar_month_outlined, Icons.calendar_month),
    '/countdown': (Icons.timer_outlined, Icons.timer),
    '/ai': (Icons.auto_awesome_outlined, Icons.auto_awesome),
    '/settings': (Icons.settings_outlined, Icons.settings),
  };

  Future<void> _pick(String route) async {
    setState(() => _busyRoute = route);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) {
        final saved = await persistPickedImage(file.path);
        await ref.read(navIconProvider.notifier).setPath(route, saved);
      }
    } finally {
      if (mounted) setState(() => _busyRoute = null);
    }
  }

  Future<void> _clear(String route) async {
    await ref.read(navIconProvider.notifier).setPath(route, null);
  }

  bool _isNewPack(NavIconConfig config) =>
      config.paths.isEmpty ||
      NavIconConfig.routes.every(
        (String route) => config.pathFor(route) == null,
      );

  bool _isClassicPack(NavIconConfig config) => NavIconConfig.routes.every(
        (String route) =>
            config.pathFor(route) ==
            BrandAssets.assetValue(
              BrandAssets.classicNavigationIcons[route]!,
            ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final config = ref.watch(navIconProvider);
    final filled = ref.watch(appIconStyleProvider) == AppIconStyle.filled;

    String labelFor(String route) {
      return switch (route) {
        '/home' => l10n.navHome,
        '/calendar' => l10n.navCalendar,
        '/countdown' => l10n.navCountdown,
        '/ai' => l10n.navAi,
        _ => l10n.navSettings,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.navIconSection,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.navIconHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              key: const ValueKey<String>('nav-icon-preset-new'),
              label: Text(l10n.navIconPresetNew),
              selected: _isNewPack(config),
              onSelected: (_) => ref.read(navIconProvider.notifier).clearAll(),
            ),
            ChoiceChip(
              key: const ValueKey<String>('nav-icon-preset-classic'),
              label: Text(l10n.navIconPresetClassic),
              selected: _isClassicPack(config),
              onSelected: (_) =>
                  ref.read(navIconProvider.notifier).useClassicPack(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final route in NavIconConfig.routes)
          _NavIconRow(
            route: route,
            label: labelFor(route),
            path: config.pathFor(route),
            fallbackIcon:
                filled ? _fallbackIcons[route]!.$2 : _fallbackIcons[route]!.$1,
            busy: _busyRoute == route,
            onPick: () => _pick(route),
            onClear: () => _clear(route),
          ),
        if (config.paths.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey<String>('nav-icons-reset-all'),
              onPressed: () => ref.read(navIconProvider.notifier).clearAll(),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l10n.navIconResetAll),
            ),
          ),
      ],
    );
  }
}

class _NavIconRow extends StatelessWidget {
  const _NavIconRow({
    required this.route,
    required this.label,
    required this.path,
    required this.fallbackIcon,
    required this.busy,
    required this.onPick,
    required this.onClear,
  });

  final String route;
  final String label;
  final String? path;
  final IconData fallbackIcon;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            SizedBox.square(
              dimension: 38,
              child: Center(
                child: BrandNavigationIcon(
                  route: route,
                  storedPath: path,
                  fallbackIcon: fallbackIcon,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              key: ValueKey<String>('nav-icon-pick-$route'),
              onPressed: busy ? null : onPick,
              tooltip: l10n.navIconPick,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 20),
            ),
            IconButton(
              key: ValueKey<String>('nav-icon-clear-$route'),
              onPressed: path == null || busy ? null : onClear,
              tooltip: l10n.navIconReset,
              icon: const Icon(Icons.restart_alt, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
