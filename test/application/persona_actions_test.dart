import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/ai/persona_actions.dart';
import 'package:toki/data/repositories/drift_ai_repository.dart';
import 'package:toki/domain/entities/ai_persona.dart';
import 'package:toki/domain/entities/chat_session.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftAiPersonaRepository personas;
  late DriftChatRepository chats;
  late PersonaActions actions;
  final DateTime now = DateTime(2026, 10, 6, 10);

  setUp(() {
    database = AppDatabase.memory();
    personas = DriftAiPersonaRepository(database);
    chats = DriftChatRepository(database);
    actions = PersonaActions(personas: personas, chats: chats);
  });

  tearDown(() => database.close());

  test('删除被人设引用的会话前会先清掉引用（不会撞外键）', () async {
    await actions.save(
      AiPersona(
        id: 'p1',
        name: '小雪',
        enabledTools: const <String>[],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await chats.upsertSession(
      ChatSession(
        id: 's1',
        title: 'Toki',
        personaId: 'p1',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 删除人设：内部会先把会话的 personaId 置空，因此不会抛约束错误。
    await actions.delete('p1');

    expect(await personas.findById('p1'), isNull);
    final session = (await chats.getSessions()).single;
    expect(session.personaId, isEmpty);
  });

  test('保存人设会写入数据库', () async {
    await actions.save(
      AiPersona(
        id: 'p2',
        name: '阿蓝',
        description: '学习搭子',
        systemPrompt: '你是阿蓝。',
        enabledTools: const <String>[],
        createdAt: now,
        updatedAt: now,
      ),
    );

    final stored = (await personas.findById('p2'))!;
    expect(stored.name, '阿蓝');
    expect(stored.description, '学习搭子');
    expect(stored.systemPrompt, '你是阿蓝。');
  });
}
