import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/app/app.dart';
import 'package:toki/application/app_startup.dart';
import 'package:toki/application/notification/notification_providers.dart';
import 'package:toki/application/ai/chat_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/demo/demo_seed.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/data/repositories/drift_ai_repository.dart';

import 'sqlite_bootstrap.dart';
import 'fake_notification_service.dart';

/// 测试中统一使用的固定时间：2026-10-06 10:00（星期二）。
final DateTime kTestNow = DateTime(2026, 10, 6, 10);

/// 当前测试使用的内存数据库（由 [pumpTokiApp] 记录，供收尾时关闭）。
AppDatabase? _activeDatabase;

/// 与 `testWidgets` 等价，但会在测试体结束后自动卸载 App 并关闭数据库。
///
/// 为什么需要这一步：drift 在取消查询流时会安排一个零延时 Timer 做缓存清理。
/// 在 widget 测试的 FakeAsync 环境里，如果不显式收尾，flutter_test 会在测试
/// 结束时抛 "A Timer is still pending"（drift 源码注释也建议在 widget 测试里
/// `await database.close()`）。
@isTest
void tokiWidgetTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (WidgetTester tester) async {
    try {
      await body(tester);
    } finally {
      await _disposeTokiApp(tester);
    }
  });
}

Future<void> _disposeTokiApp(WidgetTester tester) async {
  // 先卸载整棵树（ProviderScope 会 dispose，drift 流随之取消）。
  await tester.pumpWidget(const SizedBox.shrink());

  final database = _activeDatabase;
  _activeDatabase = null;
  if (database != null) {
    // 启动关闭，然后推帧让 drift 内部的收尾 Timer 执行。
    // 注意：不能先 await close()——它要等那些 Timer，而 FakeAsync 时钟只有
    // 通过 pump 才会前进，直接 await 会死锁。
    var closed = false;
    unawaited(
      database.close().whenComplete(() => closed = true),
    );
    for (var i = 0; i < 20 && !closed; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  // 再推一帧，确保所有收尾 Timer 都已执行。
  await tester.pump(const Duration(milliseconds: 20));
}

/// 创建一个注入了 mock prefs 与固定时钟的 ProviderContainer。
Future<ProviderContainer> createTestContainer({
  Clock? clock,
  Map<String, Object> initialPreferences = const <String, Object>{},
  bool seedDatabase = false,
  FakeNotificationService? notifications,
  AiProvider? aiProvider,
  AiProviderConfig? aiConfig,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  ensureSqliteLibraryAvailable();
  SharedPreferences.setMockInitialValues(initialPreferences);
  final preferences = await SharedPreferences.getInstance();
  final database = AppDatabase.memory();
  final effectiveClock = clock ?? FixedClock(kTestNow);
  if (seedDatabase) {
    await seedDemoDataIfEmpty(database, now: effectiveClock.now());
  }
  if (aiConfig != null) {
    await DriftAiProviderRepository(database).upsert(aiConfig);
  }
  final container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(preferences),
      clockProvider.overrideWithValue(effectiveClock),
      appDatabaseProvider.overrideWithValue(database),
      // 测试自己决定是否预置数据，关掉启动时的自动写入。
      demoSeedEnabledProvider.overrideWithValue(false),
      notificationServiceProvider.overrideWithValue(
        notifications ?? FakeNotificationService(),
      ),
      if (aiProvider != null)
        aiProviderFactoryProvider.overrideWithValue(() => aiProvider),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await database.close();
  });
  return container;
}

/// 启动整套 App（包含路由、主题、i18n）。
Future<void> pumpTokiApp(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  Clock? clock,
  Map<String, Object> initialPreferences = const <String, Object>{},
  bool seedDatabase = true,
  FakeNotificationService? notifications,
  AiProvider? aiProvider,
  AiProviderConfig? aiConfig,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  ensureSqliteLibraryAvailable();
  SharedPreferences.setMockInitialValues(initialPreferences);
  final preferences = await SharedPreferences.getInstance();
  final database = AppDatabase.memory();
  final effectiveClock = clock ?? FixedClock(kTestNow);
  if (seedDatabase) {
    await seedDemoDataIfEmpty(database, now: effectiveClock.now());
  }
  if (aiConfig != null) {
    await DriftAiProviderRepository(database).upsert(aiConfig);
  }
  _activeDatabase = database;

  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(effectiveClock),
        appDatabaseProvider.overrideWithValue(database),
        demoSeedEnabledProvider.overrideWithValue(false),
        notificationServiceProvider.overrideWithValue(
          notifications ?? FakeNotificationService(),
        ),
        if (aiProvider != null)
          aiProviderFactoryProvider.overrideWithValue(() => aiProvider),
      ],
      child: const TokiApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
