import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/storage/app_settings_store.dart';

/// 应用支持的语言（规格：中英双语，默认跟随系统、回退中文）。
const List<Locale> supportedLocales = <Locale>[
  Locale('zh'),
  Locale('en'),
];

/// 界面语言控制器。
///
/// state 为 null 表示"跟随系统"。选择持久化在 shared_preferences，
/// 属于应用级轻量设置，不进入数据库。
class LocaleController extends Notifier<Locale?> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  Locale? build() {
    final code = ref.watch(appSettingsStoreProvider).readLocaleCode();
    if (code == null) return null;
    for (final locale in supportedLocales) {
      if (locale.languageCode == code) return locale;
    }
    return null;
  }

  void setLocale(Locale? locale) {
    if (locale == state) return;
    state = locale;
    unawaited(_store.writeLocaleCode(locale?.languageCode));
  }

  void followSystem() => setLocale(null);
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// 是否展示首次启动的引导提示。
class FirstLaunchController extends Notifier<bool> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  bool build() => !ref.watch(appSettingsStoreProvider).readFirstLaunchSeen();

  void dismiss() {
    if (!state) return;
    state = false;
    unawaited(_store.markFirstLaunchSeen());
  }
}

final firstLaunchProvider =
    NotifierProvider<FirstLaunchController, bool>(FirstLaunchController.new);
