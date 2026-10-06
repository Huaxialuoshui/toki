import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// release 构建（或用户手动清空数据后）数据库是空的，
/// 界面必须给出空状态而不是空白或者假数据。
void main() {
  tokiWidgetTest('空数据库时首页显示空状态', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1280, 900),
      seedDatabase: false,
    );

    // 今天没有安排 / 没有倒计时 / 没有未来事件
    expect(find.text('Nothing scheduled today'), findsWidgets);
    expect(find.text('No countdowns yet'), findsOneWidget);
    expect(find.text("Today's schedule"), findsOneWidget);
  });

  tokiWidgetTest('空数据库时倒计时页显示空状态', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1280, 900),
      seedDatabase: false,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/countdown')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No countdowns yet'), findsWidgets);
    expect(find.text('Pinned'), findsNothing);
  });

  tokiWidgetTest('空数据库时日历页显示空状态', (tester) async {
    await pumpTokiApp(
      tester,
      size: const Size(1280, 900),
      seedDatabase: false,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/calendar')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No events on this day'), findsOneWidget);
  });
}
