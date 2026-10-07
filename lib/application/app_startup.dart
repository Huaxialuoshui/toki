import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/daily_digest.dart';
import '../data/demo/demo_seed.dart';
import '../data/repositories/repository_providers.dart';
import '../infrastructure/clock_provider.dart';
import 'ai/daily_digest_service.dart';

/// 是否允许在启动时写入示例数据。
///
/// 默认：debug 构建开启、release 关闭。测试里会 override 成 false，
/// 由测试自己决定要不要预置数据。
final demoSeedEnabledProvider = Provider<bool>((ref) => kDebugMode);

/// 应用启动时的一次性初始化。
///
/// 目前只做一件事：debug 构建下、数据库为空时写入示例数据。
/// release 构建不会写入任何数据（用户从空库开始）。
final appStartupProvider = FutureProvider<void>((ref) async {
  await _maybeGenerateDigest(ref);
  if (!ref.watch(demoSeedEnabledProvider)) return;
  final database = ref.watch(appDatabaseProvider);
  await seedDemoDataIfEmpty(
    database,
    now: ref.watch(clockProvider).now(),
  );
});

/// 按设置里的开关，在合适的时间段自动生成"今日计划 / 今日总结"。
///
/// 中午前生成计划、傍晚后生成总结，且每天只生成一次；失败不影响启动。
Future<void> _maybeGenerateDigest(Ref ref) async {
  final service = ref.read(dailyDigestServiceProvider);
  final hour = ref.read(clockProvider).now().hour;
  final kind = hour < 12
      ? DailyDigestKind.morning
      : (hour >= 18 ? DailyDigestKind.evening : null);
  if (kind == null || !service.isEnabled(kind)) return;
  try {
    await service.ensureToday(kind);
  } on Object catch (error) {
    debugPrint('生成每日摘要失败：$error');
  }
}
