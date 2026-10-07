import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/ai_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

/// 模型选择结果：选中某个模型，或要求切到手动输入。
class ModelChoice {
  const ModelChoice.picked(this.model) : manual = false;
  const ModelChoice.manual()
      : model = null,
        manual = true;

  final String? model;
  final bool manual;
}

/// 从服务商拉取模型列表并选择。
///
/// 打开即请求 `GET {baseUrl}/models`；失败时给出可读原因 + 重试 + 手动输入兜底。
class ModelPickerDialog extends ConsumerStatefulWidget {
  const ModelPickerDialog({
    super.key,
    required this.config,
    required this.current,
  });

  /// 表单里的临时配置（可能还没保存）。
  final AiProviderConfig config;

  /// 当前已选的模型 id，用于打勾。
  final String current;

  @override
  ConsumerState<ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends ConsumerState<ModelPickerDialog> {
  final TextEditingController _filter = TextEditingController();
  String _keyword = '';
  List<String>? _models;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _filter.addListener(
      () => setState(() => _keyword = _filter.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  /// 拉模型列表。
  ///
  /// 刻意用显式的 loading / error 状态而不是 `FutureBuilder`：重试时
  /// `FutureBuilder` 要等下一帧才挂上监听，失败得太快会被报成 unhandled error。
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final models =
          await ref.read(aiProviderBuilderProvider)(widget.config).listModels();
      if (!mounted) return;
      setState(() {
        _models = models;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AppException ? error.message : '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.aiModelPickerTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.calendarCancel,
                  ),
                ],
              ),
              Text(
                widget.config.baseUrl,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(child: _buildBody(l10n, theme)),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(const ModelChoice.manual()),
                  icon: const Icon(Icons.keyboard_outlined, size: 18),
                  label: Text(l10n.aiModelManual),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = _error;
    if (error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.aiFetchModelsFailed,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 6),
          Text(error, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.aiRetry),
            ),
          ),
        ],
      );
    }

    final all = _models ?? const <String>[];
    final models = all
        .where(
          (String id) =>
              _keyword.isEmpty || id.toLowerCase().contains(_keyword),
        )
        .toList(growable: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.aiModelsLoaded(all.length),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey<String>('ai-model-filter'),
          controller: _filter,
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.aiModelSearchHint,
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: models.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(l10n.aiNoModels)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: models.length,
                  itemBuilder: (BuildContext context, int index) {
                    final id = models[index];
                    final selected = id == widget.current;
                    return ListTile(
                      key: ValueKey<String>('ai-model-$id'),
                      dense: true,
                      title: Text(id),
                      trailing: selected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () =>
                          Navigator.of(context).pop(ModelChoice.picked(id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
