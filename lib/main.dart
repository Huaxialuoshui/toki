import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'infrastructure/storage/app_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 应用级轻量设置（语言 / 主题 id / 跟随系统 / 微调 / 首次启动）在启动时一次性
  // 读出，后续 provider 可以同步读取，避免到处 await。
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const TokiApp(),
    ),
  );
}
