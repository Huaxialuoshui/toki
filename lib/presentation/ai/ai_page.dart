import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/ai/chat_controller.dart';
import '../../application/ai/ai_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/chat_message.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/persona_avatar.dart';

/// AI 聊天页：真实调用已配置的 AI 服务商，逐字流式输出并落库。
class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});

  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    _composer.clear();
    final controller = ref.read(chatControllerProvider.notifier);
    unawaitedSend(controller, text);
    _scrollToBottom();
  }

  void unawaitedSend(ChatController controller, String text) {
    controller.send(text).then((_) {
      if (mounted) _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = ref.watch(clockProvider).now();
    final persona = ref.watch(activePersonaProvider) ??
        buildFallbackPersona(now: now, l10n: l10n);
    final sessionAsync = ref.watch(chatSessionProvider);
    final session = sessionAsync.valueOrNull;
    final messages = session == null
        ? const <ChatMessage>[]
        : ref.watch(chatMessagesProvider(session.id)).valueOrNull ??
            const <ChatMessage>[];
    final stream = ref.watch(chatControllerProvider);
    final config = ref.watch(activeAiConfigProvider);
    final personas =
        ref.watch(personasProvider).valueOrNull ?? const <AiPersona>[];

    return PageScaffold(
      title: l10n.navAi,
      subtitle: '${persona.name} · ${persona.description ?? ''}',
      actions: <Widget>[
        _PersonaSwitcher(
          personas: personas,
          active: persona,
          onSelect: (AiPersona selected) => _switchPersona(selected),
          onManage: () => context.go('/settings'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: messages.isEmpty && !stream.isStreaming
              ? null
              : () => _confirmClear(context, ref),
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: l10n.aiClearConversation,
        ),
      ],
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (config == null) const _NoProviderNotice(),
          if (stream.error != null)
            _ErrorBanner(
              message: stream.error == 'no-provider'
                  ? l10n.aiNoProvider
                  : (stream.error == 'empty' ? l10n.aiThinking : stream.error!),
              onDismiss: () =>
                  ref.read(chatControllerProvider.notifier).clearError(),
            ),
          Expanded(
            child: messages.isEmpty && !stream.isStreaming
                ? _EmptyConversation(persona: persona)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: messages.length + (stream.isStreaming ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= messages.length) {
                        return _StreamingBubble(
                          text: stream.streamingText,
                          persona: persona,
                        );
                      }
                      return _MessageView(
                        message: messages[index],
                        persona: persona,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          _Composer(
            controller: _composer,
            personaName: persona.name,
            isStreaming: stream.isStreaming,
            enabled: config != null,
            onSend: _send,
            onStop: () => ref.read(chatControllerProvider.notifier).cancel(),
            onOpenSettings: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.aiClearConfirm),
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
    if (confirmed != true) return;
    await ref.read(chatControllerProvider.notifier).clearConversation();
  }

  Future<void> _switchPersona(AiPersona persona) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;

    final personas = ref.read(personasProvider).valueOrNull ?? const <AiPersona>[];
    final isPersisted = personas.any((AiPersona item) => item.id == persona.id);
    if (isPersisted) {
      await ref
          .read(chatControllerProvider.notifier)
          .switchPersona(persona.id);
    }
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.aiPersonaSwitched(persona.name))),
    );
  }
}

/// 人设切换器：列出全部人设 + 「管理人设」入口。
class _PersonaSwitcher extends StatelessWidget {
  const _PersonaSwitcher({
    required this.personas,
    required this.active,
    required this.onSelect,
    required this.onManage,
  });

  final List<AiPersona> personas;
  final AiPersona active;
  final ValueChanged<AiPersona> onSelect;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PopupMenuButton<Object>(
      tooltip: l10n.aiPersona,
      onSelected: (Object value) {
        if (value == 'manage') {
          onManage();
        } else if (value is AiPersona) {
          onSelect(value);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Object>>[
        for (final persona in personas)
          PopupMenuItem<Object>(
            value: persona,
            child: Row(
              children: <Widget>[
                PersonaAvatar(persona: persona, radius: 12),
                const SizedBox(width: 10),
                Expanded(child: Text(persona.name)),
                if (persona.id == active.id)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
        if (personas.isNotEmpty) const PopupMenuDivider(),
        PopupMenuItem<Object>(
          value: 'manage',
          child: Row(
            children: <Widget>[
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 10),
              Text(l10n.aiManagePersonas),
            ],
          ),
        ),
      ],
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PersonaAvatar(persona: active, radius: 12),
            const SizedBox(width: 8),
            Text(active.name, style: theme.textTheme.labelLarge),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NoProviderNotice extends StatelessWidget {
  const _NoProviderNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.aiNoProvider,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.aiNoProviderHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.66),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/settings'),
              child: Text(l10n.aiOpenSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.persona});

  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PersonaAvatar(persona: persona, radius: 28),
          const SizedBox(height: 12),
          Text(
            l10n.aiEmptyConversation(persona.name),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.persona});

  final ChatMessage message;
  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    if (message.role == ChatRole.tool) {
      return _ToolCallView(message: message);
    }

    final theme = Theme.of(context);
    final locale = context.localeCode;
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!isUser) ...<Widget>[
                _AssistantAvatar(persona: persona),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  color: isUser
                      ? theme.colorScheme.primary.withValues(alpha: 0.16)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SelectableText(
                        message.content,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormats.time(message.createdAt, locale),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 正在逐字输出的助手气泡。
class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text, required this.persona});

  final String text;
  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasText = text.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AssistantAvatar(persona: persona),
              const SizedBox(width: 8),
              Flexible(
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (hasText)
                        SelectableText(
                          text,
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        Text(
                          l10n.aiStreamingHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.persona});

  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    return PersonaAvatar(persona: persona, radius: 14);
  }
}

class _ToolCallView extends StatelessWidget {
  const _ToolCallView({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tool = message.toolCall;
    final running = tool?.status == ToolCallStatus.running;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 14,
                height: 14,
                child: running
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${l10n.aiToolCallLabel} · ${tool?.toolName ?? ''} — '
                  '${message.content}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.personaName,
    required this.isStreaming,
    required this.enabled,
    required this.onSend,
    required this.onStop,
    required this.onOpenSettings,
  });

  final TextEditingController controller;
  final String personaName;
  final bool isStreaming;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            enabled: enabled,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: enabled
                  ? l10n.aiComposerHint(personaName)
                  : l10n.aiNoProviderHint,
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (isStreaming)
          IconButton.filledTonal(
            onPressed: onStop,
            icon: const Icon(Icons.stop),
            tooltip: l10n.aiStop,
          )
        else
          IconButton.filled(
            onPressed: enabled ? onSend : onOpenSettings,
            icon: Icon(enabled ? Icons.send : Icons.settings),
            tooltip: enabled ? l10n.aiSend : l10n.aiOpenSettings,
          ),
      ],
    );
  }
}
