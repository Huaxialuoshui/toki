import 'dart:convert';
import 'dart:io';

import '../../core/clock.dart';
import '../../core/constants/app_constants.dart';
import '../../data/backup/backup_store.dart';
import '../../domain/entities/backup.dart';
import '../../infrastructure/backup/backup_file_store.dart';

/// 导出结果：JSON 文本 + 落盘位置。
class BackupExportResult {
  const BackupExportResult({required this.json, required this.file});

  final String json;
  final File file;
}

/// 备份与恢复（规格 §12）。
///
/// 分工：`BackupStore` 管数据库读写，`BackupFileStore` 管文件，这一层管
/// **JSON 结构、版本校验与恢复策略**。JSON 结构保持"能看懂"：
///
/// ```json
/// {
///   "format": "toki-backup",
///   "formatVersion": 1,
///   "schemaVersion": 3,
///   "exportedAt": "2026-10-06T21:30:00.000",
///   "appVersion": "0.1.0+1",
///   "includesApiKeys": false,
///   "counts": { "calendar_events": 9, ... },
///   "tables": { "calendar_events": [ { ... } ] }
/// }
/// ```
class BackupService {
  BackupService({
    required BackupStore store,
    required BackupFileStore files,
    Clock clock = const SystemClock(),
    int currentSchemaVersion = 3,
    String appVersion = AppConstants.appVersion,
  })  : _store = store,
        _files = files,
        _clock = clock,
        _currentSchemaVersion = currentSchemaVersion,
        _appVersion = appVersion;

  final BackupStore _store;
  final BackupFileStore _files;
  final Clock _clock;
  final int _currentSchemaVersion;
  final String _appVersion;

  Future<Directory> backupDirectory() => _files.backupDirectory();

  Future<List<BackupFileInfo>> listFiles() => _files.list();

  /// 导出并落盘。
  Future<BackupExportResult> export({required bool includeApiKeys}) async {
    final now = _clock.now();
    final tables = await _store.readAll(includeApiKeys: includeApiKeys);
    final payload = <String, dynamic>{
      'format': kBackupFormatTag,
      'formatVersion': kBackupFormatVersion,
      'schemaVersion': _currentSchemaVersion,
      'exportedAt': now.toIso8601String(),
      'appVersion': _appVersion,
      'includesApiKeys': includeApiKeys,
      'counts': <String, int>{
        for (final entry in tables.entries) entry.key: entry.value.length,
      },
      'tables': tables,
    };
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final file = await _files.write(json, now);
    return BackupExportResult(json: json, file: file);
  }

  /// 解析 + 校验；失败抛 [BackupException]。
  BackupDocument parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (error) {
      throw BackupException(BackupErrorCode.notJson, detail: '$error');
    }
    if (decoded is! Map) {
      throw const BackupException(BackupErrorCode.notJson);
    }
    final map = decoded.cast<String, dynamic>();

    if (map['format'] != kBackupFormatTag) {
      throw const BackupException(BackupErrorCode.notTokiBackup);
    }
    final formatVersion = _asInt(map['formatVersion']);
    if (formatVersion == null || formatVersion > kBackupFormatVersion) {
      throw BackupException(
        BackupErrorCode.unsupportedFormatVersion,
        detail: '${map['formatVersion']}',
      );
    }
    final schemaVersion = _asInt(map['schemaVersion']);
    if (schemaVersion == null || schemaVersion > _currentSchemaVersion) {
      throw BackupException(
        BackupErrorCode.unsupportedSchemaVersion,
        detail: '${map['schemaVersion']}',
      );
    }

    final rawTables = map['tables'];
    if (rawTables is! Map) {
      throw const BackupException(BackupErrorCode.missingTables);
    }
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in BackupTables.ordered) {
      final rows = rawTables[table];
      if (rows == null) continue;
      if (rows is! List) {
        throw BackupException(
          BackupErrorCode.corrupted,
          detail: '$table 不是数组',
        );
      }
      tables[table] = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is! Map) {
          throw BackupException(
            BackupErrorCode.corrupted,
            detail: '$table 里有一行不是对象',
          );
        }
        tables[table]!.add(row.cast<String, dynamic>());
      }
    }

    final exportedAt =
        DateTime.tryParse('${map['exportedAt']}') ?? _clock.now();
    return BackupDocument(
      summary: BackupSummary(
        formatVersion: formatVersion,
        schemaVersion: schemaVersion,
        exportedAt: exportedAt,
        appVersion: '${map['appVersion'] ?? '?'}',
        includeApiKeys: map['includesApiKeys'] == true,
        counts: <String, int>{
          for (final entry in tables.entries) entry.key: entry.value.length,
        },
      ),
      tables: tables,
    );
  }

  /// 恢复。先整体解析校验，再把写入交给一个事务，失败不会留下半份数据。
  Future<BackupSummary> restore(
    String json, {
    required RestoreMode mode,
  }) async {
    final document = parse(json);
    await _store.restore(document.tables, mode: mode);
    return document.summary;
  }

  /// 从备份文件恢复。
  Future<BackupSummary> restoreFile(
    BackupFileInfo info, {
    required RestoreMode mode,
  }) async {
    final content = await _files.read(info);
    return restore(content, mode: mode);
  }

  /// 读一个备份文件的内容（用于"先预览再决定"）。
  Future<BackupDocument> readFile(BackupFileInfo info) async {
    final content = await _files.read(info);
    return parse(content);
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
