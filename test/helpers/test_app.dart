import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/app/app.dart';
import 'package:toki/application/countdown/countdown_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

/// 测试中统一使用的固定时间：2026-10-06 10:00（星期二）。
final DateTime kTestNow = DateTime(2026, 10, 6, 10);

/// 创建一个注入了 mock prefs 与固定时钟的 ProviderContainer。
Future<ProviderContainer> createTestContainer({
  Clock? clock,
  Map<String, Object> initialPreferences = const <String, Object>{},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(initialPreferences);
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(preferences),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// 启动整套 App（包含路由、主题、i18n）。
Future<void> pumpTokiApp(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  Clock? clock,
  Map<String, Object> initialPreferences = const <String, Object>{},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(initialPreferences);
  final preferences = await SharedPreferences.getInstance();

  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock ?? FixedClock(kTestNow)),
      ],
      child: const TokiApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
