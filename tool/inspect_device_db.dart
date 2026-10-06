// 读取设备上拉下来的 Toki 数据库，打印各表数量与日程列表，便于排查"AI 到底写了没有"。
//
// 用法：
//   adb exec-out run-as com.toki.toki cat files/toki.sqlite > toki.sqlite
//   dart run tool/inspect_device_db.dart toki.sqlite
import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/inspect_device_db.dart <db-file>');
    exit(64);
  }

  final dll = File('.dart_tool/sqlite3.dll');
  if (Platform.isWindows && dll.existsSync()) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open(dll.path),
    );
  }

  final database = sqlite3.open(args.first);
  const tables = <String>[
    'calendar_events',
    'countdowns',
    'reminders',
    'ai_personas',
    'ai_providers',
    'chat_sessions',
    'chat_messages',
  ];
  for (final table in tables) {
    final count = database.select('SELECT COUNT(*) AS c FROM $table').first['c'];
    stdout.writeln('$table: $count');
  }

  stdout.writeln('--- events ---');
  for (final row in database.select(
    'SELECT id, title, start_time, reminder_minutes FROM calendar_events '
    'ORDER BY start_time',
  )) {
    stdout.writeln(
      '${row['id']} | ${row['title']} | ${row['start_time']} | '
      'reminder=${row['reminder_minutes']}',
    );
  }

  stdout.writeln('--- chat messages (last 6) ---');
  for (final row in database.select(
    'SELECT role, tool_name, substr(content, 1, 40) AS content '
    'FROM chat_messages ORDER BY created_at DESC LIMIT 6',
  )) {
    stdout.writeln('${row['role']} | ${row['tool_name']} | ${row['content']}');
  }
  database.dispose();
}
