import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  tokiWidgetTest('设置首页只展示分类，并能进入三级具体设置', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1400, 1000),
      seedDatabase: false,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();

    for (final key in <String>[
      'settings-menu-appearance',
      'settings-menu-ai',
      'settings-menu-schedule',
      'settings-menu-time',
      'settings-menu-widget',
      'settings-menu-data',
      'settings-menu-about',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }
    expect(
        find.byKey(const ValueKey<String>('app-bg-type-image')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('settings-menu-appearance')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-appearance-theme')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-appearance-background')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('settings-appearance-background')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('app-bg-type-image')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-icon-pick-/home')),
        findsOneWidget);
  });

  tokiWidgetTest('手机宽度下设置分类与详情页可正常滚动', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(420, 900),
      seedDatabase: false,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    final appearance = find.byKey(
      const ValueKey<String>('settings-menu-appearance'),
    );
    await tester.ensureVisible(appearance);
    await tester.tap(appearance);
    await tester.pumpAndSettle();

    final theme = find.byKey(
      const ValueKey<String>('settings-appearance-theme'),
    );
    await tester.ensureVisible(theme);
    await tester.tap(theme);
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('settings-back')), findsOneWidget);
  });
}
