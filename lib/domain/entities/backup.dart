import 'package:flutter/foundation.dart';

/// 备份文件的**格式版本**（与数据库 `schemaVersion` 分开演进）。
///
/// 规则：只加字段不改语义时保持版本号；语义变化（例如某张表改名、某个字段
/// 换了单位）必须升版本，并在 `BackupService` 里补对应升级逻辑。
const int kBackupFormatVersion = 1;

/// 备份文件里的类型标识，用来挡住"随便一个 JSON 也当成备份导入"。
const String kBackupFormatTag = 'toki-backup';

/// 恢复方式。
enum RestoreMode {
  /// 清空现有数据后整体写入（真正的"恢复"）。
  replace,

  /// 保留现有数据，同 id 覆盖、新 id 追加（"合并进来"）。
  merge,
}

/// 备份的元信息与各表条数。
@immutable
class BackupSummary {
  const BackupSummary({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.includeApiKeys,
    required this.counts,
  });

  final int formatVersion;

  /// 导出时的数据库结构版本（`AppDatabase.schemaVersion`）。
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;

  /// 是否包含明文 API Key。
  final bool includeApiKeys;

  /// 表名 → 行数。
  final Map<String, int> counts;

  int get total =>
      counts.values.fold<int>(0, (int sum, int value) => sum + value);
}

/// 一份已经解析通过的备份。
@immutable
class BackupDocument {
  const BackupDocument({required this.summary, required this.tables});

  final BackupSummary summary;

  /// 表名 → 行（就是 drift 数据类的 `toJson()` 结果）。
  final Map<String, List<Map<String, dynamic>>> tables;
}

/// 备份失败的原因（界面负责翻译成文案，领域层不写死语言）。
enum BackupErrorCode {
  notJson,
  notTokiBackup,
  unsupportedFormatVersion,
  unsupportedSchemaVersion,
  missingTables,
  corrupted,
}

class BackupException implements Exception {
  const BackupException(this.code, {this.detail});

  final BackupErrorCode code;
  final String? detail;

  @override
  String toString() =>
      'BackupException(${code.name}${detail == null ? '' : ': $detail'})';
}
