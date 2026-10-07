import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/repositories/countdown_repository.dart';
import '../../infrastructure/clock_provider.dart';

/// 倒计时的写操作入口。
///
/// 负责 id / 时间戳 / 排序位等"策略"：UI 只提供用户填的字段。
class CountdownActions {
  CountdownActions(
      {required CountdownRepository repository, required Clock clock})
      : _repository = repository,
        _clock = clock;

  final CountdownRepository _repository;
  final Clock _clock;

  /// 新建倒计时：排在当前列表末尾。
  Future<CountdownItem> create({
    required String title,
    required DateTime targetTime,
    String? description,
    Color? color,
    Color? backgroundColor,
    CountdownDisplayStyle displayStyle = CountdownDisplayStyle.fullText,
    bool isPinned = false,
  }) async {
    final now = _clock.now();
    final existing = await _repository.getAll();
    final nextSortOrder = existing.isEmpty
        ? 0
        : existing
                .map((CountdownItem item) => item.sortOrder)
                .reduce((int a, int b) => a > b ? a : b) +
            1;

    final item = CountdownItem(
      id: generateId('countdown', now: now),
      title: title,
      targetTime: targetTime,
      description: description,
      color: color,
      backgroundColor: backgroundColor,
      displayStyle: displayStyle,
      isPinned: isPinned,
      sortOrder: nextSortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(item);
    return item;
  }

  /// 更新（保留 id 与 createdAt，刷新 updatedAt 由仓储负责）。
  Future<void> update(CountdownItem item) => _repository.upsert(item);

  Future<void> delete(String id) => _repository.deleteById(id);

  Future<void> setPinned({required String id, required bool isPinned}) =>
      _repository.setPinned(id: id, isPinned: isPinned);

  /// 写回拖动排序结果（只针对同一个分组内的顺序）。
  Future<void> reorder(List<String> orderedIds) =>
      _repository.reorder(orderedIds);
}

final countdownActionsProvider = Provider<CountdownActions>(
  (ref) => CountdownActions(
    repository: ref.watch(countdownRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
