import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/presentation/shell/shell_layouts.dart';

import '../helpers/test_app.dart';

void main() {
  group('响应式断点', () {
    tokiWidgetTest('< 600 使用手机布局（底部导航）', (tester) async {
      await pumpTokiApp(tester, size: const Size(599, 900));
      expect(find.byKey(kMobileShellKey), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    tokiWidgetTest('600 - 999 使用平板布局（Rail）', (tester) async {
      await pumpTokiApp(tester, size: const Size(600, 900));
      expect(find.byKey(kTabletShellKey), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpTokiApp(tester, size: const Size(999, 900));
      expect(find.byKey(kTabletShellKey), findsOneWidget);
    });

    tokiWidgetTest('>= 1000 使用桌面布局（Sidebar）', (tester) async {
      await pumpTokiApp(tester, size: const Size(1000, 900));
      expect(find.byKey(kDesktopShellKey), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Toki'), findsOneWidget);
    });

    tokiWidgetTest('桌面 Sidebar 可以折叠', (tester) async {
      await pumpTokiApp(tester, size: const Size(1280, 900));
      expect(find.text('Toki'), findsOneWidget);

      await tester.tap(find.byKey(kSidebarToggleKey));
      await tester.pumpAndSettle();

      expect(find.text('Toki'), findsNothing);
      expect(find.byKey(kDesktopShellKey), findsOneWidget);
    });
  });

  group('导航', () {
    tokiWidgetTest('五个目的地都可以到达（桌面）', (tester) async {
      await pumpTokiApp(tester, size: const Size(1280, 900));

      expect(find.text("Today's schedule"), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey<String>('sidebar-tile-/calendar')));
      await tester.pumpAndSettle();
      expect(find.text('Month'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey<String>('sidebar-tile-/countdown')));
      await tester.pumpAndSettle();
      expect(find.text('Pinned'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('sidebar-tile-/ai')));
      await tester.pumpAndSettle();
      // 测试环境没有配置 AI 服务商，AI 页显示配置提示与入口。
      expect(find.text('No AI provider configured yet'), findsOneWidget);
      expect(find.text('Open settings'), findsWidgets);

      await tester
          .tap(find.byKey(const ValueKey<String>('sidebar-tile-/settings')));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey<String>('sidebar-tile-/home')));
      await tester.pumpAndSettle();
      expect(find.text("Today's schedule"), findsOneWidget);
    });

    tokiWidgetTest('手机端底部导航可以切换页面', (tester) async {
      await pumpTokiApp(tester, size: const Size(420, 900));
      expect(find.text("Today's schedule"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Month'), findsOneWidget);
    });
  });
}
