import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'application/notification/notification_providers.dart';
import 'infrastructure/notification/flutter_local_notification_service.dart';
import 'infrastructure/storage/app_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用级轻量设置（语言 / 主题 id / 跟随系统 / 微调 / 首次启动）在启动时一次性
  // 读出，后续 provider 可以同步读取，避免到处 await。
  final preferences = await SharedPreferences.getInstance();

  // 本地通知：Android 用系统通知、Windows 用系统 Toast（同一个包的两个实现）。
  final notifications = FlutterLocalNotificationService();
  await notifications.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const TokiApp(),
    ),
  );
}
