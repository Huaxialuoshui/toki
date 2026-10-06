import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';

/// 数据库里的全部人设。
final personasProvider = StreamProvider.autoDispose<List<AiPersona>>(
  (ref) => ref.watch(aiPersonaRepositoryProvider).watchAll(),
);

/// 当前生效的人设：数据库里第一个；数据库为空时由 UI 回落到内置文案。
final activePersonaProvider = Provider.autoDispose<AiPersona?>((ref) {
  final personas = ref.watch(personasProvider).valueOrNull;
  if (personas == null || personas.isEmpty) return null;
  return personas.first;
});

/// AI 服务商配置（Phase 6 接入请求时会用到）。
final aiProvidersProvider =
    StreamProvider.autoDispose<List<AiProviderConfig>>(
  (ref) => ref.watch(aiProviderRepositoryProvider).watchAll(),
);
