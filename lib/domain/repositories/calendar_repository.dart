import '../entities/calendar_category.dart';
import '../entities/calendar_event.dart';

/// 日历事件的数据访问契约。
///
/// 业务层（application / presentation）只依赖这个接口，具体实现放在
/// `data/repositories`，因此将来换存储实现不影响上层。
abstract interface class CalendarRepository {
  /// 按开始时间排序的全部事件。
  Stream<List<CalendarEvent>> watchAll();

  /// 与 [from, to) 有交集的事件（月视图 / 日视图用）。
  Stream<List<CalendarEvent>> watchRange({
    required DateTime from,
    required DateTime to,
  });

  /// `[from, to)` 内**可能出现**的全部日程，包含重复日程的"原始行"。
  ///
  /// 与 [watchRange] 的区别：重复日程只在它第一次的 startTime 上有一行，
  /// 所以要放宽到"开始时间早于 to 且（有重复规则 或 落在区间内）"，
  /// 再由上层用 `expandOccurrences` 展开成具体发生时间。
  Stream<List<CalendarEvent>> watchRelevant({
    required DateTime from,
    required DateTime to,
  });

  /// [after] 之后的最近事件。
  Stream<List<CalendarEvent>> watchUpcoming({
    required DateTime after,
    int limit = 5,
  });

  Future<List<CalendarEvent>> getAll();
  Future<CalendarEvent?> findById(String id);
  Future<int> count();

  /// 存在则更新，不存在则插入。
  Future<void> upsert(CalendarEvent event);
  Future<void> upsertAll(List<CalendarEvent> events);

  Future<void> deleteById(String id);
  Future<void> deleteAll();

  /// 把引用了该分类的事件改成"无分类"（删除分类前调用，避免外键约束）。
  Future<void> clearCategoryFromEvents(String categoryId);
}

/// 日历分类的数据访问契约。
abstract interface class CalendarCategoryRepository {
  Stream<List<CalendarCategory>> watchAll();
  Future<List<CalendarCategory>> getAll();
  Future<void> upsert(CalendarCategory category);
  Future<void> deleteById(String id);
  Future<void> deleteAll();
}
