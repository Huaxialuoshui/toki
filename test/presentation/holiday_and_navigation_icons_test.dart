import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/entities/nav_icon_config.dart';
import 'package:toki/presentation/widgets/adaptive_local_icon.dart';

import '../helpers/test_app.dart';

void main() {
  const Size surface = Size(1400, 1600);

  tokiWidgetTest('日历默认显示公历与农历节日', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/calendar')),
    );
    await tester.pumpAndSettle();

    expect(find.text('National Day'), findsOneWidget);
    expect(find.text('Double Ninth'), findsOneWidget);
    expect(find.text('Cold Dew'), findsOneWidget);
  });

  tokiWidgetTest('设置页为五个导航目的地提供独立图标入口', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettingsPath(
      tester,
      <String>[
        'settings-menu-appearance',
        'settings-appearance-background',
      ],
    );

    for (final route in NavIconConfig.routes) {
      expect(
        find.byKey(ValueKey<String>('nav-icon-pick-$route')),
        findsOneWidget,
      );
    }
  });

  tokiWidgetTest('保存的导航图标会用于三档导航布局', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      initialPreferences: <String, Object>{
        'settings.navIcons': jsonEncode(<String, String>{
          for (final route in NavIconConfig.routes) route: '/tmp$route.png',
        }),
      },
    );

    expect(find.byType(AdaptiveLocalIcon), findsNWidgets(5));
  });

  tokiWidgetTest('关于页不再展示开发阶段和项目路径', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openSettingsPath(tester, <String>['settings-menu-about']);

    expect(find.textContaining('Phase'), findsNothing);
    expect(find.text('Project path'), findsNothing);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Open-source licenses'), findsOneWidget);
  });
}
