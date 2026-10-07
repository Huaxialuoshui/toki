import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/ai/chat_appearance_controller.dart';
import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/chat_appearance.dart';
import '../../domain/entities/avatar_config.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/chat_background.dart';
import '../widgets/avatar_editor.dart';

/// 设置页的「聊天外观」区块：直接编辑并实时预览（规格 §10 / §12）。
class ChatAppearanceSection extends ConsumerWidget {
  const ChatAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final appearance = ref.watch(chatAppearanceProvider);
    final controller = ref.read(chatAppearanceProvider.notifier);
    final background = appearance.background;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Label(text: l10n.chatBackground),
          SegmentedButton<ChatBackgroundType>(
            segments: <ButtonSegment<ChatBackgroundType>>[
              ButtonSegment<ChatBackgroundType>(
                value: ChatBackgroundType.solid,
                label: Text(l10n.chatBackgroundSolid),
              ),
              ButtonSegment<ChatBackgroundType>(
                value: ChatBackgroundType.gradient,
                label: Text(l10n.chatBackgroundGradient),
              ),
              ButtonSegment<ChatBackgroundType>(
                value: ChatBackgroundType.image,
                label: Text(l10n.chatBackgroundImage),
              ),
            ],
            selected: <ChatBackgroundType>{background.type},
            onSelectionChanged: (Set<ChatBackgroundType> selection) =>
                controller.updateBackground(
              background.copyWith(type: selection.first),
            ),
          ),
          const SizedBox(height: 12),
          if (background.type == ChatBackgroundType.solid) ...<Widget>[
            _Label(text: l10n.chatBackgroundColor),
            _ColorRow(
              selected: background.solidColor,
              onPick: (int color) => controller.updateBackground(
                background.copyWith(solidColor: color),
              ),
            ),
          ],
          if (background.type == ChatBackgroundType.gradient) ...<Widget>[
            _Label(text: l10n.chatGradientColors),
            _ColorRow(
              selected: background.gradientColors.first,
              onPick: (int color) => controller.updateBackground(
                background.copyWith(
                  gradientColors: <int>[color, background.gradientColors.last],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ColorRow(
              selected: background.gradientColors.last,
              onPick: (int color) => controller.updateBackground(
                background.copyWith(
                  gradientColors: <int>[background.gradientColors.first, color],
                ),
              ),
            ),
          ],
          if (background.type == ChatBackgroundType.image) ...<Widget>[
            TextField(
              controller: TextEditingController(text: background.imagePath)
                ..selection = TextSelection.collapsed(
                  offset: (background.imagePath ?? '').length,
                ),
              decoration: InputDecoration(
                labelText: l10n.chatBackgroundImage,
                hintText: l10n.chatBackgroundImageHint,
              ),
              onSubmitted: (String value) => controller.updateBackground(
                background.copyWith(imagePath: value.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (file == null) return;
                    controller.updateBackground(
                      background.copyWith(imagePath: file.path),
                    );
                  },
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(l10n.chatBackgroundPickImage),
                ),
                if (background.hasImage)
                  TextButton(
                    onPressed: () => controller.updateBackground(
                      background.copyWith(clearImage: true),
                    ),
                    child: Text(l10n.chatBackgroundClearImage),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SliderTile(
              label: l10n.chatBackgroundOpacity,
              value: background.imageOpacity,
              min: 0.1,
              max: 1,
              onChanged: (double value) => controller.updateBackground(
                background.copyWith(imageOpacity: value),
              ),
            ),
            _SliderTile(
              label: l10n.chatBackgroundBlur,
              value: background.blurAmount,
              min: 0,
              max: 30,
              onChanged: (double value) => controller.updateBackground(
                background.copyWith(blurAmount: value),
              ),
            ),
          ],
          if (background.type != ChatBackgroundType.solid)
            _SliderTile(
              label: l10n.chatOverlayOpacity,
              value: background.overlayOpacity,
              min: 0,
              max: 1,
              onChanged: (double value) => controller.updateBackground(
                background.copyWith(overlayOpacity: value),
              ),
            ),
          const SizedBox(height: 10),
          _Label(text: l10n.chatUserAvatar),
          Row(
            children: <Widget>[
              AvatarPreview(
                config: AvatarConfig.fromLegacy(
                  appearance.userAvatar,
                  color: appearance.userAvatarColor,
                ),
                radius: 20,
                fallback: '我',
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                key: const ValueKey<String>('chat-avatar-edit'),
                onPressed: () async {
                  final result = await showAvatarEditor(
                    context,
                    initial: AvatarConfig.fromLegacy(
                      appearance.userAvatar,
                      color: appearance.userAvatarColor,
                    ),
                    title: l10n.chatUserAvatar,
                  );
                  if (result == null) return;
                  controller.setUserAvatar(
                    result.isEmpty ? null : result.value,
                  );
                  controller.setUserAvatarColor(result.color);
                },
                icon: const Icon(Icons.face_retouching_natural, size: 18),
                label: Text(l10n.avatarChange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SliderTile(
            label: l10n.chatBubbleOpacity,
            value: appearance.bubbleOpacity,
            min: 0.4,
            max: 1,
            onChanged: controller.setBubbleOpacity,
          ),
          _SliderTile(
            label: l10n.chatBubbleRadius,
            value: appearance.bubbleRadius,
            min: 0,
            max: 32,
            onChanged: controller.setBubbleRadius,
          ),
          _SliderTile(
            label: l10n.chatFontScale,
            value: appearance.fontScale,
            min: 0.85,
            max: 1.4,
            onChanged: controller.setFontScale,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.chatAnimation),
            value: appearance.animationEnabled,
            onChanged: controller.setAnimationEnabled,
          ),
          const SizedBox(height: 6),
          _Label(text: l10n.chatAppearancePreview),
          _Preview(appearance: appearance),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.resetAll,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l10n.chatAppearanceReset),
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.appearance});

  final ChatAppearanceConfig appearance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(appearance.bubbleRadius);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 120,
        child: ChatBackground(
          config: appearance.background,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: appearance.bubbleOpacity,
                    ),
                    borderRadius: radius,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      l10n.chatPreviewMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                            appearance.fontScale,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(
                        alpha: appearance.bubbleOpacity,
                      ),
                      borderRadius: radius,
                    ),
                    child: Text('AI', style: theme.textTheme.labelSmall),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
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

/// 一行颜色选择（复用事件色板 + 透明选项）。
class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.selected, required this.onPick});

  final int selected;
  final ValueChanged<int> onPick;

  static int _argb(Color color) =>
      ((color.a * 255).round() << 24) |
      ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final color in EventPalette.colors)
          InkWell(
            onTap: () => onPick(_argb(color)),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == _argb(color)
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  width: selected == _argb(color) ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
