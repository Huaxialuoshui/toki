import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/backup/backup_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/backup.dart';
import '../../infrastructure/backup/backup_file_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

/// 设置页的「备份与恢复」区块（规格 §12 / Phase 12）。
///
/// * 导出：整库 → 一个 JSON 文件（同时复制到剪贴板，方便手机端取出）；
/// * 恢复：从备份文件或粘贴的 JSON，可选「覆盖」或「合并」；
/// * API Key 默认**不**导出，需要显式打开开关。
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  bool _includeApiKeys = false;
  bool _busy = false;
  String? _directory;
  String? _lastExportPath;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveDirectory());
  }

  Future<void> _resolveDirectory() async {
    try {
      final directory = await ref.read(backupServiceProvider).backupDirectory();
      if (!mounted) return;
      setState(() => _directory = directory.path);
    } on Object {
      // 拿不到目录不影响按钮，导出时会再报一次具体错误。
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.backupIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.backupIncludeApiKeys),
            subtitle: Text(
              l10n.backupIncludeApiKeysHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            value: _includeApiKeys,
            onChanged: _busy
                ? null
                : (bool value) => setState(() => _includeApiKeys = value),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.save_alt_outlined, size: 18),
                label: Text(l10n.backupExport),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restoreFromFile,
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(l10n.backupRestoreFromFile),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restoreFromPaste,
                icon: const Icon(Icons.content_paste_outlined, size: 18),
                label: Text(l10n.backupRestoreFromPaste),
              ),
            ],
          ),
          if (_directory != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              l10n.backupDirectory,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SelectableText(
              _lastExportPath ?? _directory!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _export() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(backupServiceProvider)
          .export(includeApiKeys: _includeApiKeys);
      await Clipboard.setData(ClipboardData(text: result.json));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _lastExportPath = result.file.path;
      });
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.backupExported(result.file.path))),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.backupExportFailed('$error'))),
      );
    }
  }

  Future<void> _restoreFromFile() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final service = ref.read(backupServiceProvider);

    setState(() => _busy = true);
    final List<BackupFileInfo> files;
    try {
      files = await service.listFiles();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.backupExportFailed('$error'))),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (files.isEmpty) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.backupNoFiles)));
      return;
    }

    final info = await showDialog<BackupFileInfo>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.backupFileListTitle),
        content: SizedBox(
          width: 460,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (BuildContext context, int index) {
              final file = files[index];
              return ListTile(
                key: ValueKey<String>('backup-file-${file.name}'),
                dense: true,
                leading: const Icon(Icons.description_outlined, size: 20),
                title: Text(file.name),
                subtitle: Text(
                  '${_formatTime(file.modifiedAt)} · ${_formatSize(file.size)}',
                ),
                onTap: () => Navigator.of(dialogContext).pop(file),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.calendarCancel),
          ),
        ],
      ),
    );
    if (info == null || !mounted) return;

    final BackupDocument document;
    try {
      document = await service.readFile(info);
    } on BackupException catch (error) {
      _showError(_errorText(l10n, error));
      return;
    } on Object catch (error) {
      _showError(l10n.backupRestoreFailed);
      debugPrint('读取备份文件失败：$error');
      return;
    }
    if (!mounted) return;

    final mode = await _askMode(document.summary);
    if (mode == null || !mounted) return;

    await _runRestore(
      () => service.restoreFile(info, mode: mode),
    );
  }

  Future<void> _restoreFromPaste() async {
    final l10n = context.l10n;
    final service = ref.read(backupServiceProvider);

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final controller = TextEditingController(text: clipboard?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.backupRestoreFromPaste),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 14,
            decoration: InputDecoration(hintText: l10n.backupPasteHint),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.calendarSave),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;

    final BackupDocument document;
    try {
      document = service.parse(text);
    } on BackupException catch (error) {
      _showError(_errorText(l10n, error));
      return;
    }
    if (!mounted) return;

    final mode = await _askMode(document.summary);
    if (mode == null || !mounted) return;

    await _runRestore(() => service.restore(text, mode: mode));
  }

  Future<void> _runRestore(Future<BackupSummary> Function() action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final summary = await action();
      if (!mounted) return;
      setState(() => _busy = false);
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.backupRestored(summary.total))),
      );
    } on BackupException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(_errorText(l10n, error));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('${l10n.backupRestoreFailed}：$error');
    }
  }

  /// 恢复前的确认框：先给你看清楚"这是哪份备份、多少条、怎么写入"。
  Future<RestoreMode?> _askMode(BackupSummary summary) {
    final l10n = context.l10n;
    return showDialog<RestoreMode>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.backupConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.backupConfirmBody(
                _formatTime(summary.exportedAt),
                summary.total,
                summary.includeApiKeys ? l10n.backupContainsApiKeys : '',
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.backupModeReplaceHint),
            const SizedBox(height: 6),
            Text(l10n.backupModeMergeHint),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.calendarCancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(RestoreMode.merge),
            child: Text(l10n.backupModeMerge),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(RestoreMode.replace),
            child: Text(l10n.backupModeReplace),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(AppLocalizations l10n, BackupException error) {
    switch (error.code) {
      case BackupErrorCode.notJson:
        return l10n.backupErrorNotJson;
      case BackupErrorCode.notTokiBackup:
        return l10n.backupErrorNotBackup;
      case BackupErrorCode.unsupportedFormatVersion:
        return l10n.backupErrorFormatVersion;
      case BackupErrorCode.unsupportedSchemaVersion:
        return l10n.backupErrorSchemaVersion;
      case BackupErrorCode.missingTables:
        return l10n.backupErrorMissingTables;
      case BackupErrorCode.corrupted:
        return l10n.backupErrorCorrupted;
    }
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
