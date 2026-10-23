import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/services/ai_provider.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import 'ai_providers.dart';
import 'context_service.dart';
import 'persona_prompt.dart';
import 'tool_permissions.dart';
import 'tools/ai_tool.dart';
import 'tools/tool_registry.dart';

/// 首次使用时自动创建的会话 id（之后用户可以新建 / 切换 / 删除会话）。
const String kDefaultChatSessionId = 'session-default';

/// 默认会话标题；只有标题还是它时才会被首条消息自动改成摘要。
const String kDefaultChatSessionTitle = 'Toki';

/// 需要用户确认的危险操作。
@immutable
class PendingToolConfirmation {
  const PendingToolConfirmation({
    required this.toolName,
    required this.category,
    required this.arguments,
    this.preview,
  });

  final String toolName;
  final AiToolCategory category;
  final Map<String, Object?> arguments;
  final AiToolPreview? preview;
}

/// 聊天页的流式状态。
@immutable
class ChatStreamState {
  const ChatStreamState({
    this.isStreaming = false,
    this.streamingText = '',
    this.error,
    this.pendingConfirmation,
    this.activeToolName,
    this.streamingReasoning = '',
  });

  final bool isStreaming;

  /// 正在逐字输出的助手文本（尚未落库）。
  final String streamingText;

  /// 最近一次错误（可读文案，不含 API Key）。
  final String? error;

  /// 等待用户确认的危险工具调用。
  final PendingToolConfirmation? pendingConfirmation;

  /// 正在执行的工具名（用于"正在创建日程…"）。
  final String? activeToolName;

  /// 正在流式输出的思考内容（思考模型；界面默认折叠，不展开显示）。
  final String streamingReasoning;

  ChatStreamState copyWith({
    bool? isStreaming,
    String? streamingText,
    String? error,
    bool clearError = false,
    PendingToolConfirmation? pendingConfirmation,
    bool clearConfirmation = false,
    String? activeToolName,
    bool clearActiveTool = false,
    String? streamingReasoning,
  }) {
    return ChatStreamState(
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
      error: clearError ? null : (error ?? this.error),
      pendingConfirmation: clearConfirmation
          ? null
          : (pendingConfirmation ?? this.pendingConfirmation),
      activeToolName:
          clearActiveTool ? null : (activeToolName ?? this.activeToolName),
      streamingReasoning: streamingReasoning ?? this.streamingReasoning,
    );
  }
}

/// 当前会话 id（应用级轻量设置，存在 shared_preferences）。
final activeChatSessionIdProvider = StateProvider<String?>(
  (ref) => ref.read(appSettingsStoreProvider).readActiveChatSessionId(),
);

/// 全部会话（最近更新的在前），供会话列表 UI 使用。
final chatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>(
  (ref) => ref.watch(chatRepositoryProvider).watchSessions(),
);

/// 当前会话与消息（供 UI 直接 watch）。
///
/// 解析顺序：持久化的当前会话 → 最近更新的会话 → 一个都没有时新建默认会话。
final chatSessionProvider =
    FutureProvider.autoDispose<ChatSession>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final now = ref.watch(clockProvider).now();
  final selectedId = ref.watch(activeChatSessionIdProvider);

  if (selectedId != null && selectedId.isNotEmpty) {
    final selected = await repository.findSession(selectedId);
    if (selected != null) return selected;
  }

  final existing = await repository.getSessions();
  if (existing.isNotEmpty) return existing.first;

  final session = ChatSession(
    id: kDefaultChatSessionId,
    title: kDefaultChatSessionTitle,
    personaId: _firstPersonaId(ref),
    createdAt: now,
    updatedAt: now,
  );
  await repository.upsertSession(session);
  return session;
});

/// 新建会话时的默认人设：数据库里第一个；没有就留空。
String _firstPersonaId(Ref ref) {
  final personas = ref.read(personasProvider).valueOrNull;
  if (personas == null || personas.isEmpty) return '';
  return personas.first.id;
}

final chatMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, String sessionId) =>
      ref.watch(chatRepositoryProvider).watchMessages(sessionId),
);

