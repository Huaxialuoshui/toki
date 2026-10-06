import '../entities/countdown_item.dart';

/// 倒计时的数据访问契约。
abstract interface class CountdownRepository {
  /// 置顶优先、其次按 sortOrder 排序。
  Stream<List<CountdownItem>> watchAll();
  Stream<List<CountdownItem>> watchPinned();

  Future<List<CountdownItem>> getAll();
  Future<CountdownItem?> findById(String id);
  Future<int> count();

  Future<void> upsert(CountdownItem item);
  Future<void> upsertAll(List<CountdownItem> items);

  /// 置顶 / 取消置顶。
  Future<void> setPinned({required String id, required bool isPinned});

  /// 写回拖动排序结果：列表顺序即新的 sortOrder。
  Future<void> reorder(List<String> orderedIds);

  Future<void> deleteById(String id);
  Future<void> deleteAll();
}
