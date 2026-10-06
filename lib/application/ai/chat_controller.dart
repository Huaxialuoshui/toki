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
import '../../infrastructure/ai/openai_compatible_provider.dart';
import '../../infrastructure/clock_provider.dart';
import 'ai_providers.dart';
import 'tool_permissions.dart';
import 'tools/ai_tool.dart';
import 'tools/tool_registry.dart';

/// 默认会话 id（多会话在后续阶段实现）。
const String kDefaultChatSessionId = 'session-default';

/// 需要用户确认的危险操作。
@immutable
class PendingToolConfirmation {
  const PendingToolConfirmation({
    required this.toolName,
    required this.category,
    required this.arguments,
  });

  final String toolName;
  final AiToolCategory category;
  final Map<String, Object?> arguments;
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

  ChatStreamState copyWith({
    bool? isStreaming,
    String? streamingText,
    String? error,
    bool clearError = false,
    PendingToolConfirmation? pendingConfirmation,
    bool clearConfirmation = false,
    String? activeToolName,
    bool clearActiveTool = false,
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
    );
  }
}

/// 会话与消息（供 UI 直接 watch）。
final chatSessionProvider = FutureProvider.autoDispose<ChatSession>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final now = ref.watch(clockProvider).now();

  final existing = await repository.findSession(kDefaultChatSessionId);
  if (existing != null) return existing;

  final session = ChatSession(
    id: kDefaultChatSessionId,
    title: 'Toki',
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

/// 当前生效的 AI 服务商配置：优先"默认"，否则用列表里的第一个。
final activeAiConfigProvider = Provider.autoDispose<AiProviderConfig?>((ref) {
  final configs = ref.watch(aiProvidersProvider).valueOrNull;
  if (configs == null || configs.isEmpty) return null;
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
    return OpenAiCompatibleProvider(config: config);
  };
});

/// 单轮流式结果。
class _TurnResult {
  const _TurnResult({required this.text, required this.toolCalls});

  final String text;
  final List<AiToolCall> toolCalls;
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

    final pending = _runAgent(provider, session);
    _pending = pending;
    await pending;
  }

  /// 核心循环：模型 → 工具 → 模型 …… 直到模型给出最终回复。
  Future<void> _runAgent(AiProvider provider, ChatSession session) async {
    final repository = ref.read(chatRepositoryProvider);
    final registry = ref.read(aiToolRegistryProvider);
    final permissions = ref.read(toolPermissionsProvider);
    final persona = _persona;

    try {
      for (var round = 0; round < maxToolRounds; round++) {
        final history = await repository.getMessages(session.id);
        final request = AiChatRequest(
          messages: _toAiMessages(history, persona),
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
          await _persistAssistantMessage(session.id, reply);
          state = const ChatStreamState();
          return;
        }

        // 1) 记录助手这一轮的文字与工具请求
        await _persistAssistantMessage(
          session.id,
          turn.text.trim(),
          toolCalls: turn.toolCalls,
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

  /// 跑一轮流式请求，实时更新 streamingText，返回文本与工具调用。
  Future<_TurnResult> _streamTurn(
    AiProvider provider,
    AiChatRequest request,
  ) async {
    final buffer = StringBuffer();
    final completer = Completer<void>();
    _completer = completer;
    var toolCalls = const <AiToolCall>[];

    _subscription = provider.chatStream(request).listen(
      (AiResponseChunk chunk) {
        if (chunk.toolCalls.isNotEmpty) {
          toolCalls = chunk.toolCalls;
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
    return _TurnResult(text: buffer.toString(), toolCalls: toolCalls);
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

    if (!permissions.allows(tool.category)) {
      return _ToolOutcome(
        content: _errorPayload(
          '用户未授权 AI 执行「${tool.category.name}」类操作，本次调用被拒绝。'
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
    state = state.copyWith(
      pendingConfirmation: PendingToolConfirmation(
        toolName: tool.name,
        category: tool.category,
        arguments: call.arguments,
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
  ) {
    final messages = <AiMessage>[
      if ((persona?.systemPrompt ?? '').trim().isNotEmpty)
        AiMessage.system(persona!.systemPrompt!.trim()),
    ];

    // 控制上下文长度：只带最近 40 条。
    final recent = history.length <= 40
        ? history
        : history.sublist(history.length - 40);
    for (final message in recent) {
      switch (message.role) {
        case ChatRole.user:
          messages.add(AiMessage.user(message.content));
        case ChatRole.assistant:
          messages.add(
            AiMessage(
              role: AiRole.assistant,
              content: message.content,
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
              content: message.toolResult ?? message.content,
            ),
          );
        case ChatRole.system:
          break;
      }
    }
    return messages;
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

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<void> _persistAssistantMessage(
    String sessionId,
    String content, {
    List<AiToolCall> toolCalls = const <AiToolCall>[],
  }) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    await repository.upsertMessage(
      ChatMessage(
        id: generateId('msg', now: clock.now()),
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: content,
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
          status:
              outcome.isError ? ToolCallStatus.failed : ToolCallStatus.succeeded,
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
