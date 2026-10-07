/// 同步能力（规格 §15）。
enum SyncCapability {
  /// 只在本机：没有远端，`sync()` 只是确认本地数据可用。
  localOnly,

  /// 有远端（WebDAV / 自建服务器 / 云）。
  remote,
}

/// 一次同步的结果。
class SyncResult {
  const SyncResult({required this.message, this.changed = false});

  final String message;
  final bool changed;
}

/// 数据同步抽象（规格 §15）。
///
/// 第一版**只有本地实现**：不建服务器、不做云同步，但接口先立在这里，
/// 以后加 `WebDavSyncService` / `CloudSyncService` 时上层不用改。
abstract interface class SyncService {
  /// 稳定标识：`local` / `webdav` / `cloud`。
  String get id;

  SyncCapability get capability;

  Future<void> initialize();

  /// 执行一次同步。本地实现只会校验数据可读，不会改动任何东西。
  Future<SyncResult> sync();
}

/// 便捷判断：是否只有本地数据（设置页据此显示说明文案）。
extension SyncServiceX on SyncService {
  bool get isLocalOnly => capability == SyncCapability.localOnly;
}
