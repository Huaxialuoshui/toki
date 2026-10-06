import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/ai_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/services/ai_provider.dart';
import '../../infrastructure/ai/openai_compatible_provider.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';

/// 常见 OpenAI Compatible 服务商预设，一键填充 Base URL 与模型。
class _Preset {
  const _Preset(this.label, this.baseUrl, this.model);

  final String label;
  final String baseUrl;
  final String model;
}

const List<_Preset> _presets = <_Preset>[
  _Preset('DeepSeek', 'https://api.deepseek.com', 'deepseek-chat'),
  // 小米 MiMo：OpenAI 兼容协议，Base URL 必须带 /v1。
  _Preset('小米 MiMo', 'https://api.xiaomimimo.com/v1', 'mimo-v2.6-pro'),
  _Preset('OpenAI', 'https://api.openai.com/v1', 'gpt-4o-mini'),
  _Preset(
      'Qwen', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-plus'),
  _Preset('Moonshot', 'https://api.moonshot.cn/v1', 'moonshot-v1-8k'),
  _Preset('智谱', 'https://open.bigmodel.cn/api/paas/v4', 'glm-4-flash'),
  _Preset('Ollama', 'http://127.0.0.1:11434/v1', 'qwen2.5:7b'),
];

/// 设置页的「AI 与服务商」区块：列出 / 新增 / 编辑服务商。
class AiProviderSection extends ConsumerWidget {
  const AiProviderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final configs = ref.watch(aiProvidersProvider).valueOrNull ??
        const <AiProviderConfig>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (configs.isEmpty)
            Text(
              l10n.aiNoProviders,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            )
          else
            for (final config in configs) _ProviderRow(config: config),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => showAiProviderEditor(context, ref: ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.aiAddProvider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiKeyStoredLocally,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends ConsumerWidget {
  const _ProviderRow({required this.config});

  final AiProviderConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showAiProviderEditor(context, ref: ref, config: config),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            config.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (config.isDefault) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.aiDefaultBadge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${config.model} · ${config.baseUrl}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.66),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // 只显示脱敏后的 Key，绝不显示原文。
                      Text(
                        '${l10n.aiApiKey}: ${config.maskedApiKey.isEmpty ? '—' : config.maskedApiKey}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!config.isDefault)
                  TextButton(
                    onPressed: () => ref
                        .read(aiProviderRepositoryProvider)
                        .setDefault(config.id),
                    child: Text(l10n.aiSetDefault),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 打开服务商编辑器（新建 / 编辑 + 测试连接 + 删除）。
Future<void> showAiProviderEditor(
  BuildContext context, {
  required WidgetRef ref,
  AiProviderConfig? config,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) =>
        _AiProviderEditorDialog(config: config),
  );
}

class _AiProviderEditorDialog extends ConsumerStatefulWidget {
  const _AiProviderEditorDialog({this.config});

  final AiProviderConfig? config;

  @override
  ConsumerState<_AiProviderEditorDialog> createState() =>
      _AiProviderEditorDialogState();
}

class _AiProviderEditorDialogState
    extends ConsumerState<_AiProviderEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  late final TextEditingController _maxTokens;

  late double _temperature;
  late bool _streaming;
  late bool _isDefault;
  bool _showKey = false;
  bool _busy = false;
  String? _feedback;
  bool _feedbackIsError = false;

  bool get _isEditing => widget.config != null;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _name = TextEditingController(text: config?.name ?? '');
    _baseUrl = TextEditingController(text: config?.baseUrl ?? '');
    _apiKey = TextEditingController(text: config?.apiKey ?? '');
    _model = TextEditingController(text: config?.model ?? '');
    _maxTokens = TextEditingController(
      text: config?.maxTokens == null ? '' : '${config!.maxTokens}',
    );
    _temperature = config?.temperature ?? 0.7;
    _streaming = config?.streamingEnabled ?? true;
    _isDefault = config?.isDefault ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _maxTokens.dispose();
    super.dispose();
  }

  AiProviderConfig _buildConfig({String? id}) {
    final now = ref.read(clockProvider).now();
    return AiProviderConfig(
      id: id ?? widget.config?.id ?? generateId('provider', now: now),
      name: _name.text.trim(),
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim().isEmpty ? null : _apiKey.text.trim(),
      model: _model.text.trim(),
      temperature: _temperature,
      maxTokens: int.tryParse(_maxTokens.text.trim()),
      streamingEnabled: _streaming,
      isDefault: _isDefault,
      createdAt: widget.config?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _isEditing ? l10n.aiEditProvider : l10n.aiAddProvider,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.calendarCancel,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          l10n.aiPresets,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final preset in _presets)
                              ActionChip(
                                label: Text(preset.label),
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                          _baseUrl.text = preset.baseUrl;
                                          _model.text = preset.model;
                                          if (_name.text.trim().isEmpty) {
                                            _name.text = preset.label;
                                          }
                                        }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _name,
                          decoration: InputDecoration(
                            labelText: l10n.aiProviderName,
                          ),
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.aiFieldRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _baseUrl,
                          decoration: InputDecoration(
                            labelText: l10n.aiBaseUrl,
                            helperText:
                                'https://api.deepseek.com 或 http://127.0.0.1:11434/v1',
                          ),
                          validator: (String? value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return l10n.aiFieldRequired;
                            if (!text.startsWith('http://') &&
                                !text.startsWith('https://')) {
                              return l10n.aiInvalidUrl;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _apiKey,
                          obscureText: !_showKey,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: l10n.aiApiKey,
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showKey = !_showKey),
                              icon: Icon(
                                _showKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                              ),
                              tooltip:
                                  _showKey ? l10n.aiHideKey : l10n.aiShowKey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _model,
                          decoration: InputDecoration(
                            labelText: l10n.aiModel,
                          ),
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.aiFieldRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${l10n.aiTemperature} · ${_temperature.toStringAsFixed(1)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        Slider(
                          value: _temperature,
                          min: 0,
                          max: 2,
                          divisions: 20,
                          label: _temperature.toStringAsFixed(1),
                          onChanged: _busy
                              ? null
                              : (double value) =>
                                  setState(() => _temperature = value),
                        ),
                        TextFormField(
                          controller: _maxTokens,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.aiMaxTokens,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.aiStreamingEnabled),
                          value: _streaming,
                          onChanged: _busy
                              ? null
                              : (bool value) =>
                                  setState(() => _streaming = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.aiSetDefault),
                          value: _isDefault,
                          onChanged: _busy
                              ? null
                              : (bool value) =>
                                  setState(() => _isDefault = value),
                        ),
                        if (_feedback != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            _feedback!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _feedbackIsError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(l10n.calendarDelete),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _busy ? null : _testConnection,
                      child: Text(l10n.aiTestConnection),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(l10n.calendarSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 用当前表单内容发一条最小请求，验证 Base URL / Key / 模型是否可用。
  Future<void> _testConnection() async {
    final l10n = context.l10n;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _busy = true;
      _feedback = null;
    });

    final provider = OpenAiCompatibleProvider(config: _buildConfig());
    try {
      final response = await provider.chat(
        const AiChatRequest(
          messages: <AiMessage>[AiMessage.user('ping')],
          maxTokens: 16,
          temperature: 0,
        ),
      );
      final reply = response.content.trim();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = false;
        _feedback = l10n.aiTestOk(
          reply.length <= 40 ? reply : '${reply.substring(0, 40)}…',
        );
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedbackIsError = true;
        _feedback = '$error';
      });
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _busy = true;
      _feedback = null;
    });

    final repository = ref.read(aiProviderRepositoryProvider);
    final config = _buildConfig();
    await repository.upsert(config);
    if (config.isDefault) {
      await repository.setDefault(config.id);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final config = widget.config;
    if (config == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.calendarDeleteConfirmTitle),
        content: Text(l10n.calendarDeleteConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.calendarDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(aiProviderRepositoryProvider).deleteById(config.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
