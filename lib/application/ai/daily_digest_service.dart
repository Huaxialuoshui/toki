import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/daily_digest.dart';
import '../../domain/services/ai_provider.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../settings/settings_controller.dart';
import 'ai_providers.dart';
import 'chat_controller.dart';
import 'context_service.dart';
import 'persona_prompt.dart';

/// AI 每日计划 / 每日总结（规格 §14）。
///
/// * 开关默认**关闭**，用户可以分别关闭早间计划与晚间总结；
/// * 生成结果按天存进 `daily_digests`，一天一条，重复生成会覆盖；
/// * 生成失败（没配服务商 / 网络错误）只抛给调用方，不写半条数据。
class DailyDigestService {
  DailyDigestService(this._ref);

  final Ref _ref;

  AppSettingsStore get _store => _ref.read(appSettingsStoreProvider);
  Clock get _clock => _ref.read(clockProvider);

  bool isEnabled(DailyDigestKind kind) => switch (kind) {
        DailyDigestKind.morning => _store.readMorningDigestEnabled(),
        DailyDigestKind.evening => _store.readEveningDigestEnabled(),
      };

  Future<void> setEnabled(DailyDigestKind kind, bool value) async {
    switch (kind) {
      case DailyDigestKind.morning:
        await _store.writeMorningDigestEnabled(value);
      case DailyDigestKind.evening:
        await _store.writeEveningDigestEnabled(value);
    }
  }

  /// 今天这一条（可能还没生成）。
  Future<DailyDigest?> today(DailyDigestKind kind) {
    final now = _clock.now();
    return _ref
        .read(dailyDigestRepositoryProvider)
        .find(DailyDigest.keyFor(now), kind);
  }

  /// 开关打开、且今天还没生成时，生成一条；否则返回已有的那条。
  Future<DailyDigest?> ensureToday(DailyDigestKind kind) async {
    if (!isEnabled(kind)) return null;
    final existing = await today(kind);
    if (existing != null) return existing;
    return generate(kind);
  }

  /// 强制生成（手动点击 / 重新生成）。
  Future<DailyDigest> generate(DailyDigestKind kind) async {
    // 刚启动时服务商配置的流可能还没出值，先等首帧，否则会误判成"没有配置"。
    await _ref.read(aiProvidersProvider.future);
    final config = _ref.read(activeAiConfigProvider);
    if (config == null) {
      throw const AppException('还没有配置 AI 服务商');
    }
    final provider = _ref.read(aiProviderBuilderProvider)(config);
    final now = _clock.now();
    final existing = await today(kind);

    // 复用 ContextService：只把"今天"相关的切片交给模型。
    final context = await _ref
        .read(contextServiceProvider)
        .buildContext(kind == DailyDigestKind.morning ? '今天' : '今天总结');
    final persona = _ref.read(activePersonaProvider);

    final request = AiChatRequest(
      messages: <AiMessage>[
        AiMessage.system(_systemPrompt(persona)),
        AiMessage.user('${_instruction(kind)}\n\n$context'),
      ],
      temperature: 0.4,
      maxTokens: 600,
    );
    final response = await provider.chat(request);
    final content = response.content.trim();
    if (content.isEmpty) {
      throw const AppException('AI 没有返回内容');
    }

    final digest = DailyDigest(
      // 同一天同一种只保留一条：重新生成时复用原来的 id（upsert 覆盖）。
      id: existing?.id ?? generateId('digest', now: now),
      kind: kind,
      dayKey: DailyDigest.keyFor(now),
      content: content,
      createdAt: existing?.createdAt ?? now,
      planId: existing?.planId,
      feedback: existing?.feedback,
      metricsJson: existing?.metricsJson,
      updatedAt: now,
      userEdited: false,
    );
    await _ref.read(dailyDigestRepositoryProvider).upsert(digest);
    return digest;
  }

  String _systemPrompt(AiPersona? persona) {
    // 每日计划 / 总结本身就是日程功能：当前人设是"纯聊天"时不能用它的
    // 扮演提示词写日程摘要，否则会得到一段跑题的剧本。
    final base = PersonaPrompt.isCalendarAssistant(persona)
        ? persona?.systemPrompt?.trim()
        : null;
    if (base != null && base.isNotEmpty) return base;
    return '你是用户的私人日程助手，回答简短、直接、口语化。';
  }

  String _instruction(DailyDigestKind kind) {
    final Locale locale =
        _ref.read(localeControllerProvider) ?? _ref.read(systemLocaleProvider);
    final english = locale.languageCode == 'en';
    if (english) {
      return kind == DailyDigestKind.morning
          ? 'Based on the schedule data below, write a short "Today\'s plan" in Markdown: '
              'one line summarising the focus of the day, then 2-4 bullets with time and item, '
              'and one short reminder at the end. Markdown only, no JSON, do not invent anything.'
          : 'Based on the schedule data below, write a short "Today\'s recap" in Markdown: '
              'what is done, what is still open, and one line for tomorrow. '
              'Markdown only, no JSON, do not invent anything.';
    }
    return kind == DailyDigestKind.morning
        ? '根据下面的日程数据，用 Markdown 写一份简短的「今日计划」：'
            '先用一句话概括今天的重心，再用 2-4 条要点列出时间与事项，最后给一句提醒。'
            '只输出 Markdown，不要贴 JSON，不要编造数据里没有的信息。'
        : '根据下面的日程数据，用 Markdown 写一份简短的「今日总结」：'
            '已经结束的事项、还没完成的、以及一句给明天的提醒。'
            '只输出 Markdown，不要贴 JSON，不要编造数据里没有的信息。';
  }
}

final dailyDigestServiceProvider = Provider<DailyDigestService>(
  (ref) => DailyDigestService(ref),
);

/// 系统语言；没有 Flutter binding（纯 Dart 测试）时回落到中文。
final systemLocaleProvider = Provider<Locale>((ref) {
  try {
    return WidgetsBinding.instance.platformDispatcher.locale;
  } on Object {
    return const Locale('zh');
  }
});

/// 今天某一种摘要（供首页展示）。
final todayDigestProvider =
    FutureProvider.autoDispose.family<DailyDigest?, DailyDigestKind>(
  (ref, kind) => ref.watch(dailyDigestServiceProvider).today(kind),
);
