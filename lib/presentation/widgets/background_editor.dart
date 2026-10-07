import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/chat_appearance.dart';
import '../../infrastructure/storage/local_image_store.dart';
import 'image_edit_button.dart';

/// 背景配置编辑器：纯色 / 渐变 / 图片 + 透明度 / 模糊 / 遮罩。
///
/// 聊天外观与应用背景共用同一套控件（配置模型也一样）。
class BackgroundEditor extends StatelessWidget {
  const BackgroundEditor({
    super.key,
    required this.config,
    required this.onChanged,
    this.imageKeyPrefix = 'bg',
  });

  final ChatBackgroundConfig config;
  final ValueChanged<ChatBackgroundConfig> onChanged;

  /// 用于测试定位的 key 前缀。
  final String imageKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedButton<ChatBackgroundType>(
          key: ValueKey<String>('$imageKeyPrefix-type'),
          segments: <ButtonSegment<ChatBackgroundType>>[
            ButtonSegment<ChatBackgroundType>(
              value: ChatBackgroundType.solid,
              label: Text(
                l10n.chatBackgroundSolid,
                key: ValueKey<String>('$imageKeyPrefix-type-solid'),
              ),
            ),
            ButtonSegment<ChatBackgroundType>(
              value: ChatBackgroundType.gradient,
              label: Text(
                l10n.chatBackgroundGradient,
                key: ValueKey<String>('$imageKeyPrefix-type-gradient'),
              ),
            ),
            ButtonSegment<ChatBackgroundType>(
              value: ChatBackgroundType.image,
              label: Text(
                l10n.chatBackgroundImage,
                key: ValueKey<String>('$imageKeyPrefix-type-image'),
              ),
            ),
          ],
          selected: <ChatBackgroundType>{config.type},
          onSelectionChanged: (Set<ChatBackgroundType> selection) =>
              onChanged(config.copyWith(type: selection.first)),
        ),
        const SizedBox(height: 12),
        if (config.type == ChatBackgroundType.solid) ...<Widget>[
          _Label(text: l10n.chatBackgroundColor),
          _ColorRow(
            keyPrefix: '$imageKeyPrefix-solid',
            selected: config.solidColor,
            onPick: (int color) =>
                onChanged(config.copyWith(solidColor: color)),
          ),
        ],
        if (config.type == ChatBackgroundType.gradient) ...<Widget>[
          _Label(text: l10n.chatGradientColors),
          _ColorRow(
            keyPrefix: '$imageKeyPrefix-gradient-1',
            selected:
                config.gradientColors.isEmpty ? 0 : config.gradientColors.first,
            onPick: (int color) => onChanged(
              config.copyWith(
                gradientColors: <int>[
                  color,
                  config.gradientColors.length > 1
                      ? config.gradientColors[1]
                      : 0xFF3A2A5A,
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ColorRow(
            keyPrefix: '$imageKeyPrefix-gradient-2',
            selected:
                config.gradientColors.length > 1 ? config.gradientColors[1] : 0,
            onPick: (int color) => onChanged(
              config.copyWith(
                gradientColors: <int>[
                  config.gradientColors.isEmpty
                      ? 0xFF1B2030
                      : config.gradientColors.first,
                  color,
                ],
              ),
            ),
          ),
        ],
        if (config.type == ChatBackgroundType.image) ...<Widget>[
          _Label(text: l10n.chatBackgroundImage),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                key: ValueKey<String>('$imageKeyPrefix-pick'),
                onPressed: () async {
                  final file = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (file == null) return;
                  final saved = await persistPickedImage(file.path);
                  onChanged(config.copyWith(imagePath: saved));
                },
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(l10n.chatBackgroundPickImage),
              ),
              if (config.hasImage) ...<Widget>[
                TextButton(
                  onPressed: () => onChanged(config.copyWith(clearImage: true)),
                  child: Text(l10n.chatBackgroundClearImage),
                ),
              ],
              // 和聊天背景 / 小组件保持一致：图片档里始终有这个按钮（没图时置灰）。
              ImageEditButton(
                keyPrefix: imageKeyPrefix,
                path: config.imagePath,
                onEdited: (String edited) =>
                    onChanged(config.copyWith(imagePath: edited)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey<String>('$imageKeyPrefix-path'),
            controller: TextEditingController(text: config.imagePath ?? '')
              ..selection = TextSelection.collapsed(
                offset: (config.imagePath ?? '').length,
              ),
            decoration: InputDecoration(
              labelText: l10n.widgetBackgroundImage,
              hintText: l10n.chatBackgroundImageHint,
              isDense: true,
            ),
            onSubmitted: (String value) =>
                onChanged(config.copyWith(imagePath: value)),
          ),
          const SizedBox(height: 4),
          _Slider(
            label: l10n.chatBackgroundOpacity,
            value: config.imageOpacity,
            min: 0.1,
            max: 1,
            onChanged: (double value) =>
                onChanged(config.copyWith(imageOpacity: value)),
          ),
        ],
        _Slider(
          label: l10n.chatBackgroundBlur,
          value: config.blurAmount,
          min: 0,
          max: 30,
          onChanged: (double value) =>
              onChanged(config.copyWith(blurAmount: value)),
        ),
        _Slider(
          label: l10n.chatBackgroundOverlay,
          value: config.overlayOpacity,
          min: 0,
          max: 0.8,
          onChanged: (double value) =>
              onChanged(config.copyWith(overlayOpacity: value)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.appBackgroundHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
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

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '$label · ${value.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.keyPrefix,
    required this.selected,
    required this.onPick,
  });

  final String keyPrefix;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = <Color>[
      const Color(0x00000000),
      const Color(0xFFFFFFFF),
      const Color(0xFF0E1016),
      ...EventPalette.colors,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (int index, Color color) in colors.indexed)
          InkWell(
            key: ValueKey<String>('$keyPrefix-$index'),
            onTap: () => onPick(_argb(color)),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _argb(color) == selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  width: _argb(color) == selected ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  static int _argb(Color color) =>
      ((color.a * 255).round() << 24) |
      ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();
}
