import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/device/device_providers.dart';
import '../../core/extensions/l10n_extension.dart';

/// 「用系统工具编辑」按钮：背景 / 头像 / 应用图标 / 小组件背景共用。
///
/// * Android：拉起 `ACTION_EDIT`（相册 / 文件管理器自带的编辑功能）；
/// * Windows：打开系统画图；
/// * 编辑结果一定落在**新路径**上，所以调用方只要换掉配置里的路径就行。
class ImageEditButton extends ConsumerStatefulWidget {
  const ImageEditButton({
    super.key,
    required this.path,
    required this.onEdited,
    this.keyPrefix = 'edit',
  });

  /// 当前图片路径；`null`、URL 或不存在的本机文件都会把按钮置灰。
  final String? path;

  /// 编辑成功且内容有变化时回调（参数是新的图片路径）。
  final ValueChanged<String> onEdited;

  /// 测试定位用的 key 前缀。
  final String keyPrefix;

  @override
  ConsumerState<ImageEditButton> createState() => _ImageEditButtonState();
}

class _ImageEditButtonState extends ConsumerState<ImageEditButton> {
  bool _busy = false;

  bool get _enabled {
    final value = widget.path?.trim() ?? '';
    if (value.isEmpty) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return false;
    }
    return true;
  }

  Future<void> _edit() async {
    final path = widget.path?.trim();
    if (path == null || path.isEmpty) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    final outcome = await ref.read(imageEditServiceProvider).edit(path);
    if (!mounted) return;
    setState(() => _busy = false);

    if (!outcome.ok) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('${l10n.editImageFailed}：${outcome.error}'),
        ),
      );
      return;
    }
    if (!outcome.changed || outcome.path == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.editImageUnchanged)),
      );
      return;
    }
    widget.onEdited(outcome.path!);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.editImageDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OutlinedButton.icon(
      key: ValueKey<String>('${widget.keyPrefix}-edit-image'),
      onPressed: (_busy || !_enabled) ? null : _edit,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.brush_outlined, size: 18),
      label: Text(l10n.editImage),
    );
  }
}
