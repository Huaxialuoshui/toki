import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 备份文件的位置与读写。
///
/// Android 用 `getExternalStorageDirectory()`（`Android/data/<包名>/files`）——
/// 虽然仍是应用专属目录，但插上 USB 就能直接拷出来；拿不到时退回应用私有目录。
/// 桌面平台用系统文档目录。
class BackupFileStore {
  BackupFileStore({Directory? directory}) : _cachedDirectory = directory;

  static const String filePrefix = 'toki-backup-';
  static const String fileSuffix = '.json';

  Directory? _cachedDirectory;

  Future<Directory> backupDirectory() async {
    final cached = _cachedDirectory;
    if (cached != null) return cached;

    Directory? resolved;
    if (Platform.isAndroid) {
      try {
        resolved = await getExternalStorageDirectory();
      } on Object {
        resolved = null;
      }
    }
    resolved ??= await getApplicationDocumentsDirectory();
    await resolved.create(recursive: true);
    _cachedDirectory = resolved;
    return resolved;
  }

  /// 写入一份备份，返回文件。
  ///
  /// 文件名带时间戳，便于在"从文件恢复"里按时间挑选。
  Future<File> write(String json, DateTime now) async {
    final directory = await backupDirectory();
    final file = File(p.join(directory.path, _fileNameFor(now)));
    await file.writeAsString(json, flush: true);
    return file;
  }

  /// 列出目录里的备份文件，新的在前。
  Future<List<BackupFileInfo>> list() async {
    final directory = await backupDirectory();
    final entries = await directory.list().toList();
    final files = <BackupFileInfo>[];
    for (final entry in entries) {
      if (entry is! File) continue;
      final name = p.basename(entry.path);
      if (!name.startsWith(filePrefix) || !name.endsWith(fileSuffix)) continue;
      final stat = await entry.stat();
      files.add(
        BackupFileInfo(
          path: entry.path,
          name: name,
          size: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    files.sort(
      (BackupFileInfo a, BackupFileInfo b) =>
          b.modifiedAt.compareTo(a.modifiedAt),
    );
    return files;
  }

  Future<String> read(BackupFileInfo info) =>
      File(info.path).readAsString(encoding: utf8);

  String _fileNameFor(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    return '$filePrefix$stamp$fileSuffix';
  }
}

/// 一个备份文件的元信息。
class BackupFileInfo {
  const BackupFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedAt,
  });

  final String path;
  final String name;
  final int size;
  final DateTime modifiedAt;
}
