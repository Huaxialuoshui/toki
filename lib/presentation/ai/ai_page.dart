import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/ai_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/chat_message.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/page_scaffold.dart';

/// AI 页面。
///
/// Phase 2 之后人设可以来自数据库（debug 构建会写入示例人设）；
/// 会话内容仍然是演示数据——Provider / Tool Calling 分别在 Phase 6-8 接入。
class AiPage extends ConsumerWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ref.watch(clockProvider).now();
    final persona = ref.watch(activePersonaProvider) ??
        buildFallbackPersona(now: now, l10n: l10n);
    final messages = buildMockConversation(now: now, l10n: l10n);

    return PageScaffold(
      title: l10n.navAi,
      subtitle: '${persona.name} · ${persona.description ?? ''}',
      actions: <Widget>[_PersonaChip(persona: persona)],
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _MockNotice(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _MessageView(message: messages[index]),
            ),
          ),
          const SizedBox(height: 8),
          _Composer(personaName: persona.name),
        ],
      ),
    );
  }
}

class _PersonaChip extends StatelessWidget {
  const _PersonaChip({required this.persona});

  final AiPersona persona;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Tooltip(
      message: l10n.aiPersonaSwitchSoon,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 12,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.16),
              child: Text(
                persona.avatarInitial,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(persona.name, style: theme.textTheme.labelLarge),
            const SizedBox(width: 6),
            Icon(
              Icons.lock_outline,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockNotice extends StatelessWidget {
  const _MockNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.aiMockNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message});

  final ChatMessage message;

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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            color: isUser
                ? theme.colorScheme.primary.withValues(alpha: 0.16)
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.content, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  DateFormats.time(message.createdAt, locale),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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

class _Composer extends StatefulWidget {
  const _Composer({required this.personaName});

  final String personaName;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSend() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(context.l10n.aiMockNotice)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _onSend(),
            decoration: InputDecoration(
              hintText: l10n.aiComposerHint(widget.personaName),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: _onSend,
          icon: const Icon(Icons.send),
          tooltip: l10n.aiSend,
        ),
      ],
    );
  }
}
