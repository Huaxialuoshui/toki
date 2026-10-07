import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/calendar_options.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/avatar_config.dart';
import 'image_source.dart';

/// 打开头像编辑器；取消时返回 null。
///
/// 不是"一个输入框"：可以在 **表情 / 文字（带底色）/ 图片** 之间选，
/// 图片既能从相册选，也能直接填路径或 URL。
Future<AvatarConfig?> showAvatarEditor(
  BuildContext context, {
  required AvatarConfig initial,
  String? title,
}) {
  return showDialog<AvatarConfig>(
    context: context,
    builder: (BuildContext dialogContext) =>
        _AvatarEditorDialog(initial: initial, title: title),
  );
}

/// 头像预览（emoji / 文字 / 图片都能显示）。
class AvatarPreview extends StatelessWidget {
  const AvatarPreview({
    super.key,
    required this.config,
    this.radius = 20,
    this.fallback = '?',
  });

  final AvatarConfig config;
  final double radius;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = config.color == null
        ? theme.colorScheme.primary.withValues(alpha: 0.16)
        : Color(config.color!);
    final text = config.value.trim().isEmpty ? fallback : config.value.trim();
    final image = config.isImage ? resolveImageProvider(config.value) : null;

    if (image != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        foregroundImage: image,
        onForegroundImageError: (_, __) {},
        child: Text(
          fallback,
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        text,
        style: TextStyle(
          fontSize: radius * 0.9,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _AvatarEditorDialog extends StatefulWidget {
  const _AvatarEditorDialog({required this.initial, this.title});

  final AvatarConfig initial;
  final String? title;

  @override
  State<_AvatarEditorDialog> createState() => _AvatarEditorDialogState();
}

class _AvatarEditorDialogState extends State<_AvatarEditorDialog> {
  late AvatarConfig _draft;
  late final TextEditingController _text;
  late final TextEditingController _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _text = TextEditingController(
      text: widget.initial.kind == AvatarKind.image ? '' : widget.initial.value,
    );
    _image = TextEditingController(
      text: widget.initial.kind == AvatarKind.image ? widget.initial.value : '',
    );
  }

  @override
  void dispose() {
    _text.dispose();
    _image.dispose();
    super.dispose();
  }

  void _setKind(AvatarKind kind) {
    setState(() {
      _draft = _draft.copyWith(
        kind: kind,
        value: switch (kind) {
          AvatarKind.emoji =>
            _text.text.trim().isEmpty ? '🙂' : _text.text.trim(),
          AvatarKind.text =>
            _text.text.trim().isEmpty ? '我' : _text.text.trim(),
          AvatarKind.image => _image.text.trim(),
        },
      );
    });
  }

  Future<void> _pickImage() async {
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      _image.text = file.path;
      setState(() {
        _draft = _draft.copyWith(kind: AvatarKind.image, value: file.path);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title ?? l10n.avatarEditorTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(child: AvatarPreview(config: _draft, radius: 32)),
              const SizedBox(height: 14),
              SegmentedButton<AvatarKind>(
                segments: <ButtonSegment<AvatarKind>>[
                  ButtonSegment<AvatarKind>(
                    value: AvatarKind.emoji,
                    label: Text(l10n.avatarKindEmoji),
                  ),
                  ButtonSegment<AvatarKind>(
                    value: AvatarKind.text,
                    label: Text(l10n.avatarKindText),
                  ),
                  ButtonSegment<AvatarKind>(
                    value: AvatarKind.image,
                    label: Text(l10n.avatarKindImage),
                  ),
                ],
                selected: <AvatarKind>{_draft.kind},
                onSelectionChanged: (Set<AvatarKind> selection) =>
                    _setKind(selection.first),
              ),
              const SizedBox(height: 14),
              if (_draft.kind == AvatarKind.emoji) ...<Widget>[
                Text(
                  l10n.avatarPickEmoji,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final (int index, String emoji)
                        in kAvatarEmojis.indexed)
                      InkWell(
                        key: ValueKey<String>('avatar-emoji-$index'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() {
                          _text.text = emoji;
                          _draft = _draft.copyWith(value: emoji);
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _draft.value == emoji
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                  ],
                ),
              ],
              if (_draft.kind != AvatarKind.image) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('avatar-text'),
                  controller: _text,
                  maxLength: 2,
                  decoration: InputDecoration(
                    labelText: _draft.kind == AvatarKind.emoji
                        ? l10n.avatarEmojiHint
                        : l10n.avatarTextHint,
                  ),
                  onChanged: (String value) =>
                      setState(() => _draft = _draft.copyWith(value: value)),
                ),
              ],
              if (_draft.kind == AvatarKind.image) ...<Widget>[
                Row(
                  children: <Widget>[
                    OutlinedButton.icon(
                      key: const ValueKey<String>('avatar-pick-image'),
                      onPressed: _busy ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(l10n.avatarPickImage),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey<String>('avatar-image-path'),
                  controller: _image,
                  decoration: InputDecoration(
                    labelText: l10n.avatarImageHint,
                  ),
                  onChanged: (String value) =>
                      setState(() => _draft = _draft.copyWith(value: value)),
                ),
              ],
              const SizedBox(height: 6),
              Text(l10n.avatarColor, style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: Text(l10n.calendarColorDefault),
                    selected: _draft.color == null,
                    onSelected: (_) => setState(
                      () => _draft = _draft.copyWith(clearColor: true),
                    ),
                  ),
                  for (final (int index, Color color)
                      in EventPalette.colors.indexed)
                    InkWell(
                      key: ValueKey<String>('avatar-color-$index'),
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(color: _argb(color)),
                      ),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _draft.color == _argb(color)
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.18),
                            width: _draft.color == _argb(color) ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.calendarCancel),
        ),
        if (!widget.initial.isEmpty)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const AvatarConfig(value: '')),
            child: Text(l10n.avatarClear),
          ),
        FilledButton(
          key: const ValueKey<String>('avatar-save'),
          onPressed: () => Navigator.of(context).pop(_draft),
          child: Text(l10n.calendarSave),
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
