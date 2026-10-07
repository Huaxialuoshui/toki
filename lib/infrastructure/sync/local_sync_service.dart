import '../../domain/services/sync_service.dart';

/// 仅本地的同步实现（规格 §15 的第一版要求）。
///
/// 数据本来就在本机 SQLite 里，所以这里不做搬运，只确认数据库可读；
/// 真正的"导出 / 恢复"由 Phase 12 的备份功能负责。
class LocalSyncService implements SyncService {
  const LocalSyncService({required this.countRows});

  /// 注入一个"数一数有多少行"的函数，避免 infrastructure 依赖具体仓储。
  final Future<int> Function() countRows;

  @override
  String get id => 'local';

  @override
  SyncCapability get capability => SyncCapability.localOnly;

  @override
  Future<void> initialize() async {}

  @override
  Future<SyncResult> sync() async {
    final rows = await countRows();
    return SyncResult(message: 'local:$rows', changed: false);
  }
}