/// 当前生效的人设：
/// 1. 当前会话 `chat_sessions.persona_id` 指定的人设；
/// 2. 否则数据库里的第一个人设；
/// 3. 数据库为空时返回 null，由 UI 回落到内置文案。
final activePersonaProvider = Provider.autoDispose<AiPersona?>((ref) {
  final personas = ref.watch(personasProvider).valueOrNull;
  if (personas == null || personas.isEmpty) return null;

  final selectedId = ref.watch(chatSessionProvider).valueOrNull?.personaId;
  if (selectedId != null && selectedId.isNotEmpty) {
    for (final persona in personas) {
      if (persona.id == selectedId) return persona;
    }
  }
  return personas.first;
});

/// 当前生效的 AI 服务商配置：
/// 1. 当前会话指定的服务商（聊天页可以切换）；
/// 2. 标了"默认"的那个；
/// 3. 列表里的第一个。
final activeAiConfigProvider = Provider.autoDispose<AiProviderConfig?>((ref) {
  final configs = ref.watch(aiProvidersProvider).valueOrNull;
  if (configs == null || configs.isEmpty) return null;

  final selectedId = ref.watch(chatSessionProvider).valueOrNull?.providerId;
  if (selectedId != null && selectedId.isNotEmpty) {
    for (final config in configs) {
      if (config.id == selectedId) return config;
    }
    // 服务商被删掉了：回落到默认，不影响继续聊天。
  }
  for (final config in configs) {
    if (config.isDefault) return config;
  }
  return configs.first;
});

/// 根据当前配置构造 [AiProvider]；没有配置时返回 null。
final aiProviderFactoryProvider =
    Provider.autoDispose<AiProvider? Function()>((ref) {
  return () {
    final config = ref.read(activeAiConfigProvider);
    if (config == null) return null;
    return ref.read(aiProviderBuilderProvider)(config);
  };
});

/// 单轮流式结果。
class _TurnResult {
  const _TurnResult({
    required this.text,
    required this.toolCalls,
    this.reasoning,
  });

  final String text;
  final List<AiToolCall> toolCalls;

  /// 思考模型这一轮的内部推理（没有则为空）。
  final String? reasoning;
}

/// 工具执行结果（给模型看的内容 + 给用户看的摘要）。
class _ToolOutcome {
  const _ToolOutcome({
    required this.content,
    required this.isError,
    required this.display,
  });

  final String content;
  final bool isError;
  final String display;
}

class ChatController extends Notifier<ChatStreamState> {
  /// 一次用户输入最多允许几轮"模型 → 工具 → 模型"。
  static const int maxToolRounds = 5;

  StreamSubscription<AiResponseChunk>? _subscription;
  Completer<void>? _completer;
  Completer<bool>? _confirmation;
  Future<void>? _pending;

