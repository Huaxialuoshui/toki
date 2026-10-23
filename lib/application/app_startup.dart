import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo/demo_seed.dart';
import '../data/repositories/repository_providers.dart';
import '../infrastructure/clock_provider.dart';
import 'planning/daily_automation_service.dart';

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
  await ref.read(dailyAutomationServiceProvider).runCatchUp();
  if (!ref.watch(demoSeedEnabledProvider)) return;
  final database = ref.watch(appDatabaseProvider);
  await seedDemoDataIfEmpty(
    database,
    now: ref.watch(clockProvider).now(),
  );
});
