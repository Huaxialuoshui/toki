import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 数据库文件名。
const String kDatabaseFileName = 'toki.sqlite';

/// 打开应用数据库：文件放在系统约定的应用数据目录。
///
/// * Android：应用私有目录
/// * Windows：用户 AppData 下的应用目录
///
/// 使用 NativeDatabase.createInBackground 把 SQLite 放到独立 isolate，
/// 避免数据库读写阻塞 UI 线程。
QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, kDatabaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
