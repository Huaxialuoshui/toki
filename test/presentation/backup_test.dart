import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/backup/backup_providers.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/backup.dart';
import 'package:toki/infrastructure/backup/backup_file_store.dart';

import '../helpers/test_app.dart';

/// Phase 12：设置页的「备份与恢复」。
void main() {
  const Size surface = Size(1400, 1800);

  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('toki-backup-ui');
  });

  tearDown(() async {
    if (directory.existsSync()) {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        // Windows 上偶发"文件仍被占用"，测试临时目录留着也无所谓。
      }
    }
  });

  List<Override> overridesFor(Directory dir) => <Override>[
        backupFileStoreProvider
            .overrideWithValue(BackupFileStore(directory: dir)),
      ];

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('sidebar-tile-/settings')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  /// 对话框里的按钮 / 输入框：Shell 的 IndexedStack 会把其它分支的 widget
  /// 也留在树里（例如 AI 页的聊天输入框），所以必须限定在对话框内查找。
  Finder inDialog(Finder matching) => find.descendant(
        of: find.byType(AlertDialog),
        matching: matching,
      );

  Future<void> tapDialogText(WidgetTester tester, String text) async {
    await tester.tap(inDialog(find.text(text)).last);
    await tester.pumpAndSettle();
  }

  /// 文件 / 数据库的异步收尾不驱动帧，`pumpAndSettle` 可能在结果出来之前就返回，
  /// 所以这里按"目标出现"来等。
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 60,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  /// 剪贴板在测试里没有默认实现，需要自己接一个假的。
  List<MethodCall> mockClipboard(WidgetTester tester, {String? text}) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': text ?? ''};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return calls;
  }

  tokiWidgetTest('设置页显示备份区块与操作入口', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      extraOverrides: overridesFor(directory),
    );
    await openSettings(tester);

    await tester.ensureVisible(find.text('Export backup'));
    await tester.pumpAndSettle();

    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Restore from file'), findsOneWidget);
    expect(find.text('Paste JSON'), findsOneWidget);
    expect(find.text('Include API keys'), findsOneWidget);
    expect(find.text('Backup folder'), findsOneWidget);
  });

  tokiWidgetTest('导出备份：落盘 + 复制到剪贴板 + 提示路径', (tester) async {
    final calls = mockClipboard(tester);
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: true,
      extraOverrides: overridesFor(directory),
    );
    await openSettings(tester);
    // 导出会写真实文件：widget 测试的 FakeAsync 环境不会投递 dart:io 的完成事件，
    // 所以这一步必须放进 runAsync（应用代码本身不需要特殊处理）。
    await tester.runAsync(() async {
      await tapText(tester, 'Export backup');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    await pumpUntil(tester, find.textContaining('Backup saved to'));

    // 文件落盘
    final files = directory
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.json'))
        .toList();
    expect(files, hasLength(1));

    // 剪贴板拿到的是同一份 JSON，且 API Key 默认被抹掉
    final setData = calls.firstWhere(
      (MethodCall call) => call.method == 'Clipboard.setData',
    );
    final payload = jsonDecode((setData.arguments as Map)['text'] as String)
        as Map<String, dynamic>;
    expect(payload['format'], kBackupFormatTag);
    expect(payload['includesApiKeys'], isFalse);
    final providers =
        (payload['tables'] as Map)['ai_providers'] as List<dynamic>;
    for (final row in providers) {
      expect((row as Map)['apiKey'], isNull);
    }

    expect(find.textContaining('Backup saved to'), findsOneWidget);
    expect(find.text(files.single.path), findsOneWidget, reason: '界面显示导出路径');
  });

  tokiWidgetTest('粘贴 JSON 并覆盖恢复：数据真的写回', (tester) async {
    mockClipboard(tester);
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      extraOverrides: overridesFor(directory),
    );
    final container = containerOf(tester);
    expect(await container.read(calendarRepositoryProvider).getAll(), isEmpty);

    const backup = '{"format":"toki-backup","formatVersion":1,'
        '"schemaVersion":3,"exportedAt":"2026-10-06T21:30:00.000",'
        '"includesApiKeys":false,"tables":{"calendar_events":[{'
        '"id":"restored-1","title":"恢复进来的日程","description":null,'
        '"startTime":1792508400000,"endTime":1792515600000,"allDay":false,'
        '"location":null,"categoryId":null,"color":null,"repeatRule":null,'
        '"reminderMinutes":null,"status":"scheduled",'
        '"createdAt":1792508400000,"updatedAt":1792508400000}]}}';

    await openSettings(tester);
    await tapText(tester, 'Paste JSON');
    await pumpUntil(tester, inDialog(find.byType(TextField)));
    await tester.enterText(inDialog(find.byType(TextField)).last, backup);
    await tapDialogText(tester, 'Save');
    await pumpUntil(tester, find.text('Restore this backup?'));

    // 确认框里能看到这次备份的摘要，然后选「覆盖」。
    expect(find.text('Restore this backup?'), findsOneWidget);
    expect(find.textContaining('1 rows'), findsWidgets);
    await tapDialogText(tester, 'Replace');
    await pumpUntil(tester, find.textContaining('Restored'));

    final events = await container.read(calendarRepositoryProvider).getAll();
    expect(events, hasLength(1));
    expect(events.single.title, '恢复进来的日程');
    expect(find.textContaining('Restored'), findsOneWidget);
  });

  tokiWidgetTest('粘贴非法 JSON：只提示错误，不动数据', (tester) async {
    mockClipboard(tester);
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: true,
      extraOverrides: overridesFor(directory),
    );
    final container = containerOf(tester);
    final before = await container.read(calendarRepositoryProvider).getAll();

    await openSettings(tester);
    await tapText(tester, 'Paste JSON');
    await pumpUntil(tester, inDialog(find.byType(TextField)));
    await tester.enterText(
        inDialog(find.byType(TextField)).last, 'not-a-backup');
    await tapDialogText(tester, 'Save');
    await pumpUntil(tester, find.text('That is not valid JSON.'));

    expect(find.text('That is not valid JSON.'), findsOneWidget);
    expect(find.text('Restore this backup?'), findsNothing);
    expect(await container.read(calendarRepositoryProvider).getAll(), before);
  });
}
