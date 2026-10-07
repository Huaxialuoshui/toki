import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/appearance/app_appearance_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../infrastructure/storage/local_image_store.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/image_edit_button.dart';

/// 设置页的「应用图标」区块：用自己的图片做应用图标。
///
/// Android 与 Windows 能做到的事情不一样，界面上如实写清楚：
/// * Android：换「最近任务」里的图标 + 用 `requestPinShortcut` 生成一个带自定义
///   图标的桌面快捷方式（系统会弹一次确认框）；
/// * Windows：换窗口标题栏 / 任务栏图标；exe 自身的图标是打包资源，需要重新构建。
class AppIconSection extends ConsumerStatefulWidget {
  const AppIconSection({super.key});

  @override
  ConsumerState<AppIconSection> createState() => _AppIconSectionState();
}

class _AppIconSectionState extends ConsumerState<AppIconSection> {
  bool _busy = false;

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    // 相册给的是缓存文件，先搬进应用私有目录再记住路径。
    final saved = await persistPickedImage(file.path);
    await ref.read(appIconProvider.notifier).setPath(saved);
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    final outcome = await ref.read(appIconProvider.notifier).apply();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!outcome.ok) {
      messenger?.showSnackBar(
        SnackBar(content: Text(outcome.error ?? l10n.appIconFailed)),
      );
      return;
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          outcome.shortcut ? l10n.appIconAppliedShortcut : l10n.appIconApplied,
        ),
      ),
    );
  }

  Future<void> _reset() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    await ref.read(appIconProvider.notifier).reset();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.appIconResetDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final path = ref.watch(appIconProvider);
    final hasIcon = path != null && File(path).existsSync();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AppIconPreview(path: hasIcon ? path : null),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.appIcon,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.appIconHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                key: const ValueKey<String>('app-icon-pick'),
                onPressed: _busy ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(l10n.appIconPick),
              ),
              ImageEditButton(
                keyPrefix: 'app-icon',
                path: hasIcon ? path : null,
                onEdited: (String edited) =>
                    ref.read(appIconProvider.notifier).setPath(edited),
              ),
              FilledButton.icon(
                key: const ValueKey<String>('app-icon-apply'),
                onPressed: (_busy || !hasIcon) ? null : _apply,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(l10n.appIconApply),
              ),
              if (hasIcon)
                TextButton(
                  key: const ValueKey<String>('app-icon-reset'),
                  onPressed: _busy ? null : _reset,
                  child: Text(l10n.appIconReset),
                ),
            ],
          ),
          if (hasIcon)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                path,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

/// 图标预览：圆角方形（和启动器的观感接近）。
class _AppIconPreview extends StatelessWidget {
  const _AppIconPreview({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(18);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.event_available, color: Colors.white, size: 28),
      ),
    );

    return SizedBox(
      key: const ValueKey<String>('app-icon-preview'),
      width: 68,
      height: 68,
      child: ClipRRect(
        borderRadius: radius,
        child: path == null
            ? placeholder
            : Image.file(
                File(path!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
