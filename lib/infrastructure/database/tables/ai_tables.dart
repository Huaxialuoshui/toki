import 'package:drift/drift.dart';

import '../../../domain/entities/chat_message.dart';
import '../converters.dart';

/// AI 人设（规格 §3）。
@DataClassName('AiPersonaRow')
class AiPersonas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get avatar => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get personality => text().nullable()();
  TextColumn get speakingStyle => text().nullable()();
  TextColumn get userNickname => text().nullable()();
  TextColumn get systemPrompt => text().nullable()();
  TextColumn get enabledTools => text().map(const StringListConverter())();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// AI 服务商（OpenAI Compatible）。
///
/// apiKey 只保存在本机数据库，禁止写入日志、禁止提交到 Git；
/// Phase 6 会补上脱敏 UI，并在需要时改为系统安全存储。
@DataClassName('AiProviderRow')
class AiProviders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text().nullable()();
  TextColumn get model => text()();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  IntColumn get maxTokens => integer().nullable()();
  BoolColumn get streamingEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 会话。
@DataClassName('ChatSessionRow')
class ChatSessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get personaId => text().nullable().references(AiPersonas, #id)();

  /// 这个会话用哪个服务商；为空时用"默认服务商"。
  /// 故意不加外键：SQLite 的 ALTER TABLE ADD COLUMN 不方便带 REFERENCES，
  /// 服务商被删掉时的回落逻辑放在应用层（见 activeAiConfigProvider）。
  TextColumn get providerId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 聊天消息。
@DataClassName('ChatMessageRow')
@TableIndex(name: 'idx_chat_messages_session', columns: <Symbol>{#sessionId})
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(ChatSessions, #id)();
  TextColumn get role => textEnum<ChatRole>()();
  TextColumn get content => text()();
  TextColumn get toolName => text().nullable()();

  /// OpenAI 协议里 `role=tool` 的消息必须带 `tool_call_id`。
  TextColumn get toolCallId => text().nullable()();

  TextColumn get toolArguments => text().nullable()();
  TextColumn get toolResult => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
