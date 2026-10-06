import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/test_app.dart';

void main() {
  const Size surface = Size(1400, 1400);

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  /// 设置页很长，先把目标控件滚进可视区域再操作。
  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('设置页显示通知权限状态与操作按钮', (tester) async {
    final notifications = FakeNotificationService(enabled: true);
    await pumpTokiApp(
      tester,
      size: surface,
      notifications: notifications,
    );
    await openSettings(tester);

    await reveal(tester, find.text('Notifications').first);
    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Allowed'), findsOneWidget);
    expect(find.text('Request permission'), findsOneWidget);
    expect(find.text('Send a test notification'), findsOneWidget);
  });

  tokiWidgetTest('未授权时显示未允许，点击请求权限会调用服务', (tester) async {
    final notifications =
        FakeNotificationService(enabled: false, permissionGranted: false);
    await pumpTokiApp(
      tester,
      size: surface,
      notifications: notifications,
    );
    await openSettings(tester);

    await reveal(tester, find.text('Not allowed'));
    expect(find.text('Not allowed'), findsOneWidget);

    await tester.tap(find.text('Request permission'));
    await tester.pumpAndSettle();

    expect(notifications.requestPermissionCount, greaterThan(0));
  });

  tokiWidgetTest('发送测试通知会调用通知服务并提示', (tester) async {
    final notifications = FakeNotificationService();
    await pumpTokiApp(
      tester,
      size: surface,
      notifications: notifications,
    );
    await openSettings(tester);

    await reveal(tester, find.text('Send a test notification'));
    await tester.tap(find.text('Send a test notification'));
    await tester.pumpAndSettle();

    expect(notifications.scheduled, isNotEmpty);
    expect(find.text('Test notification scheduled (5s)'), findsOneWidget);
  });
}
