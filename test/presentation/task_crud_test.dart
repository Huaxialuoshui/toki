import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  const Size surface = Size(1400, 1400);

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('首页新建任务后可以进入任务页并完成', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);

    await tapText(tester, 'New task');
    await tester.enterText(find.byType(TextFormField).first, 'Buy milk');
    await tapText(tester, 'Save');
    expect(find.text('Buy milk'), findsOneWidget);

    await tapText(tester, 'Buy milk');
    expect(find.text('Open 1'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('No open tasks'), findsOneWidget);

    await tapText(tester, 'Completed 1');
    expect(find.text('Buy milk'), findsOneWidget);
  });

  tokiWidgetTest('任务标题为空时不保存并显示字段错误', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);

    await tapText(tester, 'New task');
    await tapText(tester, 'Save');

    expect(find.text('Enter a task title'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
