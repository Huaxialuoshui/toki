import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/calendar_category.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/infrastructure/clock_provider.dart';

import '../helpers/test_app.dart';

/// 重复日程 / 自定义提醒 / 分类管理 的界面联调（P1）。
void main() {
  const Size surface = Size(1400, 1800);

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  Future<void> openCalendar(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/calendar')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  /// 编辑器弹窗的字段比可视区域长，操作下半部分前先把弹窗内容往上拖。
  Future<void> scrollEditor(WidgetTester tester, double dy) async {
    final scrollable = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollable, findsWidgets, reason: '编辑器应当是滚动容器');
    await tester.drag(scrollable.first, Offset(0, dy));
    await tester.pumpAndSettle();
  }

  tokiWidgetTest('新建日程可以设为每天重复，并落到数据库', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openCalendar(tester);
    await tapText(tester, 'New event');
    await tester.enterText(find.byType(TextFormField).first, '晨会');
    await tester.pumpAndSettle();

    // 重复下拉改成"每天"
    await scrollEditor(tester, -400);
    await tapText(tester, 'Does not repeat');
    await tapText(tester, 'Every day');

    await tapText(tester, 'Save');

    final container = containerOf(tester);
    final events = await container.read(calendarRepositoryProvider).getAll();
    expect(events, hasLength(1));
    expect(events.single.repeatRule, 'daily');
  });

  tokiWidgetTest('自定义提醒提前量（90 分钟）会保存并在界面上显示', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    await openCalendar(tester);
    await tapText(tester, 'New event');
    await tester.enterText(find.byType(TextFormField).first, '复盘');
    await tester.pumpAndSettle();

    await scrollEditor(tester, -400);
    await tapText(tester, 'Custom lead time');
    await tester.enterText(find.byType(TextField).last, '90');
    await tester
        .tap(find.byKey(const ValueKey<String>('reminder-custom-save')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Save');

    final container = containerOf(tester);
    final event =
        (await container.read(calendarRepositoryProvider).getAll()).single;
    expect(event.reminderMinutes, 90);

    // 提醒行同步成 90 分钟前的通知
    final reminders = await container.read(reminderRepositoryProvider).getAll();
    expect(reminders, hasLength(1));
    expect(
      event.startTime.difference(reminders.single.triggerTime).inMinutes,
      90,
    );
  });

  tokiWidgetTest('设置页可以新建与删除日历分类', (tester) async {
    await pumpTokiApp(tester, size: surface, seedDatabase: false);
    final container = containerOf(tester);
    await openSettings(tester);

    await tester
        .ensureVisible(find.byKey(const ValueKey<String>('category-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '工作');
    await tester.tap(find.byKey(const ValueKey<String>('category-color-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('category-save')));
    await tester.pumpAndSettle();

    final repository = container.read(calendarCategoryRepositoryProvider);
    var categories = await repository.getAll();
    expect(categories.map((CalendarCategory c) => c.name), contains('工作'));
    final created = categories.single;

    // 删掉分类：先给事件挂上它，再删，事件应当被摘成"无分类"
    final now = container.read(clockProvider).now();
    await container.read(calendarRepositoryProvider).upsert(
          CalendarEvent(
            id: 'e1',
            title: '写周报',
            startTime: now,
            endTime: now.add(const Duration(hours: 1)),
            categoryId: created.id,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(ValueKey<String>('category-delete-${created.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('category-delete-confirm')),
    );
    await tester.pumpAndSettle();

    categories = await repository.getAll();
    expect(categories, isEmpty);
    final event =
        await container.read(calendarRepositoryProvider).findById('e1');
    expect(event!.categoryId, isNull, reason: '事件保留，只是没有分类了');
  });
}
