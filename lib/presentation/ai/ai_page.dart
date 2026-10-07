import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/ai/chat_controller.dart';
import '../../application/ai/ai_providers.dart';
import '../../application/ai/chat_appearance_controller.dart';
import '../../application/ai/persona_actions.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/avatar_config.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/chat_appearance.dart';
import '../../domain/entities/glass_style.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/mock/mock_data.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/markdown_text.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/chat_background.dart';
import '../widgets/avatar_editor.dart';
import '../widgets/image_source.dart';
import '../widgets/persona_avatar.dart';
import '../widgets/tool_labels.dart';

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

  /// 会话列表：新建 / 切换 / 删除。
  Future<void> _showSessions() async {
    final l10n = context.l10n;
    final controller = ref.read(chatControllerProvider.notifier);
    final activeId = ref.read(chatSessionProvider).valueOrNull?.id;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // 用 Consumer watch 会话流：新建 / 删除后列表立刻跟着变。
      builder: (BuildContext sheetContext) => Consumer(
        builder: (BuildContext context, WidgetRef sheetRef, Widget? _) {
          final sessions = sheetRef.watch(chatSessionsProvider).valueOrNull ??
              const <ChatSession>[];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.aiSessions,
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey<String>('ai-new-session'),
                        onPressed: () =>
                            Navigator.of(sheetContext).pop('__new__'),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.aiNewSession),
                      ),
                    ],
                  ),
                ),
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.aiSessionEmpty)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final session = sessions[index];
                        final active = session.id == activeId;
                        return ListTile(
                          key: ValueKey<String>('ai-session-${session.id}'),
                          selected: active,
                          leading: Icon(
                            active
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                            size: 20,
                          ),
                          title: Text(
                            session.title.isEmpty
                                ? l10n.aiNewSession
                                : session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormats.time(
                                session.updatedAt, context.localeCode),
                          ),
                          trailing: IconButton(
                            key: ValueKey<String>(
                                'ai-session-delete-${session.id}'),
                            tooltip: l10n.aiDeleteSession,
                            onPressed: () => Navigator.of(sheetContext)
                                .pop('delete:${session.id}'),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Theme.of(sheetContext).colorScheme.error,
                            ),
                          ),
                          onTap: () => Navigator.of(sheetContext)
                              .pop('switch:${session.id}'),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    if (selected == null || !mounted) return;

    if (selected == '__new__') {
      await controller.createSession(l10n.aiNewSession);
      _scrollToBottom();
      return;
    }
    if (selected.startsWith('switch:')) {
      await controller.switchSession(selected.substring('switch:'.length));
      _scrollToBottom();
      return;
    }
    if (selected.startsWith('delete:')) {
      final id = selected.substring('delete:'.length);
      final confirmed = await _confirm(
        l10n.aiDeleteSessionConfirm,
        confirmLabel: l10n.calendarDelete,
      );
      if (confirmed != true) return;
      await controller.deleteSession(id);
    }
  }

  /// 单条消息的操作：复制 / 编辑并重发 / 重新生成 / 删除。
  Future<void> _showMessageActions(ChatMessage message) async {
    final l10n = context.l10n;
    final controller = ref.read(chatControllerProvider.notifier);
    final isUser = message.role == ChatRole.user;
    final isAssistant = message.role == ChatRole.assistant;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              key: const ValueKey<String>('ai-msg-copy'),
              leading: const Icon(Icons.copy_all_outlined, size: 20),
              title: Text(l10n.aiMessageCopy),
              onTap: () => Navigator.of(sheetContext).pop('copy'),
            ),
            if (isUser)
              ListTile(
                key: const ValueKey<String>('ai-msg-edit'),
                leading: const Icon(Icons.edit_outlined, size: 20),
                title: Text(l10n.aiMessageEdit),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
            if (isAssistant)
              ListTile(
                key: const ValueKey<String>('ai-msg-regenerate'),
                leading: const Icon(Icons.refresh, size: 20),
                title: Text(l10n.aiMessageRegenerate),
                onTap: () => Navigator.of(sheetContext).pop('regenerate'),
              ),
            ListTile(
              key: const ValueKey<String>('ai-msg-delete'),
              leading: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                l10n.aiMessageDelete,
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.content));
        if (!mounted) return;
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(l10n.aiMessageCopied)));
      case 'edit':
        final text = await _editMessage(message.content);
        if (text == null) return;
        await controller.editAndResend(message.id, text);
        _scrollToBottom();
      case 'regenerate':
        await controller.regenerateFrom(message.id);
        _scrollToBottom();
      case 'delete':
        await controller.deleteMessage(message.id);
    }
  }

  Future<String?> _editMessage(String current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: current);
    final text = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.aiEditMessageTitle),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 8,
            autofocus: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            key: const ValueKey<String>('ai-edit-save'),
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.calendarSave),
          ),
        ],
      ),
    );
    return (text == null || text.trim().isEmpty) ? null : text;
  }

  Future<bool?> _confirm(String body, {required String confirmLabel}) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.calendarDeleteConfirmTitle),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.calendarCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
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

    // 危险工具需要用户确认：状态里出现 pendingConfirmation 时弹确认框。
    ref.listen<ChatStreamState>(chatControllerProvider, (
      ChatStreamState? previous,
      ChatStreamState next,
    ) {
      final pending = next.pendingConfirmation;
      if (pending != null && previous?.pendingConfirmation == null) {
        unawaited(_showToolConfirmation(pending));
      }
    });

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
    final appearance = ref.watch(chatAppearanceProvider);
    final personas =
        ref.watch(personasProvider).valueOrNull ?? const <AiPersona>[];
    final providers = ref.watch(aiProvidersProvider).valueOrNull ??
        const <AiProviderConfig>[];

    return PageScaffold(
      title: l10n.navAi,
      subtitle: '${persona.name} · ${persona.description ?? ''}',
      actions: <Widget>[
        if (providers.isNotEmpty)
          _ProviderSwitcher(
            providers: providers,
            activeId: config?.id ?? '',
            onSelect: (String id) =>
                ref.read(chatControllerProvider.notifier).switchProvider(id),
          ),
        const SizedBox(width: 8),
        _PersonaSwitcher(
          personas: personas,
          active: persona,
          onSelect: (AiPersona selected) => _switchPersona(selected),
          onManage: () => context.go('/settings'),
        ),
        const SizedBox(width: 8),
        _AvatarMenu(
          persona: persona,
          isPersonaPersisted:
              personas.any((AiPersona item) => item.id == persona.id),
          onEditMine: _editMyAvatar,
          onEditPersona: () => _editPersonaAvatar(persona),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey<String>('ai-sessions'),
          onPressed: () => _showSessions(),
          icon: const Icon(Icons.forum_outlined),
          tooltip: l10n.aiSessions,
        ),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ChatBackground(
                key: const ValueKey<String>('ai-chat-background'),
                config: appearance.background,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(appearance.fontScale),
                  ),
                  child: messages.isEmpty && !stream.isStreaming
                      ? _EmptyConversation(persona: persona)
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(8),
                          itemCount:
                              messages.length + (stream.isStreaming ? 1 : 0),
                          itemBuilder: (BuildContext context, int index) {
                            if (index >= messages.length) {
                              return _AnimatedMessage(
                                key: const ValueKey<String>('streaming'),
                                enabled: appearance.animationEnabled,
                                child: _StreamingBubble(
                                  text: stream.streamingText,
                                  persona: persona,
                                ),
                              );
                            }
                            final message = messages[index];
                            return _AnimatedMessage(
                              key: ValueKey<String>(message.id),
                              enabled: appearance.animationEnabled,
                              child: _MessageView(
                                message: message,
                                persona: persona,
                                appearance: appearance,
                                onAction: () => _showMessageActions(message),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (stream.activeToolName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l10n.aiToolRunning(
                  toolLabel(l10n, stream.activeToolName!),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
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

    final personas =
        ref.read(personasProvider).valueOrNull ?? const <AiPersona>[];
    final isPersisted = personas.any((AiPersona item) => item.id == persona.id);
    if (isPersisted) {
      await ref.read(chatControllerProvider.notifier).switchPersona(persona.id);
    }
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.aiPersonaSwitched(persona.name))),
    );
  }

  /// 聊天页直接改「我的头像」——打开的就是设置页那套头像编辑器
  /// （表情 / 单字 / 图片 + 底色，图片档里还有「用系统工具编辑」）。
  Future<void> _editMyAvatar() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final appearance = ref.read(chatAppearanceProvider);
    final current = AvatarConfig.fromLegacy(
      appearance.userAvatar,
      color: appearance.userAvatarColor,
    );
    final result = await showAvatarEditor(
      context,
      initial: current,
      title: l10n.aiAvatarMine,
    );
    if (result == null || !mounted) return;
    final controller = ref.read(chatAppearanceProvider.notifier);
    controller.setUserAvatar(result.isEmpty ? null : result.value);
    controller.setUserAvatarColor(result.color);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.aiAvatarSaved)));
  }

  /// 聊天页直接改「助手头像」（写回人设）。内置的兜底人设不落库，所以不提供编辑。
  Future<void> _editPersonaAvatar(AiPersona persona) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final personas =
        ref.read(personasProvider).valueOrNull ?? const <AiPersona>[];
    if (!personas.any((AiPersona item) => item.id == persona.id)) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.aiAvatarOnlyLocal)),
      );
      return;
    }
    final result = await showAvatarEditor(
      context,
      initial: AvatarConfig.fromLegacy(
        persona.avatar,
        color: persona.avatarColor,
      ),
      title: l10n.aiAvatarAssistant,
    );
    if (result == null || !mounted) return;
    await ref.read(personaActionsProvider).save(
          persona.copyWith(
            avatar: result.isEmpty ? null : result.value,
            clearAvatar: result.isEmpty,
            avatarColor: result.color,
            clearAvatarColor: result.color == null,
            updatedAt: ref.read(clockProvider).now(),
          ),
        );
    if (!mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(l10n.aiAvatarSaved)));
  }

  /// 危险操作的二次确认。
  Future<void> _showToolConfirmation(PendingToolConfirmation pending) async {
    final l10n = context.l10n;
    final controller = ref.read(chatControllerProvider.notifier);
    if (!mounted) return;

    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.aiToolConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.aiToolConfirmBody(toolLabel(l10n, pending.toolName)),
            ),
            const SizedBox(height: 12),
            for (final entry in pending.arguments.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${entry.key}: ${entry.value}'),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.aiToolConfirmDeny),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.aiToolConfirmAllow),
          ),
        ],
      ),
    );

    controller.resolveConfirmation(approved ?? false);
  }
}

