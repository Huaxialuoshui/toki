import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/ai_providers.dart';
import '../../application/ai/persona_actions.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/ai_persona.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/persona_avatar.dart';

/// 设置页的「AI 人设」区块：列出 / 新增 / 编辑 / 删除。
class AiPersonaSection extends ConsumerWidget {
  const AiPersonaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final personas =
        ref.watch(personasProvider).valueOrNull ?? const <AiPersona>[];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (personas.isEmpty)
            Text(
              l10n.aiNoPersonas,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            )
          else
            for (final persona in personas) _PersonaRow(persona: persona),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => showPersonaEditor(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.aiAddPersona),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonaRow extends StatelessWidget {
  const _PersonaRow({required this.persona});

  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showPersonaEditor(context, persona: persona),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: <Widget>[
                PersonaAvatar(persona: persona, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        persona.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if ((persona.description ?? '').isNotEmpty)
                        Text(
                          persona.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.66),
                          ),
                        ),
                    ],
                  ),
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

Future<void> showPersonaEditor(
  BuildContext context, {
  AiPersona? persona,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => _PersonaEditorDialog(
      persona: persona,
    ),
  );
}

class _PersonaEditorDialog extends ConsumerStatefulWidget {
  const _PersonaEditorDialog({this.persona});

  final AiPersona? persona;

  @override
  ConsumerState<_PersonaEditorDialog> createState() =>
      _PersonaEditorDialogState();
}

class _PersonaEditorDialogState extends ConsumerState<_PersonaEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _identity;
  late final TextEditingController _avatar;
  late final TextEditingController _personality;
  late final TextEditingController _speakingStyle;
  late final TextEditingController _nickname;
  late final TextEditingController _systemPrompt;

  late double _temperature;
  bool _busy = false;

  bool get _isEditing => widget.persona != null;

  @override
  void initState() {
    super.initState();
    final persona = widget.persona;
    _name = TextEditingController(text: persona?.name ?? '');
    _identity = TextEditingController(text: persona?.description ?? '');
    _avatar = TextEditingController(text: persona?.avatar ?? '');
    _personality = TextEditingController(text: persona?.personality ?? '');
    _speakingStyle = TextEditingController(text: persona?.speakingStyle ?? '');
    _nickname = TextEditingController(text: persona?.userNickname ?? '');
    _systemPrompt = TextEditingController(text: persona?.systemPrompt ?? '');
    _temperature = persona?.temperature ?? 0.7;
  }

  @override
  void dispose() {
    _name.dispose();
    _identity.dispose();
    _avatar.dispose();
    _personality.dispose();
    _speakingStyle.dispose();
    _nickname.dispose();
    _systemPrompt.dispose();
    super.dispose();
  }

  AiPersona _buildPersona() {
    final l10n = context.l10n;
    final now = ref.read(clockProvider).now();
    final persona = widget.persona;
    String? clean(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return AiPersona(
      id: persona?.id ?? generateId('persona', now: now),
      name: _name.text.trim(),
      avatar: clean(_avatar),
      description: clean(_identity),
      personality: clean(_personality),
      speakingStyle: clean(_speakingStyle),
      userNickname: clean(_nickname),
      systemPrompt: clean(_systemPrompt) ?? l10n.aiPersonaDefaultPrompt,
      enabledTools: persona?.enabledTools ?? const <String>[],
      temperature: _temperature,
      createdAt: persona?.createdAt ?? now,
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
                        _isEditing ? l10n.aiEditPersona : l10n.aiAddPersona,
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
                        TextFormField(
                          controller: _name,
                          autofocus: !_isEditing,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaName,
                          ),
                          validator: (String? value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.aiFieldRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _identity,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaIdentity,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _avatar,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaAvatar,
                            helperText: l10n.aiPersonaAvatarHint,
                            helperMaxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _personality,
                          minLines: 2,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaPersonality,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _speakingStyle,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaSpeakingStyle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nickname,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaNickname,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _systemPrompt,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: l10n.aiPersonaSystemPrompt,
                            hintText: l10n.aiPersonaDefaultPrompt,
                            hintMaxLines: 3,
                          ),
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
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.calendarCancel),
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

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _busy = true);
    await ref.read(personaActionsProvider).save(_buildPersona());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final persona = widget.persona;
    if (persona == null) return;

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

    await ref.read(personaActionsProvider).delete(persona.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
