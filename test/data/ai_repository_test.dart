import 'package:flutter_test/flutter_test.dart';
import 'package:toki/data/repositories/drift_ai_repository.dart';
import 'package:toki/domain/entities/ai_persona.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/entities/chat_message.dart';
import 'package:toki/domain/entities/chat_session.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftAiPersonaRepository personaRepository;
  late DriftAiProviderRepository providerRepository;
  late DriftChatRepository chatRepository;
  final DateTime now = DateTime(2026, 10, 6, 10);

  setUp(() {
    database = AppDatabase.memory();
    personaRepository = DriftAiPersonaRepository(database);
    providerRepository = DriftAiProviderRepository(database);
    chatRepository = DriftChatRepository(database);
  });

  tearDown(() => database.close());

  test('人设 CRUD，enabledTools 以 JSON 往返', () async {
    final persona = AiPersona(
      id: 'p1',
      name: '小雪',
      description: '私人日程助手',
      personality: '温柔、活泼',
      speakingStyle: '简短、自然',
      userNickname: '主人',
      systemPrompt: '你是用户的私人日程助手。',
      enabledTools: const <String>['get_events', 'create_event'],
      temperature: 0.6,
      createdAt: now,
      updatedAt: now,
    );

    await personaRepository.upsert(persona);
    final loaded = (await personaRepository.findById('p1'))!;
    expect(loaded.name, '小雪');
    expect(loaded.enabledTools, <String>['get_events', 'create_event']);
    expect(loaded.temperature, 0.6);

    await personaRepository.upsert(
      AiPersona(
        id: 'p1',
        name: '小雪',
        enabledTools: const <String>['get_events'],
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect((await personaRepository.getAll()).single.enabledTools,
        <String>['get_events']);

    await personaRepository.deleteById('p1');
    expect(await personaRepository.getAll(), isEmpty);
  });

  test('服务商 CRUD：API Key 往返，只有一个默认服务商', () async {
    AiProviderConfig build(String id, {bool isDefault = false}) =>
        AiProviderConfig(
          id: id,
          name: 'DeepSeek-$id',
          baseUrl: 'https://api.deepseek.com',
          apiKey: 'sk-test-$id',
          model: 'deepseek-chat',
          temperature: 0.7,
          maxTokens: 2048,
          isDefault: isDefault,
          createdAt: now,
          updatedAt: now,
        );

    await providerRepository.upsert(build('a', isDefault: true));
    await providerRepository.upsert(build('b'));

    expect((await providerRepository.getAll()).length, 2);
    final loaded = (await providerRepository.findDefault())!;
    expect(loaded.id, 'a');
    expect(loaded.apiKey, 'sk-test-a');
    expect(loaded.maxTokens, 2048);
    expect(loaded.maskedApiKey, 'sk-t****st-a');

    await providerRepository.setDefault('b');
    expect((await providerRepository.findDefault())!.id, 'b');
    final all = await providerRepository.getAll();
    expect(all.where((AiProviderConfig c) => c.isDefault).length, 1);

    await providerRepository.deleteById('b');
    expect((await providerRepository.getAll()).length, 1);
  });

  test('会话与消息 CRUD，删除会话会连带删除消息', () async {
    // 会话通过外键引用人设，因此先建人设。
    await personaRepository.upsert(
      AiPersona(
        id: 'p1',
        name: '小雪',
        enabledTools: const <String>[],
        createdAt: now,
        updatedAt: now,
      ),
    );
    final session = ChatSession(
      id: 's1',
      title: '新的对话',
      personaId: 'p1',
      createdAt: now,
      updatedAt: now,
    );
    await chatRepository.upsertSession(session);
    expect((await chatRepository.getSessions()).single.title, '新的对话');

    await chatRepository.upsertMessages(<ChatMessage>[
      ChatMessage(
        id: 'm1',
        sessionId: 's1',
        role: ChatRole.user,
        content: '我下周有什么安排？',
        createdAt: now,
      ),
      ChatMessage(
        id: 'm2',
        sessionId: 's1',
        role: ChatRole.assistant,
        content: '下周三 15:00 毕业答辩。',
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ]);

    final messages = await chatRepository.getMessages('s1');
    expect(messages.map((ChatMessage m) => m.id), <String>['m1', 'm2']);
    expect(messages.first.role, ChatRole.user);

    await chatRepository.deleteMessage('m2');
    expect((await chatRepository.getMessages('s1')).length, 1);

    await chatRepository.deleteSession('s1');
    expect(await chatRepository.getSessions(), isEmpty);
    expect(await chatRepository.getMessages('s1'), isEmpty);
  });

  test('外键约束生效：引用不存在的人设会被拒绝', () async {
    expect(
      () => chatRepository.upsertSession(
        ChatSession(
          id: 's-missing-persona',
          title: '非法会话',
          personaId: 'not-exists',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}
