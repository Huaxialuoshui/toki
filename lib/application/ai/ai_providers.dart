import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/ai_provider_config.dart';
import '../../domain/services/ai_provider.dart';
import '../../infrastructure/ai/openai_compatible_provider.dart';

/// 数据库里的全部人设。
final personasProvider = StreamProvider.autoDispose<List<AiPersona>>(
  (ref) => ref.watch(aiPersonaRepositoryProvider).watchAll(),
);

/// AI 服务商配置（Phase 6 接入请求时会用到）。
final aiProvidersProvider = StreamProvider.autoDispose<List<AiProviderConfig>>(
  (ref) => ref.watch(aiProviderRepositoryProvider).watchAll(),
);

/// 按**任意配置**构造 [AiProvider]。
///
/// 设置页要用"表单里还没保存的那份配置"去测试连接 / 拉模型列表，
/// 所以留一个可替换的构造入口（测试里 override 成假实现即可）。
final aiProviderBuilderProvider =
    Provider<AiProvider Function(AiProviderConfig)>(
  (ref) =>
      (AiProviderConfig config) => OpenAiCompatibleProvider(config: config),
);
