import 'package:drift/drift.dart';

import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

/// [AiPersonaRepository] 的 Drift 实现。
class DriftAiPersonaRepository implements AiPersonaRepository {
  DriftAiPersonaRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<AiPersona>> watchAll() => (_db.select(_db.aiPersonas)
        ..orderBy(<OrderClauseGenerator<$AiPersonasTable>>[
          ($AiPersonasTable t) => OrderingTerm.asc(t.name),
        ]))
      .watch()
      .map(_mapAll);

  @override
  Future<List<AiPersona>> getAll() async {
    final rows = await (_db.select(_db.aiPersonas)
          ..orderBy(<OrderClauseGenerator<$AiPersonasTable>>[
            ($AiPersonasTable t) => OrderingTerm.asc(t.name),
          ]))
        .get();
    return _mapAll(rows);
  }

  @override
  Future<AiPersona?> findById(String id) async {
    final row = await (_db.select(_db.aiPersonas)
          ..where(($AiPersonasTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(AiPersona persona) =>
      _db.into(_db.aiPersonas).insertOnConflictUpdate(
            aiPersonaToCompanion(persona),
          );

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.aiPersonas)
          ..where(($AiPersonasTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.aiPersonas).go();

  List<AiPersona> _mapAll(List<AiPersonaRow> rows) =>
      rows.map((AiPersonaRow row) => row.toDomain()).toList(growable: false);
}

/// [AiProviderRepository] 的 Drift 实现。
///
/// 注意：读出的对象包含 API Key，禁止写日志。
class DriftAiProviderRepository implements AiProviderRepository {
  DriftAiProviderRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<AiProviderConfig>> watchAll() => (_db.select(_db.aiProviders)
        ..orderBy(<OrderClauseGenerator<$AiProvidersTable>>[
          ($AiProvidersTable t) => OrderingTerm.asc(t.name),
        ]))
      .watch()
      .map(_mapAll);

  @override
  Future<List<AiProviderConfig>> getAll() async {
    final rows = await (_db.select(_db.aiProviders)
          ..orderBy(<OrderClauseGenerator<$AiProvidersTable>>[
            ($AiProvidersTable t) => OrderingTerm.asc(t.name),
          ]))
        .get();
    return _mapAll(rows);
  }

  @override
  Future<AiProviderConfig?> findDefault() async {
    final row = await (_db.select(_db.aiProviders)
          ..where(($AiProvidersTable t) => t.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(AiProviderConfig config) =>
      _db.into(_db.aiProviders).insertOnConflictUpdate(
            aiProviderToCompanion(config),
          );

  @override
  Future<void> setDefault(String id) async {
    await _db.transaction(() async {
      await _db.update(_db.aiProviders).write(
            const AiProvidersCompanion(isDefault: Value<bool>(false)),
          );
      await (_db.update(_db.aiProviders)
            ..where(($AiProvidersTable t) => t.id.equals(id)))
          .write(const AiProvidersCompanion(isDefault: Value<bool>(true)));
    });
  }

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.aiProviders)
          ..where(($AiProvidersTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.aiProviders).go();

  List<AiProviderConfig> _mapAll(List<AiProviderRow> rows) =>
      rows.map((AiProviderRow row) => row.toDomain()).toList(growable: false);
}

/// [ChatRepository] 的 Drift 实现。
class DriftChatRepository implements ChatRepository {
  DriftChatRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ChatSession>> watchSessions() => (_db.select(_db.chatSessions)
        ..orderBy(<OrderClauseGenerator<$ChatSessionsTable>>[
          ($ChatSessionsTable t) => OrderingTerm.desc(t.updatedAt),
        ]))
      .watch()
      .map(
        (List<ChatSessionRow> rows) => rows
            .map((ChatSessionRow row) => row.toDomain())
            .toList(growable: false),
      );

  @override
  Future<List<ChatSession>> getSessions() async {
    final rows = await (_db.select(_db.chatSessions)
          ..orderBy(<OrderClauseGenerator<$ChatSessionsTable>>[
            ($ChatSessionsTable t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
    return rows
        .map((ChatSessionRow row) => row.toDomain())
        .toList(growable: false);
  }

  @override
  Future<ChatSession?> findSession(String id) async {
    final row = await (_db.select(_db.chatSessions)
          ..where(($ChatSessionsTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsertSession(ChatSession session) =>
      _db.into(_db.chatSessions).insertOnConflictUpdate(
            chatSessionToCompanion(session),
          );

  @override
  Future<void> deleteSession(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.chatMessages)
            ..where(($ChatMessagesTable t) => t.sessionId.equals(id)))
          .go();
      await (_db.delete(_db.chatSessions)
            ..where(($ChatSessionsTable t) => t.id.equals(id)))
          .go();
    });
  }

  @override
  Future<void> clearPersonaFromSessions(String personaId) async {
    await (_db.update(_db.chatSessions)
          ..where(($ChatSessionsTable t) => t.personaId.equals(personaId)))
        .write(const ChatSessionsCompanion(personaId: Value<String?>(null)));
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    final query = _db.select(_db.chatMessages)
      ..where(($ChatMessagesTable t) => t.sessionId.equals(sessionId))
      ..orderBy(<OrderClauseGenerator<$ChatMessagesTable>>[
        ($ChatMessagesTable t) => OrderingTerm.asc(t.createdAt),
      ]);
    return query.watch().map(
          (List<ChatMessageRow> rows) => rows
              .map((ChatMessageRow row) => row.toDomain())
              .toList(growable: false),
        );
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final rows = await (_db.select(_db.chatMessages)
          ..where(($ChatMessagesTable t) => t.sessionId.equals(sessionId))
          ..orderBy(<OrderClauseGenerator<$ChatMessagesTable>>[
            ($ChatMessagesTable t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return rows
        .map((ChatMessageRow row) => row.toDomain())
        .toList(growable: false);
  }

  @override
  Future<void> upsertMessage(ChatMessage message) =>
      _db.into(_db.chatMessages).insertOnConflictUpdate(
            chatMessageToCompanion(message),
          );

  @override
  Future<void> upsertMessages(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.chatMessages,
        messages.map(chatMessageToCompanion),
      );
    });
  }

  @override
  Future<void> deleteMessage(String id) async {
    await (_db.delete(_db.chatMessages)
          ..where(($ChatMessagesTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.chatMessages).go();
      await _db.delete(_db.chatSessions).go();
    });
  }
}
