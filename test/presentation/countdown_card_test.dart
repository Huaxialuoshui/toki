import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/countdown/countdown_controller.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/l10n/generated/app_localizations.dart';
import 'package:toki/presentation/widgets/countdown_card.dart';

import '../helpers/test_app.dart';

CountdownItem _item({
  required String title,
  required DateTime target,
  CountdownDisplayStyle style = CountdownDisplayStyle.fullText,
  bool pinned = false,
}) {
  return CountdownItem(
    id: 'item-1',
    title: title,
    targetTime: target,
    displayStyle: style,
    isPinned: pinned,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );
}

Widget _harness({required Clock clock, required CountdownItem item}) {
  return ProviderScope(
    overrides: <Override>[clockProvider.overrideWithValue(clock)],
    child: MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 340, child: CountdownCard(item: item)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('秒数每秒刷新，但其它部分保持不动', (tester) async {
    final clock = FixedClock(kTestNow);
    final item = _item(
      title: '毕业答辩',
      target: kTestNow.add(
        const Duration(days: 1, hours: 2, minutes: 3, seconds: 4),
      ),
    );

    await tester.pumpWidget(_harness(clock: clock, item: item));
    await tester.pump();

    expect(find.textContaining('1天 2小时 3分钟'), findsOneWidget);
    expect(find.text('04秒'), findsOneWidget);

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('03秒'), findsOneWidget);
    expect(find.textContaining('1天 2小时 3分钟'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('目标时间已经过去时显示已过去文案', (tester) async {
    final clock = FixedClock(kTestNow);
    final item = _item(
      title: '晨间计划',
      target: kTestNow.subtract(const Duration(minutes: 5, seconds: 30)),
    );

    await tester.pumpWidget(_harness(clock: clock, item: item));
    await tester.pump();

    expect(find.textContaining('已经过去'), findsOneWidget);
    expect(find.textContaining('5分钟'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('大数字样式显示天与 hh:mm:ss', (tester) async {
    final clock = FixedClock(kTestNow);
    final item = _item(
      title: '毕业答辩',
      style: CountdownDisplayStyle.bigNumber,
      pinned: true,
      target: kTestNow.add(
        const Duration(days: 13, hours: 8, minutes: 21, seconds: 5),
      ),
    );

    await tester.pumpWidget(_harness(clock: clock, item: item));
    await tester.pump();

    expect(find.text('13'), findsOneWidget);
    expect(find.text('08:21:05'), findsOneWidget);

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('08:21:04'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('卡片卸载后不残留 Timer', (tester) async {
    final clock = FixedClock(kTestNow);
    final item = _item(
      title: '毕业测验',
      target: kTestNow.add(const Duration(hours: 3)),
    );

    await tester.pumpWidget(_harness(clock: clock, item: item));
    await tester.pump();
    expect(find.textContaining('3小时'), findsOneWidget);

    // 卸载整棵树：如果节拍 Timer 没有被释放，flutter_test 会在测试结束时
    // 报 "A Timer is still pending" 而失败。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
