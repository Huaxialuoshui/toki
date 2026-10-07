import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings/settings_controller.dart';
import '../application/app_startup.dart';
import '../application/notification/reminder_sync.dart';
import '../application/theme/theme_controller.dart';
import '../application/widget/widget_controller.dart';
import '../application/theme/theme_mapper.dart';
import '../core/extensions/l10n_extension.dart';
import '../domain/entities/glass_style.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/theme_config_scope.dart';
import 'router.dart';

/// 应用根组件。
///
/// * `ThemeData` 来自 [themeResolutionProvider]（颜色 / 字体 / 组件主题）；
/// * 透明度与模糊由 `GlassTheme` 单独向下传递，不混进 `ThemeData`；
/// * 语言默认跟随系统，系统语言不受支持时回退中文。
class TokiApp extends ConsumerWidget {
  const TokiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 触发启动初始化（debug 构建下为数据库写入示例数据）。
    ref.watch(appStartupProvider);
    // 通知：请求权限 + 首次排期同步，并在提醒变化时自动重排。
    ref.watch(notificationStartupProvider);
    ref.watch(reminderAutoSyncProvider);
    // 日程 / 倒计时 / 小组件外观一变，就把状态推给原生桌面小组件。
    ref.watch(widgetAutoSyncProvider);

    final resolution = ref.watch(themeResolutionProvider);
    final locale = ref.watch(localeControllerProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      theme: buildThemeData(resolution.light),
      darkTheme: buildThemeData(resolution.dark),
      themeMode: resolution.mode,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (deviceLocale, supported) {
        if (locale != null) return locale;
        if (deviceLocale != null) {
          for (final candidate in supported) {
            if (candidate.languageCode == deviceLocale.languageCode) {
              return candidate;
            }
          }
        }
        return const Locale('zh');
      },
      routerConfig: router,
      builder: (context, child) {
        final brightness = switch (resolution.mode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        final config = resolution.configFor(brightness);
        return ThemeConfigScope(
          config: config,
          child: GlassTheme(
            style: GlassStyle.fromThemeConfig(config),
            // 字号缩放在这里生效：ThemeData 的文本样式在部分平台没有显式 fontSize，
            // 用 textScaler 才能对所有文字生效。
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(config.fontScale),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
