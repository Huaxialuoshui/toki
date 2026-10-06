import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// 日历页的增删改与视图切换。
///
/// 注意：`FilledButton.icon` / `TextButton.icon` 会构造私有子类，
/// `find.byType(FilledButton)` 匹配不到，因此这里统一用文案定位。
void main() {
  const Size surface = Size(1400, 1400);

  Future<void> openCalendar(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/calendar')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text, {bool last = false}) async {
    final finder = find.text(text);
    await tester.ensureVisible(last ? finder.last : finder.first);
    await tester.pumpAndSettle();
    await tester.tap(last ? finder.last : finder.first);
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('新建日程：保存后出现在当天列表', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openCalendar(tester);

    await tapText(tester, 'New event');
    await tester.enterText(find.byType(TextFormField).first, '产品评审');
    await tapText(tester, 'Save');

    expect(find.text('Save'), findsNothing, reason: '编辑器应已关闭');
    expect(find.text('产品评审'), findsOneWidget);
    expect(find.text('No events on this day'), findsNothing);
  });

  tokiWidgetTest('标题为空时给出校验提示且不保存', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openCalendar(tester);

    await tapText(tester, 'New event');
    await tapText(tester, 'Save');

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  tokiWidgetTest('全天开关会隐藏时间选择按钮', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openCalendar(tester);

    await tapText(tester, 'New event');
    expect(find.byIcon(Icons.schedule).evaluate().length, 2,
        reason: '开始 / 结束各有一个时间按钮');

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.schedule).evaluate().length, 0);
  });

  tokiWidgetTest('编辑日程：改标题后列表同步', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCalendar(tester);

    await tapText(tester, '晨间计划');
    expect(find.text('Event detail'), findsOneWidget);

    await tapText(tester, 'Edit');
    await tester.enterText(find.byType(TextFormField).first, '晨间计划（改）');
    await tapText(tester, 'Save');

    expect(find.text('晨间计划（改）'), findsOneWidget);
    expect(find.text('晨间计划'), findsNothing);
  });

  tokiWidgetTest('删除日程：二次确认后从列表消失', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCalendar(tester);

    await tapText(tester, '课程项目截止');
    await tapText(tester, 'Edit');
    await tapText(tester, 'Delete');

    expect(find.text('Delete this event?'), findsOneWidget);
    await tapText(tester, 'Delete', last: true);

    expect(find.text('课程项目截止'), findsNothing);
  });

  tokiWidgetTest('月 / 周 / 日视图可以切换', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCalendar(tester);

    expect(find.byType(GridView), findsOneWidget, reason: '默认月视图');

    await tapText(tester, 'Week');
    expect(find.text('This week'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);

    await tapText(tester, 'Day');
    expect(find.byType(GridView), findsNothing);

    await tapText(tester, 'Month');
    expect(find.byType(GridView), findsOneWidget);
  });
}