  @override
  ChatStreamState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
      _confirmation?.complete(false);
      _confirmation = null;
    });
    return const ChatStreamState();
  }

  AiPersona? get _persona => ref.read(activePersonaProvider);

  /// 用户确认 / 拒绝一个危险工具调用。
  void resolveConfirmation(bool approved) {
    final completer = _confirmation;
    _confirmation = null;
    state = state.copyWith(clearConfirmation: true);
    if (completer != null && !completer.isCompleted) {
      completer.complete(approved);
    }
  }

  Future<void> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || state.isStreaming) return;

    final factory = ref.read(aiProviderFactoryProvider);
    final provider = factory();
    if (provider == null) {
      state = const ChatStreamState(error: 'no-provider');
      return;
    }

    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    final session = await ref.read(chatSessionProvider.future);

    state = const ChatStreamState(isStreaming: true);
    await repository.upsertMessage(
      ChatMessage(
        id: generateId('msg', now: clock.now()),
        sessionId: session.id,
        role: ChatRole.user,
        content: content,
        createdAt: clock.now(),
      ),
    );
    await _touchSession(session.id);
    await _maybeAutoTitle(session, content);

    final pending = _runAgent(provider, session);
    _pending = pending;
    await pending;
  }

  /// 标题还是默认值时，用首条用户消息做摘要。
  Future<void> _maybeAutoTitle(ChatSession session, String content) async {
    if (session.title.trim().isNotEmpty &&
        session.title != kDefaultChatSessionTitle) {
      return;
    }
    final oneLine = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) return;
    final title =
        oneLine.length <= 20 ? oneLine : '${oneLine.substring(0, 20)}…';
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    await repository.upsertSession(
      session.copyWith(title: title, updatedAt: clock.now()),
    );
    // 标题变了：让 watch chatSessionProvider 的地方跟着刷新。
    ref.invalidate(chatSessionProvider);
  }

  /// 核心循环：模型 → 工具 → 模型 …… 直到模型给出最终回复。
  Future<void> _runAgent(AiProvider provider, ChatSession session) async {
    final repository = ref.read(chatRepositoryProvider);
    final registry = ref.read(aiToolRegistryProvider);
    final permissions = ref.read(toolPermissionsProvider);
    final persona = _persona;

    try {
      // Phase 9：按用户问题动态收集上下文（今天/相关日程/倒计时/当前时间），
      // 只算一次，后续轮次靠工具结果补充细节。
      // 纯聊天人设不碰日历：连"当前时间"都不注入，只靠对话本身。
      final question = await _latestUserQuestion(session.id);
      final context = question == null || !PersonaPrompt.usesCalendar(persona)
          ? null
          : await ref.read(contextServiceProvider).buildContext(question);

      for (var round = 0; round < maxToolRounds; round++) {
        final history = await repository.getMessages(session.id);
        final request = AiChatRequest(
          messages: _toAiMessages(history, persona, context),
          temperature: persona?.temperature,
          tools: registry.definitions(
            permissions: permissions,
            persona: persona,
          ),
        );

        final turn = await _streamTurn(provider, request);

        if (turn.toolCalls.isEmpty) {
          final reply = turn.text.trim();
          if (reply.isEmpty) {
            state = const ChatStreamState(error: 'empty');
            return;
          }
          await _persistAssistantMessage(
            session.id,
            reply,
            reasoning: turn.reasoning,
          );
          state = const ChatStreamState();
          return;
        }

        // 1) 记录助手这一轮的文字与工具请求
        await _persistAssistantMessage(
          session.id,
          turn.text.trim(),
          toolCalls: turn.toolCalls,
          reasoning: turn.reasoning,
        );

        // 2) 依次执行工具，并把结果落库（模型下一轮会看到）
        for (final call in turn.toolCalls) {
          final outcome = await _executeTool(
            call: call,
            registry: registry,
            permissions: permissions,
          );
          await _persistToolMessage(session.id, call, outcome);
        }
      }

      state = const ChatStreamState(
        error: '工具调用轮数过多，已停止（可以换个说法再试）',
      );
    } on AppException catch (error) {
      state = ChatStreamState(error: error.message);
    } catch (error) {
      state = ChatStreamState(error: '$error');
    } finally {
      _subscription = null;
      _completer = null;
      _pending = null;
    }
  }

  Future<String?> _latestUserQuestion(String sessionId) async {
    final history =
        await ref.read(chatRepositoryProvider).getMessages(sessionId);
    for (final message in history.reversed) {
      if (message.role == ChatRole.user) return message.content;
    }
    return null;
  }

  /// 跑一轮流式请求，实时更新 streamingText，返回文本与工具调用。
  Future<_TurnResult> _streamTurn(
    AiProvider provider,
    AiChatRequest request,
  ) async {
    final buffer = StringBuffer();
    final reasoningBuffer = StringBuffer();
    final completer = Completer<void>();
    _completer = completer;
    var toolCalls = const <AiToolCall>[];

    _subscription = provider.chatStream(request).listen(
      (AiResponseChunk chunk) {
        if (chunk.toolCalls.isNotEmpty) {
          toolCalls = chunk.toolCalls;
        }
        if (chunk.reasoning.isNotEmpty) {
          reasoningBuffer.write(chunk.reasoning);
          state = state.copyWith(
            streamingReasoning: reasoningBuffer.toString(),
          );
        }
        if (chunk.delta.isNotEmpty) {
          buffer.write(chunk.delta);
          state = state.copyWith(streamingText: buffer.toString());
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.completeError(error);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
    final reasoning = reasoningBuffer.toString().trim();
    return _TurnResult(
      text: buffer.toString(),
      toolCalls: toolCalls,
      reasoning: reasoning.isEmpty ? null : reasoning,
    );
  }

  /// 权限检查 → 危险操作二次确认 → 执行。
  Future<_ToolOutcome> _executeTool({
    required AiToolCall call,
    required AiToolRegistry registry,
    required ToolPermissions permissions,
  }) async {
    final tool = registry.byName(call.name);
    if (tool == null) {
      return _ToolOutcome(
        content: _errorPayload('未注册的工具：${call.name}'),
        isError: true,
        display: '未知工具 ${call.name}',
      );
    }

    final missingPermissions = tool.requiredCategories
        .where((AiToolCategory category) => !permissions.allows(category))
        .toList(growable: false);
    if (missingPermissions.isNotEmpty) {
      return _ToolOutcome(
        content: _errorPayload(
          '用户未授权 AI 执行「${missingPermissions.map((e) => e.name).join('/')}」'
          '类操作，本次调用被拒绝。'
          '请告知用户可以在设置里开启该权限。',
        ),
        isError: true,
        display: '权限被拒绝',
      );
    }

    if (tool.requiresConfirmation) {
      final approved = await _askConfirmation(tool, call);
      if (!approved) {
        return _ToolOutcome(
          content: _errorPayload('用户拒绝执行 ${tool.name}，本次调用已取消。'),
          isError: true,
          display: '用户已取消',
        );
      }
    }

    state = state.copyWith(activeToolName: tool.name);
    try {
      final result = await tool.execute(call.arguments);
      return _ToolOutcome(
        content: result.toJsonString(),
        isError: result.isError,
        display: result.isError ? '执行失败' : '已完成',
      );
    } catch (error) {
      return _ToolOutcome(
        content: _errorPayload('工具执行异常：$error'),
        isError: true,
        display: '执行失败',
      );
    } finally {
      state = state.copyWith(clearActiveTool: true);
    }
  }

  /// 与 [AiToolResult] 保持一致的错误结构，便于回灌给模型、也便于 UI 判断失败。
  static String _errorPayload(String message) =>
      jsonEncode(<String, Object?>{'error': message});

  Future<bool> _askConfirmation(AiTool tool, AiToolCall call) async {
    final completer = Completer<bool>();
    _confirmation = completer;
    final preview = await tool.preview(call.arguments);
    state = state.copyWith(
      pendingConfirmation: PendingToolConfirmation(
        toolName: tool.name,
        category: tool.category,
        arguments: call.arguments,
        preview: preview,
      ),
    );
    // 卡片上的"确认/取消"由 UI 调用 resolveConfirmation。
    final approved = await completer.future;
    state = state.copyWith(clearConfirmation: true);
    return approved;
  }

  /// 把落库的消息转成发给模型的消息（含工具调用与工具结果）。
  static List<AiMessage> _toAiMessages(
    List<ChatMessage> history,
    AiPersona? persona,
    String? context,
  ) {
    final messages = <AiMessage>[
      if ((persona?.systemPrompt ?? '').trim().isNotEmpty)
        AiMessage.system(persona!.systemPrompt!.trim()),
      if ((context ?? '').trim().isNotEmpty)
        AiMessage.system(
          '以下是用户当前与本问题相关的数据（可能不完整，需要更多细节时请调用工具）。'
          '回答时优先依据这些数据，不要凭空编造：\n$context',
        ),
    ];

    // 控制上下文长度：只带最近 40 条，并从一条 user 消息开始——
    // 否则可能把 assistant(tool_calls) 或 tool 结果截断，导致协议不合法。
    var recent =
        history.length <= 40 ? history : history.sublist(history.length - 40);
    final firstUserIndex = recent.indexWhere(
      (ChatMessage message) => message.role == ChatRole.user,
    );
    if (firstUserIndex > 0) recent = recent.sublist(firstUserIndex);

    for (final message in recent) {
      switch (message.role) {
        case ChatRole.user:
          messages.add(AiMessage.user(message.content));
        case ChatRole.assistant:
          messages.add(
            AiMessage(
              role: AiRole.assistant,
              content: message.content,
              // 思考模型：把历史推理原样回传（官方建议），能明显改善多轮工具调用。
              reasoning: message.reasoningContent,
              toolCalls: message.requestedToolCalls
                  .map(
                    (ChatToolCall call) => AiToolCall(
                      id: call.id,
                      name: call.name,
                      argumentsJson: call.argumentsJson,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        case ChatRole.tool:
          messages.add(
            AiMessage.toolResult(
              toolCallId: message.toolCallId ?? '',
              content: _truncate(message.toolResult ?? message.content),
            ),
          );
        case ChatRole.system:
          break;
      }
    }
    return messages;
  }

  /// 工具结果可能很大（例如整月日程），按字符截断以控制 token。
  static String _truncate(String text, {int maxChars = 2000}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…（结果过长已截断）';
  }

  /// 中止当前输出；已经收到的文本会保留并落库。
  Future<void> cancel() async {
    final subscription = _subscription;
    if (subscription == null) return;

    await subscription.cancel();
    _subscription = null;
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    await _pending;
  }

  /// 清空当前会话的消息（会关闭流）。
  Future<void> clearConversation() async {
    await cancel();
    final repository = ref.read(chatRepositoryProvider);
    final session = await ref.read(chatSessionProvider.future);
    for (final message in await repository.getMessages(session.id)) {
      await repository.deleteMessage(message.id);
    }
    state = const ChatStreamState();
  }

  /// 新建会话并切过去。
  Future<void> createSession([String title = kDefaultChatSessionTitle]) async {
    await cancel();
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    final now = clock.now();
    final session = ChatSession(
      id: generateId('session', now: now),
      title: title,
      personaId: _firstPersonaId(ref),
      createdAt: now,
      updatedAt: now,
    );
    await repository.upsertSession(session);
    _selectSession(session.id);
    state = const ChatStreamState();
  }

  /// 切换当前会话。
  Future<void> switchSession(String id) async {
    if (ref.read(activeChatSessionIdProvider) == id) return;
    await cancel();
    _selectSession(id);
    state = const ChatStreamState();
  }

  /// 删除会话（连带消息）。删的是当前会话时自动切到最近的一个。
  Future<void> deleteSession(String id) async {
    await cancel();
    final repository = ref.read(chatRepositoryProvider);
    // 首次启动时当前会话是"自动创建"出来的，持久化里还是空的，
    // 所以也要拿当前已解析出的会话 id 比一次。
    final activeId = ref.read(activeChatSessionIdProvider) ??
        ref.read(chatSessionProvider).valueOrNull?.id;
    await repository.deleteSession(id);
    if (activeId != id) return;

    final remaining = await repository.getSessions();
    if (remaining.isEmpty) {
      // 一个都不剩：直接建一个新的，别让界面停在已经删掉的会话上。
      await createSession();
      return;
    }
    _selectSession(remaining.first.id);
  }

  void _selectSession(String? id) {
    ref.read(activeChatSessionIdProvider.notifier).state = id;
    unawaited(
      ref.read(appSettingsStoreProvider).writeActiveChatSessionId(id ?? ''),
    );
    ref.invalidate(chatSessionProvider);
  }

  /// 删除单条消息。
  Future<void> deleteMessage(String messageId) async {
    await cancel();
    await ref.read(chatRepositoryProvider).deleteMessage(messageId);
  }

  /// 重新生成某条助手消息：删掉它以及它后面的消息，用前面最后一条用户消息重跑。
  Future<void> regenerateFrom(String assistantMessageId) async {
    if (state.isStreaming) return;
    final repository = ref.read(chatRepositoryProvider);
    final session = await ref.read(chatSessionProvider.future);
    final messages = await repository.getMessages(session.id);
    final index =
        messages.indexWhere((ChatMessage m) => m.id == assistantMessageId);
    if (index < 0) return;

    String? question;
    for (var i = index - 1; i >= 0; i--) {
      if (messages[i].role == ChatRole.user) {
        question = messages[i].content;
        break;
      }
    }
    if (question == null) return;

    for (final message in messages.sublist(index)) {
      await repository.deleteMessage(message.id);
    }
    await _rerun(question);
  }

  /// 编辑用户消息并重新生成后续回复（改完内容后，它后面的消息都会被删掉重跑）。
  Future<void> editAndResend(String userMessageId, String text) async {
    final content = text.trim();
    if (content.isEmpty || state.isStreaming) return;
    await cancel();
    final repository = ref.read(chatRepositoryProvider);
    final session = await ref.read(chatSessionProvider.future);
    final messages = await repository.getMessages(session.id);
    final index = messages.indexWhere((ChatMessage m) => m.id == userMessageId);
    if (index < 0) return;

    await repository.upsertMessage(messages[index].copyWith(content: content));
    for (final message in messages.sublist(index + 1)) {
      await repository.deleteMessage(message.id);
    }
    await _rerun(content);
  }

  /// 用已有的消息历史重跑一轮（用户消息不再插入）。
  Future<void> _rerun(String question) async {
    final provider = ref.read(aiProviderFactoryProvider)();
    if (provider == null) {
      state = const ChatStreamState(error: 'no-provider');
      return;
    }
    final session = await ref.read(chatSessionProvider.future);
    state = const ChatStreamState(isStreaming: true);
    final pending = _runAgent(provider, session);
    _pending = pending;
    await pending;
  }

  /// 切换当前会话使用的人设（只影响后续请求的 system prompt）。
  Future<void> switchPersona(String personaId) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    final session = await ref.read(chatSessionProvider.future);
    await repository.upsertSession(
      ChatSession(
        id: session.id,
        title: session.title,
        personaId: personaId,
        createdAt: session.createdAt,
        updatedAt: clock.now(),
      ),
    );
    ref.invalidate(chatSessionProvider);
  }

  /// 切换当前会话使用的服务商（只影响后续请求）。
  ///
  /// 传空字符串表示"跟随默认服务商"。
  Future<void> switchProvider(String providerId) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    final session = await ref.read(chatSessionProvider.future);
    await repository.upsertSession(
      session.copyWith(providerId: providerId, updatedAt: clock.now()),
    );
    ref.invalidate(chatSessionProvider);
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<void> _persistAssistantMessage(
    String sessionId,
    String content, {
    List<AiToolCall> toolCalls = const <AiToolCall>[],
    String? reasoning,
  }) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    await repository.upsertMessage(
      ChatMessage(
        id: generateId('msg', now: clock.now()),
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: content,
        reasoningContent: reasoning,
        requestedToolCalls: toolCalls
            .map(
              (AiToolCall call) => ChatToolCall(
                id: call.id,
                name: call.name,
                argumentsJson: call.argumentsJson,
              ),
            )
            .toList(growable: false),
        createdAt: clock.now(),
      ),
    );
    await _touchSession(sessionId);
  }

  Future<void> _persistToolMessage(
    String sessionId,
    AiToolCall call,
    _ToolOutcome outcome,
  ) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    await repository.upsertMessage(
      ChatMessage(
        id: generateId('msg', now: clock.now()),
        sessionId: sessionId,
        role: ChatRole.tool,
        content: outcome.display,
        toolCallId: call.id,
        toolResult: outcome.content,
        toolCall: ToolCallInfo(
          toolName: call.name,
          status: outcome.isError
              ? ToolCallStatus.failed
              : ToolCallStatus.succeeded,
          summary: outcome.display,
        ),
        createdAt: clock.now(),
      ),
    );
  }

  Future<void> _touchSession(String sessionId) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    final session = await repository.findSession(sessionId);
    if (session == null) return;
    await repository.upsertSession(
      ChatSession(
        id: session.id,
        title: session.title,
        personaId: session.personaId,
        createdAt: session.createdAt,
        updatedAt: clock.now(),
      ),
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatStreamState>(ChatController.new);
