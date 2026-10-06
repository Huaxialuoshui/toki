import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';

/// 数据库里的全部人设。
final personasProvider = StreamProvider.autoDispose<List<AiPersona>>(
  (ref) => ref.watch(aiPersonaRepositoryProvider).watchAll(),
);

/// AI 服务商配置（Phase 6 接入请求时会用到）。
final aiProvidersProvider = StreamProvider.autoDispose<List<AiProviderConfig>>(
  (ref) => ref.watch(aiProviderRepositoryProvider).watchAll(),
);
