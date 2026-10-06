import '../entities/ai_persona.dart';
import '../entities/ai_provider_config.dart';
import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

/// AI 人设的数据访问契约。
abstract interface class AiPersonaRepository {
  Stream<List<AiPersona>> watchAll();
  Future<List<AiPersona>> getAll();
  Future<AiPersona?> findById(String id);
  Future<void> upsert(AiPersona persona);
  Future<void> deleteById(String id);
  Future<void> deleteAll();
}

/// AI 服务商配置的数据访问契约。
///
/// 注意：返回的对象包含 API Key，禁止写日志。
abstract interface class AiProviderRepository {
  Stream<List<AiProviderConfig>> watchAll();
  Future<List<AiProviderConfig>> getAll();
  Future<AiProviderConfig?> findDefault();
  Future<void> upsert(AiProviderConfig config);
  Future<void> setDefault(String id);
  Future<void> deleteById(String id);
  Future<void> deleteAll();
}

/// 会话与消息的数据访问契约。
abstract interface class ChatRepository {
  Stream<List<ChatSession>> watchSessions();
  Future<List<ChatSession>> getSessions();
  Future<ChatSession?> findSession(String id);
  Future<void> upsertSession(ChatSession session);
  Future<void> deleteSession(String id);

  Stream<List<ChatMessage>> watchMessages(String sessionId);
  Future<List<ChatMessage>> getMessages(String sessionId);
  Future<void> upsertMessage(ChatMessage message);
  Future<void> upsertMessages(List<ChatMessage> messages);
  Future<void> deleteMessage(String id);

  Future<void> deleteAll();
}