/// 人设切换器：列出全部人设 + 「管理人设」入口。
/// 头像菜单：聊天页直接改「我的头像 / 助手头像」。
///
/// 两个入口打开的都是同一个人头编辑器（表情 / 单字 / 图片 + 底色），
/// 图片档里带「用系统工具编辑」，所以从聊天页也能一路改到系统编辑器。
class _AvatarMenu extends ConsumerWidget {
  const _AvatarMenu({
    required this.persona,
    required this.isPersonaPersisted,
    required this.onEditMine,
    required this.onEditPersona,
  });

  final AiPersona persona;
  final bool isPersonaPersisted;
  final VoidCallback onEditMine;
  final VoidCallback onEditPersona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(chatAppearanceProvider);
    return PopupMenuButton<Object>(
      key: const ValueKey<String>('ai-avatar-menu'),
      tooltip: l10n.aiAvatarMenu,
      icon: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.transparent,
        child: AvatarPreview(
          config: AvatarConfig.fromLegacy(
            appearance.userAvatar,
            color: appearance.userAvatarColor,
          ),
          radius: 14,
          fallback: '我',
        ),
      ),
      onSelected: (Object value) {
        if (value == 'mine') {
          onEditMine();
        } else if (value == 'persona') {
          onEditPersona();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Object>>[
        PopupMenuItem<Object>(
          value: 'mine',
          child: Row(
            children: <Widget>[
              AvatarPreview(
                config: AvatarConfig.fromLegacy(
                  appearance.userAvatar,
                  color: appearance.userAvatarColor,
                ),
                radius: 12,
                fallback: '我',
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.aiAvatarMine)),
            ],
          ),
        ),
        PopupMenuItem<Object>(
          value: 'persona',
          enabled: isPersonaPersisted,
          child: Row(
            children: <Widget>[
              PersonaAvatar(persona: persona, radius: 12),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.aiAvatarAssistant)),
            ],
          ),
        ),
      ],
    );
  }
}

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
    // 窄屏只显示头像，避免顶栏把标题挤成竖排。
    final compact = MediaQuery.sizeOf(context).width < 600;

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
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PersonaAvatar(persona: active, radius: 12),
            if (!compact) ...<Widget>[
              const SizedBox(width: 8),
              Text(active.name, style: theme.textTheme.labelLarge),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// 服务商切换：这个会话用哪个模型（只影响后续请求）。
class _ProviderSwitcher extends StatelessWidget {
  const _ProviderSwitcher({
    required this.providers,
    required this.activeId,
    required this.onSelect,
  });

  final List<AiProviderConfig> providers;
  final String activeId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final matches = providers.where((AiProviderConfig p) => p.id == activeId);
    final active = matches.isEmpty ? null : matches.first;
    // 窄屏（手机）上顶栏空间有限：只留一个图标，名字放进菜单里。
    final compact = MediaQuery.sizeOf(context).width < 600;

    return PopupMenuButton<String>(
      key: const ValueKey<String>('ai-provider-switcher'),
      tooltip: l10n.aiSwitchProvider,
      onSelected: onSelect,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final provider in providers)
          PopupMenuItem<String>(
            value: provider.id,
            child: Row(
              children: <Widget>[
                const Icon(Icons.memory, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(provider.name),
                      Text(
                        provider.model,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.id == activeId)
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
      child: GlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.memory,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            if (!compact) ...<Widget>[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  active?.model ?? l10n.aiNoProviderShort,
                  style: theme.textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
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
            Icon(Icons.info_outline,
                size: 18, color: theme.colorScheme.primary),
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
  const _MessageView({
    required this.message,
    required this.persona,
    required this.appearance,
    required this.onAction,
  });

  final ChatMessage message;
  final AiPersona persona;
  final ChatAppearanceConfig appearance;

  /// 长按 / 右键：打开这条消息的操作菜单。
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (message.role == ChatRole.tool) {
      return _ToolCallView(message: message, onAction: onAction);
    }

    final theme = Theme.of(context);
    final locale = context.localeCode;
    final isUser = message.role == ChatRole.user;

    // 只请求工具、没有文字的助手消息不渲染成空气泡（它仍然需要留在历史里）。
    if (!isUser && message.content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final style = GlassStyle(
      opacity: appearance.bubbleOpacity,
      blurAmount: 0,
      borderRadius: appearance.bubbleRadius,
      tintColor: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
      borderColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
    );

    // 用户头像（设置了才显示）。
    final userAvatar = _UserAvatar(
      avatar: appearance.userAvatar,
      color: appearance.userAvatarColor,
      radius: 14,
    );
    final showUserAvatar =
        isUser && (appearance.userAvatar ?? '').trim().isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onAction,
        onSecondaryTap: onAction,
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
                    style: style,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MarkdownText(message.content),
                        if ((message.reasoningContent ?? '').trim().isNotEmpty)
                          _ReasoningDisclosure(
                            reasoning: message.reasoningContent!,
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
                if (showUserAvatar) ...<Widget>[
                  const SizedBox(width: 8),
                  userAvatar,
                ],
              ],
            ),
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
                        MarkdownText(text)
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

/// 思考模型的推理过程：默认收起，点一下展开。
///
/// 规格 §12 要求"不要把复杂内容直接摊给用户看"，所以默认只显示一行提示。
class _ReasoningDisclosure extends StatefulWidget {
  const _ReasoningDisclosure({required this.reasoning});

  final String reasoning;

  @override
  State<_ReasoningDisclosure> createState() => _ReasoningDisclosureState();
}

class _ReasoningDisclosureState extends State<_ReasoningDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            key: const ValueKey<String>('ai-reasoning-toggle'),
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded
                        ? l10n.aiReasoningHide
                        : l10n.aiReasoningShow(widget.reasoning.length),
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
              child: SelectableText(
                widget.reasoning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 用户头像：emoji / 单个字 / 图片路径或 URL。
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.avatar, this.color, this.radius = 14});

  final String? avatar;
  final int? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (avatar ?? '').trim();
    final image = resolveImageProvider(value);
    final background = color == null
        ? theme.colorScheme.secondary.withValues(alpha: 0.18)
        : Color(color!);

    if (image != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: background,
        foregroundImage: image,
        onForegroundImageError: (_, __) {},
        child: Text('我', style: theme.textTheme.labelMedium),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        value.isEmpty ? '我' : value,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 消息入场动画（可关闭）。
class _AnimatedMessage extends StatelessWidget {
  const _AnimatedMessage({
    super.key,
    required this.child,
    required this.enabled,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? inner) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}

class _ToolCallView extends StatelessWidget {
  const _ToolCallView({required this.message, required this.onAction});

  final ChatMessage message;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tool = message.toolCall;
    final running = tool?.status == ToolCallStatus.running;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onAction,
        onSecondaryTap: onAction,
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
                    '${l10n.aiToolCallLabel} · '
                    '${toolLabel(l10n, tool?.toolName ?? '')} — ${message.content}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
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
