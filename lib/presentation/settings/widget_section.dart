import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/widget/widget_controller.dart';
import '../../application/device/device_providers.dart';
import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/widget_config.dart';
import '../../infrastructure/device/device_channel.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「桌面小组件」区块（Android）。
///
/// 皮肤（纯色 / 渐变 / 图片）、图标风格、背景图片、圆角、配色、显示内容，
/// 以及后台保活（电池优化白名单 + 可选的常驻服务）都在这里。
class WidgetSection extends ConsumerStatefulWidget {
  const WidgetSection({super.key});

  @override
  ConsumerState<WidgetSection> createState() => _WidgetSectionState();
}

class _WidgetSectionState extends ConsumerState<WidgetSection> {
  bool _backgroundService = false;
  bool _busy = false;

  DeviceChannel get _device => ref.read(deviceChannelProvider);

  @override
  void initState() {
    super.initState();
    _loadNativeState();
  }

  Future<void> _loadNativeState() async {
    final enabled = await _device.isBackgroundServiceEnabled();
    if (!mounted) return;
    setState(() => _backgroundService = enabled);
  }

  WidgetConfig get _config => ref.read(widgetConfigProvider);

  Future<void> _update(WidgetConfig next) =>
      ref.read(widgetConfigProvider.notifier).update(next);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final config = ref.watch(widgetConfigProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.widgetSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 12),
          _Label(l10n.widgetBackground),
          SegmentedButton<WidgetSkin>(
            segments: <ButtonSegment<WidgetSkin>>[
              ButtonSegment<WidgetSkin>(
                value: WidgetSkin.solid,
                label: Text(l10n.widgetSkinSolid),
              ),
              ButtonSegment<WidgetSkin>(
                value: WidgetSkin.gradient,
                label: Text(l10n.widgetSkinGradient),
              ),
              ButtonSegment<WidgetSkin>(
                value: WidgetSkin.image,
                label: Text(l10n.widgetSkinImage),
              ),
            ],
            selected: <WidgetSkin>{config.skin},
            onSelectionChanged: (Set<WidgetSkin> selection) =>
                _update(config.copyWith(skin: selection.first)),
          ),
          const SizedBox(height: 10),
          if (config.skin == WidgetSkin.solid) ...<Widget>[
            _Label(l10n.widgetBackground),
            _SwatchRow(
              fieldKey: 'widget-bg',
              value: config.backgroundColor,
              onPick: (int color) =>
                  _update(config.copyWith(backgroundColor: color)),
            ),
          ],
          if (config.skin == WidgetSkin.gradient) ...<Widget>[
            _Label(l10n.widgetSkinGradient),
            _SwatchRow(
              fieldKey: 'widget-grad-start',
              value: config.gradientStart,
              onPick: (int color) =>
                  _update(config.copyWith(gradientStart: color)),
            ),
            const SizedBox(height: 6),
            _SwatchRow(
              fieldKey: 'widget-grad-end',
              value: config.gradientEnd,
              onPick: (int color) =>
                  _update(config.copyWith(gradientEnd: color)),
            ),
          ],
          if (config.skin == WidgetSkin.image) ...<Widget>[
            _Label(l10n.widgetBackgroundImage),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  key: const ValueKey<String>('widget-pick-image'),
                  onPressed: _busy ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(l10n.widgetPickImage),
                ),
                if ((config.imagePath ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _update(config.copyWith(clearImage: true)),
                    child: Text(l10n.widgetClearImage),
                  ),
                ],
              ],
            ),
            if ((config.imagePath ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  config.imagePath!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          const SizedBox(height: 12),
          _Label(l10n.widgetTextColor),
          _SwatchRow(
            fieldKey: 'widget-text',
            value: config.textColor,
            onPick: (int color) => _update(config.copyWith(textColor: color)),
          ),
          const SizedBox(height: 6),
          _Label(l10n.widgetAccentColor),
          _SwatchRow(
            fieldKey: 'widget-accent',
            value: config.accentColor,
            onPick: (int color) => _update(config.copyWith(accentColor: color)),
          ),
          const SizedBox(height: 10),
          _Label(l10n.widgetIconStyle),
          SegmentedButton<WidgetIconStyle>(
            segments: <ButtonSegment<WidgetIconStyle>>[
              ButtonSegment<WidgetIconStyle>(
                value: WidgetIconStyle.outlined,
                label: Text(l10n.widgetIconOutlined),
              ),
              ButtonSegment<WidgetIconStyle>(
                value: WidgetIconStyle.filled,
                label: Text(l10n.widgetIconFilled),
              ),
            ],
            selected: <WidgetIconStyle>{config.iconStyle},
            onSelectionChanged: (Set<WidgetIconStyle> selection) =>
                _update(config.copyWith(iconStyle: selection.first)),
          ),
          const SizedBox(height: 8),
          _Label(
            '${l10n.widgetCornerRadius} · ${config.cornerRadius}',
          ),
          Slider(
            value: config.cornerRadius.toDouble(),
            min: 0,
            max: 48,
            divisions: 24,
            onChanged: (double value) =>
                _update(config.copyWith(cornerRadius: value.round())),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.widgetTransparent),
            value: config.transparent,
            onChanged: (bool value) =>
                _update(config.copyWith(transparent: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.widgetShowCountdown),
            value: config.showCountdown,
            onChanged: (bool value) =>
                _update(config.copyWith(showCountdown: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.widgetShowEvent),
            value: config.showEvent,
            onChanged: (bool value) =>
                _update(config.copyWith(showEvent: value)),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                key: const ValueKey<String>('widget-pin'),
                onPressed: _busy ? null : _pinWidget,
                icon: const Icon(Icons.add_to_home_screen, size: 18),
                label: Text(l10n.widgetAddToHome),
              ),
              OutlinedButton.icon(
                key: const ValueKey<String>('widget-refresh-now'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await ref.read(widgetPublisherProvider).publish();
                  if (!mounted) return;
                  messenger?.showSnackBar(
                    SnackBar(content: Text(l10n.widgetRefreshed)),
                  );
                },
                icon: const Icon(Icons.sync, size: 18),
                label: Text(l10n.widgetRefreshNow),
              ),
            ],
          ),
          const Divider(height: 28),
          Text(
            l10n.widgetBackgroundServiceHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SwitchListTile(
            key: const ValueKey<String>('widget-background-service'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.widgetBackgroundService),
            value: _backgroundService,
            onChanged: _busy ? null : _toggleBackgroundService,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('widget-battery-optimization'),
              onPressed: _busy ? null : _requestBatteryOptimization,
              icon: const Icon(Icons.battery_charging_full_outlined, size: 18),
              label: Text(l10n.widgetBatteryOptimization),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.widgetBatteryOptimizationHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pinWidget() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await _device.requestPinWidget();
    if (!mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.widgetAddToHomeHint)),
    );
  }

  Future<void> _pickImage() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      // 复制到应用私有目录：小组件进程需要长期稳定的路径。
      final copied = await _device.copyWidgetBackground(file.path);
      await _update(_config.copyWith(imagePath: copied ?? file.path));
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(l10n.widgetRefreshed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBackgroundService(bool enabled) async {
    setState(() => _busy = true);
    final actual = await _device.setBackgroundService(enabled);
    if (!mounted) return;
    setState(() {
      _backgroundService = actual;
      _busy = false;
    });
  }

  Future<void> _requestBatteryOptimization() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final already = await _device.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() => _busy = true);
    if (!already) {
      await _device.requestIgnoreBatteryOptimizations();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.widgetBatteryOptimizationDone)),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

/// 一行色板：从主题色板里选，也允许纯黑 / 纯白。
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.fieldKey,
    required this.value,
    required this.onPick,
  });

  final String fieldKey;
  final int value;
  final ValueChanged<int> onPick;

  static int argb(Color color) =>
      ((color.a * 255).round() << 24) |
      ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = <Color>[
      const Color(0xFF171A24),
      const Color(0xFF10131C),
      const Color(0xFFFFFFFF),
      ...EventPalette.colors,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (int index, Color color) in colors.indexed)
          InkWell(
            key: ValueKey<String>('$fieldKey-$index'),
            onTap: () => onPick(argb(color)),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: argb(color) == value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  width: argb(color) == value ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
