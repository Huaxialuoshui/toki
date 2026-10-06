import '../entities/reminder.dart';

/// 提醒的数据访问契约。
abstract interface class ReminderRepository {
  Stream<List<Reminder>> watchAll();
  Stream<List<Reminder>> watchForEvent(String eventId);

  /// 待触发且已启用的提醒（Phase 5 通知调度使用）。
  Stream<List<Reminder>> watchPending({required DateTime from});

  Future<List<Reminder>> getAll();
  Future<List<Reminder>> getForEvent(String eventId);
  Future<Reminder?> findById(String id);
  Future<int> count();

  Future<void> upsert(Reminder reminder);
  Future<void> upsertAll(List<Reminder> reminders);
  Future<void> setEnabled({required String id, required bool enabled});

  /// 删除某个日程的所有提醒（事件被编辑或删除时同步用）。
  Future<void> deleteForEvent(String eventId);

  Future<void> deleteById(String id);
  Future<void> deleteAll();
}
