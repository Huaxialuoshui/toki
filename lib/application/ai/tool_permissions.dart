import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/storage/app_settings_store.dart';
import 'tools/ai_tool.dart';

/// AI 工具权限（规格 §8 的 ToolPermission）。
///
/// 按"类别"授权：查询 / 创建 / 修改 / 删除。默认允许前三种，**删除默认关闭**，
/// 需要用户显式打开。
@immutable
class ToolPermissions {
  const ToolPermissions({
    this.allowRead = true,
    this.allowCreate = true,
    this.allowUpdate = true,
    this.allowDelete = false,
  });

  final bool allowRead;
  final bool allowCreate;
  final bool allowUpdate;
  final bool allowDelete;

  bool allows(AiToolCategory category) => switch (category) {
        AiToolCategory.read => allowRead,
        AiToolCategory.create => allowCreate,
        AiToolCategory.update => allowUpdate,
        AiToolCategory.delete => allowDelete,
      };

  ToolPermissions copyWith({
    bool? allowRead,
    bool? allowCreate,
    bool? allowUpdate,
    bool? allowDelete,
  }) {
    return ToolPermissions(
      allowRead: allowRead ?? this.allowRead,
      allowCreate: allowCreate ?? this.allowCreate,
      allowUpdate: allowUpdate ?? this.allowUpdate,
      allowDelete: allowDelete ?? this.allowDelete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolPermissions &&
        other.allowRead == allowRead &&
        other.allowCreate == allowCreate &&
        other.allowUpdate == allowUpdate &&
        other.allowDelete == allowDelete;
  }

  @override
  int get hashCode =>
      Object.hash(allowRead, allowCreate, allowUpdate, allowDelete);
}

class ToolPermissionsController extends Notifier<ToolPermissions> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  ToolPermissions build() {
    final store = ref.watch(appSettingsStoreProvider);
    return ToolPermissions(
      allowRead: store.readAiAllowRead() ?? true,
      allowCreate: store.readAiAllowCreate() ?? true,
      allowUpdate: store.readAiAllowUpdate() ?? true,
      allowDelete: store.readAiAllowDelete() ?? false,
    );
  }

  void setRead(bool value) => _update(
        state.copyWith(allowRead: value),
        () => _store.writeAiAllowRead(value),
      );

  void setCreate(bool value) => _update(
        state.copyWith(allowCreate: value),
        () => _store.writeAiAllowCreate(value),
      );

  void setUpdate(bool value) => _update(
        state.copyWith(allowUpdate: value),
        () => _store.writeAiAllowUpdate(value),
      );

  void setDelete(bool value) => _update(
        state.copyWith(allowDelete: value),
        () => _store.writeAiAllowDelete(value),
      );

  void _update(ToolPermissions next, Future<void> Function() persist) {
    if (next == state) return;
    state = next;
    unawaited(persist());
  }
}

final toolPermissionsProvider =
    NotifierProvider<ToolPermissionsController, ToolPermissions>(
  ToolPermissionsController.new,
);
