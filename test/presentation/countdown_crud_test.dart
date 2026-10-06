import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/presentation/widgets/countdown_card.dart';

import '../helpers/test_app.dart';

void main() {
  const Size surface = Size(1400, 1400);

  Future<void> openCountdown(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/countdown')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(
    WidgetTester tester,
    String text, {
    bool last = false,
  }) async {
    final finder = find.text(text);
    await tester.ensureVisible(last ? finder.last : finder.first);
    await tester.pumpAndSettle();
    await tester.tap(last ? finder.last : finder.first);
    await tester.pumpAndSettle();
  }

  List<String> cardTitles(WidgetTester tester) => tester
      .widgetList<CountdownCard>(find.byType(CountdownCard))
      .map((CountdownCard card) => card.item.title)
      .toList(growable: false);

  tokiWidgetTest('新建倒计时：保存后出现在列表', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openCountdown(tester);

    expect(find.text('No countdowns yet'), findsWidgets);

    await tapText(tester, 'New countdown');
    await tester.enterText(find.byType(TextFormField).first, '雅思考试');
    await tapText(tester, 'Save');

    expect(find.text('雅思考试'), findsOneWidget);
    expect(find.text('No countdowns yet'), findsNothing);
  });

  tokiWidgetTest('编辑倒计时：改标题与显示样式', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCountdown(tester);

    await tapText(tester, '生日');
    expect(find.text('Edit countdown'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '生日（改）');
    await tapText(tester, 'Big number');
    await tapText(tester, 'Save');

    expect(find.text('生日（改）'), findsOneWidget);
    expect(find.text('生日'), findsNothing);
  });

  tokiWidgetTest('置顶开关会在分组之间移动卡片', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCountdown(tester);

    final pinnedIconsBefore = find.byIcon(Icons.push_pin).evaluate().length;
    expect(pinnedIconsBefore, 4, reason: '两张置顶卡片各有指示图标 + 按钮');

    // 只用卡片内部的图钉按钮：分组的 SectionHeader 图标也是 push_pin_outlined。
    final unpinButtons = find.descendant(
      of: find.byType(CountdownCard),
      matching: find.byIcon(Icons.push_pin_outlined),
    );
    expect(unpinButtons, findsNWidgets(2));

    // 未置顶分组里的第一张是「生日」。
    await tester.tap(unpinButtons.first);
    await tester.pumpAndSettle();

    // 卡片头部指示 + 按钮自身，各多一个实心图钉。
    expect(
      find.byIcon(Icons.push_pin).evaluate().length,
      pinnedIconsBefore + 2,
    );
  });

  tokiWidgetTest('删除倒计时：二次确认后消失', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCountdown(tester);

    await tapText(tester, '晨间计划');
    await tapText(tester, 'Delete');
    expect(find.text('Delete this countdown?'), findsOneWidget);
    await tapText(tester, 'Delete', last: true);

    expect(find.text('晨间计划'), findsNothing);
  });

  tokiWidgetTest('拖动排序：同一分组内顺序会写回', (tester) async {
    await pumpTokiApp(tester, size: surface);
    await openCountdown(tester);

    final before = cardTitles(tester);
    expect(before, <String>['毕业设计答辩', '课程项目截止', '生日', '晨间计划']);

    // 未置顶分组的第一个手柄（前两个是置顶分组）。
    final handle = find.byIcon(Icons.drag_indicator).at(2);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    // 测试平台是 Android → 手柄是"长按后拖动"。
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 400));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    final after = cardTitles(tester);
    expect(after, <String>['毕业设计答辩', '课程项目截止', '晨间计划', '生日']);
  });
}
