// 开发/验证用：往一个已存在的 Toki 数据库里写入一条"紧接着就要触发"的提醒，
// 方便验证"应用被关掉后仍能提醒"。
//
// 用法（Windows，项目根目录下）：
//   $adb = "D:\androidSDK\platform-tools\adb.exe"
//   & $adb exec-out run-as com.toki.toki cat files/toki.sqlite > toki.sqlite
//   dart run tool/seed_device_reminder.dart toki.sqlite 90
//   & $adb push toki.sqlite /sdcard/toki.sqlite
//   & $adb shell run-as com.toki.toki sh -c "cat /sdcard/toki.sqlite > files/toki.sqlite"
//
// 注意：drift 的 dateTime 列以 **Unix 秒** 存储。
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: dart run tool/seed_device_reminder.dart <db-file> <seconds-from-now>');
    exit(64);
  }

  final file = args[0];
  final leadSeconds = int.parse(args[1]);

  // Dart VM 上没有自带的 sqlite3，用测试里缓存的那份动态库。
  final dll = File('.dart_tool/sqlite3.dll');
  if (Platform.isWindows && dll.existsSync()) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open(dll.path),
    );
  }

  final database = sqlite3.open(file);
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final triggerSeconds = nowSeconds + leadSeconds;

  database.execute(
    'INSERT OR REPLACE INTO reminders '
    '(id, event_id, title, trigger_time, repeat_rule, enabled, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    <Object?>[
      'reminder-device-check',
      'demo-event-project',
      'Toki 验证提醒',
      triggerSeconds,
      null,
      1,
      nowSeconds,
    ],
  );

  final rows = database.select(
    'SELECT id, trigger_time FROM reminders ORDER BY trigger_time',
  );
  stdout.writeln('now=$nowSeconds trigger=$triggerSeconds (+${leadSeconds}s)');
  for (final row in rows) {
    stdout.writeln('  ${row['id']} -> ${row['trigger_time']}');
  }
  database.dispose();
}
