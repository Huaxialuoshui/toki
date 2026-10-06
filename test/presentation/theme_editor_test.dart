import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/theme/theme_controller.dart';
import 'package:toki/application/theme/theme_mapper.dart';
import 'package:toki/application/theme/theme_presets.dart';
import 'package:toki/core/constants/calendar_options.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/theme_config.dart';

import '../helpers/test_app.dart';

/// Phase 11：主题编辑器（实时预览 / 保存为用户主题 / JSON 导入导出 / 删除）。
///
/// 与 `calendar_crud_test` 一样：`*.icon` 按钮会构造私有子类，
/// `find.byType(FilledButton)` 匹配不到，所以统一用文案定位。
void main() {
  const Size surface = Size(1400, 1600);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester, String entry) async {
    await openSettings(tester);
    await tapText(tester, entry);
  }

  /// 当前 `MaterialApp` 实际渲染的浅色主题（草稿会即时反映到这里）。
  ThemeData appTheme(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  tokiWidgetTest('主题编辑器实时改变全局主题，关闭后撤销预览', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openEditor(tester, 'Edit current theme');

    expect(appTheme(tester).colorScheme.primary,
        ThemePresets.defaultTheme.primaryColor);

    // 换一个主色：整个应用（包括下面的预览卡片）立即变色。
    await tester.tap(find.byKey(const ValueKey<String>('swatch-primary-2')));
    await tester.pumpAndSettle();
    expect(appTheme(tester).colorScheme.primary, EventPalette.colors[2]);

    // 关闭编辑器：草稿撤销，回到已保存的主题（默认预设）。
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(appTheme(tester).colorScheme.primary,
        ThemePresets.defaultTheme.primaryColor);
    expect(find.text('Edit current theme'), findsOneWidget, reason: '应回到设置页');
  });

  tokiWidgetTest('保存为主题会写入数据库并选中它', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openEditor(tester, 'New theme');

    await tester.tap(find.byKey(const ValueKey<String>('swatch-primary-1')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Save theme');

    // 名称对话框：填名字后保存。
    await tester.enterText(find.byType(TextField).last, 'Ocean');
    await tapText(tester, 'Save');

    final container = containerOf(tester);
    final themes = await container.read(themeRepositoryProvider).getAll();
    expect(themes, hasLength(1));
    expect(themes.single.name, 'Ocean');
    expect(themes.single.primaryColor, EventPalette.colors[1]);
    expect(container.read(themeControllerProvider).themeId, themes.single.id);

    // 选择写入 shared_preferences（应用级轻量设置）。
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('settings.themeId'), themes.single.id);
  });

  tokiWidgetTest('另存为新主题会新增第二条用户主题', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openEditor(tester, 'New theme');

    await tapText(tester, 'Save theme');
    await tester.enterText(find.byType(TextField).last, 'First');
    await tapText(tester, 'Save');

    // 现在正在编辑一个用户主题，会出现「另存为新主题」。
    await tapText(tester, 'Save as new');
    await tester.enterText(find.byType(TextField).last, 'Second');
    await tapText(tester, 'Save');

    final container = containerOf(tester);
    final themes = await container.read(themeRepositoryProvider).getAll();
    expect(themes.map((ThemeConfig t) => t.name),
        containsAll(<String>['First', 'Second']));
    expect(
        container.read(themeControllerProvider).themeId,
        isNot(
          themes.firstWhere((ThemeConfig t) => t.name == 'First').id,
        ));
  });

  tokiWidgetTest('导入合法 JSON 新增主题，非法 JSON 报错且不写入', (tester) async {
    // 导入对话框会先读剪贴板做预填；测试环境需要显式提供 handler。
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async => call.method == 'Clipboard.getData'
          ? <String, dynamic>{'text': ''}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openEditor(tester, 'New theme');
    final container = containerOf(tester);

    const String json =
        '{"schemaVersion":1,"name":"Imported","brightness":"dark",'
        '"primaryColor":4283215696,"borderRadius":20,"cardOpacity":0.9,'
        '"blurAmount":12,"shadowStrength":0.5,"animationEnabled":false}';

    await tapText(tester, 'Import JSON');
    await tester.enterText(find.byType(TextField).last, json);
    await tapText(tester, 'Save');

    var themes = await container.read(themeRepositoryProvider).getAll();
    expect(themes, hasLength(1));
    expect(themes.single.name, 'Imported');
    expect(themes.single.isDark, isTrue);
    expect(themes.single.blurAmount, 12);
    expect(themes.single.shadowStrength, 0.5);

    // 等第一条 SnackBar 自动消失，否则下一条会排队而不是立刻显示。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 垃圾输入：提示错误，数据库不变。
    await tapText(tester, 'Import JSON');
    await tester.enterText(find.byType(TextField).last, 'not-json');
    await tapText(tester, 'Save');

    expect(find.textContaining('Import failed'), findsOneWidget);
    themes = await container.read(themeRepositoryProvider).getAll();
    expect(themes, hasLength(1));
  });

  tokiWidgetTest('删除用户主题后回落到默认预设', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    final container = containerOf(tester);
    final repository = container.read(themeRepositoryProvider);

    const ThemeConfig custom = ThemeConfig(
      id: 'user-theme-1',
      name: 'Night',
      brightness: Brightness.dark,
      primaryColor: Color(0xFF7C8CFF),
      secondaryColor: Color(0xFFB48CFF),
      backgroundColor: Color(0xFF0E1016),
      surfaceColor: Color(0xFF1A1D26),
      textColor: Color(0xFFECEFF8),
    );
    await repository.upsert(custom);
    container.read(themeControllerProvider.notifier).selectTheme(custom.id);
    await openSettings(tester);

    expect(appTheme(tester).colorScheme.primary, custom.primaryColor);
    expect(find.text('Night'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('delete-theme-user-theme-1')),
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Delete');

    expect(await repository.getAll(), isEmpty);
    expect(
      container.read(themeControllerProvider).themeId,
      ThemePresets.defaultId,
    );
    expect(find.text('Theme deleted'), findsOneWidget);
  });

  group('主题解析与草稿', () {
    test('草稿驱动全局主题，清空后回到已保存主题', () async {
      final container = await createTestContainer(clock: FixedClock(kTestNow));
      expect(
        container.read(themeResolutionProvider).light.id,
        ThemePresets.defaultId,
      );

      container.read(themeDraftProvider.notifier).state =
          ThemePresets.darkTheme;
      final draftResolution = container.read(themeResolutionProvider);
      expect(draftResolution.light.id, ThemePresets.darkId);
      expect(draftResolution.dark.id, ThemePresets.darkId);
      expect(draftResolution.mode, ThemeMode.dark);
      expect(buildThemeData(draftResolution.dark).brightness, Brightness.dark);

      container.read(themeDraftProvider.notifier).state = null;
      expect(
        container.read(themeResolutionProvider).light.id,
        ThemePresets.defaultId,
      );
    });

    test('选中数据库里的用户主题后解析为该主题', () async {
      final container = await createTestContainer(clock: FixedClock(kTestNow));
      const ThemeConfig custom = ThemeConfig(
        id: 'user-theme-2',
        name: 'Forest',
        brightness: Brightness.light,
        primaryColor: Color(0xFF12B5A5),
        secondaryColor: Color(0xFF3DBF7A),
        backgroundColor: Color(0xFFF2FBF8),
        surfaceColor: Color(0xFFFFFFFF),
        textColor: Color(0xFF12211C),
        shadowStrength: 0.1,
      );
      await container.read(themeRepositoryProvider).upsert(custom);
      await container.read(userThemesProvider.future);

      container.read(themeControllerProvider.notifier).selectTheme(custom.id);
      final resolution = container.read(themeResolutionProvider);
      expect(resolution.light.name, 'Forest');
      expect(resolution.light.primaryColor, custom.primaryColor);
      expect(resolution.mode, ThemeMode.light);
    });
  });
}
