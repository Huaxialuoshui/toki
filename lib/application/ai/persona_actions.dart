import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/repositories/ai_repository.dart';

/// 人设的写操作入口。
///
/// 删除人设时必须先清掉会话对它的引用（`chat_sessions.persona_id` 有外键），
/// 否则会直接抛 FOREIGN KEY 约束错误——这个细节收敛在这里。
class PersonaActions {
  PersonaActions({
    required AiPersonaRepository personas,
    required ChatRepository chats,
  })  : _personas = personas,
        _chats = chats;

  final AiPersonaRepository _personas;
  final ChatRepository _chats;

  Future<void> save(AiPersona persona) => _personas.upsert(persona);

  Future<void> delete(String personaId) async {
    await _chats.clearPersonaFromSessions(personaId);
    await _personas.deleteById(personaId);
  }
}

final personaActionsProvider = Provider<PersonaActions>(
  (ref) => PersonaActions(
    personas: ref.watch(aiPersonaRepositoryProvider),
    chats: ref.watch(chatRepositoryProvider),
  ),
);
