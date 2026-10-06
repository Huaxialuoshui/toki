import 'dart:async';

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

/// 默认会话 id（Phase 7 会支持多会话）。
const String kDefaultChatSessionId = 'session-default';

/// 聊天页的流式状态。
@immutable
class ChatStreamState {
  const ChatStreamState({
    this.isStreaming = false,
    this.streamingText = '',
    this.error,
  });

  final bool isStreaming;

  /// 正在逐字输出的助手文本（尚未落库）。
  final String streamingText;

  /// 最近一次错误（可读文案，不含 API Key）。
  final String? error;

  ChatStreamState copyWith({
    bool? isStreaming,
    String? streamingText,
    String? error,
    bool clearError = false,
  }) {
    return ChatStreamState(
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
      error: clearError ? null : (error ?? this.error),
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
    // 不能用 activePersonaProvider（它反过来依赖本 provider，会形成环）。
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

class ChatController extends Notifier<ChatStreamState> {
  StreamSubscription<AiResponseChunk>? _subscription;
  Completer<void>? _completer;
  Future<void>? _pending;

  @override
  ChatStreamState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const ChatStreamState();
  }

  AiPersona? get _persona => ref.read(activePersonaProvider);

  /// 把用户输入发给模型，并把流式结果写进状态、结束后落库。
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

    final history = await repository.getMessages(session.id);
    final request = AiChatRequest(
      messages: <AiMessage>[
        if ((_persona?.systemPrompt ?? '').trim().isNotEmpty)
          AiMessage.system(_persona!.systemPrompt!.trim()),
        for (final message in history)
          if (message.role == ChatRole.user)
            AiMessage.user(message.content)
          else if (message.role == ChatRole.assistant)
            AiMessage.assistant(message.content),
      ],
      temperature: _persona?.temperature,
    );

    final pending = _runStream(provider, request, session.id);
    _pending = pending;
    await pending;
  }

  Future<void> _runStream(
    AiProvider provider,
    AiChatRequest request,
    String sessionId,
  ) async {
    final buffer = StringBuffer();
    final completer = Completer<void>();
    _completer = completer;

    _subscription = provider.chatStream(request).listen(
      (AiResponseChunk chunk) {
        if (chunk.delta.isNotEmpty) {
          buffer.write(chunk.delta);
          // 逐字刷新：只更新状态里的流式文本。
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

    try {
      await completer.future;
      final reply = buffer.toString().trim();
      if (reply.isEmpty) {
        state = const ChatStreamState(error: 'empty');
        return;
      }
      await _persistAssistantMessage(sessionId, reply);
      state = const ChatStreamState();
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

  /// 中止当前流式输出；已经收到的部分会保留并落库。
  ///
  /// 实现要点：取消订阅后必须结束正在等待的 completer，否则 [send] 会一直挂着。
  Future<void> cancel() async {
    final subscription = _subscription;
    if (subscription == null) return;

    await subscription.cancel();
    _subscription = null;
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    // 等 send() 自己把已收到的部分落库，避免两条路径重复写入。
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
    // 会话变了 → activePersonaProvider 需要重新解析。
    ref.invalidate(chatSessionProvider);
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<void> _persistAssistantMessage(String sessionId, String content) async {
    final repository = ref.read(chatRepositoryProvider);
    final clock = ref.read(clockProvider);
    await repository.upsertMessage(
      ChatMessage(
        id: generateId('msg', now: clock.now()),
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: content,
        createdAt: clock.now(),
      ),
    );
    final session = await repository.findSession(sessionId);
    if (session != null) {
      final now = clock.now();
      await repository.upsertSession(
        ChatSession(
          id: session.id,
          title: session.title,
          personaId: session.personaId,
          createdAt: session.createdAt,
          updatedAt: now,
        ),
      );
    }
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatStreamState>(ChatController.new);
