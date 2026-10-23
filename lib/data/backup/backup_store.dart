import 'package:drift/drift.dart' show ValueSerializer;

import '../../domain/entities/backup.dart';
import '../../infrastructure/database/app_database.dart';

/// 备份涉及的表，**顺序即写入顺序**（父表在前，满足外键约束）。
///
/// 外键关系：`calendar_events → calendar_categories`、`reminders → calendar_events`、
/// `chat_sessions → ai_personas`、`chat_messages → chat_sessions`。
/// 读取与删除都按这个顺序的反向执行。
abstract final class BackupTables {
  static const List<String> ordered = <String>[
    'calendar_categories',
    'tasks',
    'calendar_events',
    'countdowns',
    'reminders',
    'ai_personas',
    'ai_providers',
    'chat_sessions',
    'chat_messages',
    'theme_configs',
    'planning_preferences',
    'daily_plans',
    'daily_plan_items',
    'daily_digests',
  ];
}

/// 备份专用的值序列化器。
///
/// drift 的默认序列化器对 `List<String>` 这类列会直接 `as T`；JSON 往返之后
/// 元素类型是 `dynamic`，`List<dynamic> as List<String>` 会直接抛错，于是
/// `ai_personas.enabled_tools` 根本存不回去。这里把 List 统一还原成
/// `List<String>`（当前 schema 里只有这一列是列表），DateTime 同时兼容
/// ISO 字符串与时间戳。
class BackupValueSerializer extends ValueSerializer {
  const BackupValueSerializer();

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  @override
  T fromJson<T>(dynamic json) {
    if (json is List) {
      return List<String>.from(json.map((Object? item) => '$item')) as T;
    }
    if (T == DateTime) {
      if (json is String) return DateTime.parse(json) as T;
      if (json is int) return DateTime.fromMillisecondsSinceEpoch(json) as T;
    }
    return json as T;
  }
}

const ValueSerializer _backupSerializer = BackupValueSerializer();

/// 直接用 drift 数据类的 `toJson()` / `fromJson()` 做整表搬运。
///
/// 这里刻意不走仓储：备份要的是"每一行原样带走"，而仓储暴露的是领域语义
/// （排序、置顶、默认项等）。两边职责不同，谁也替代不了谁。
class BackupStore {
  BackupStore(this._db);

  final AppDatabase _db;

  /// 读出全部表。`includeApiKeys == false` 时把 `api_providers.api_key` 抹成 null。
  Future<Map<String, List<Map<String, dynamic>>>> readAll({
    required bool includeApiKeys,
  }) async {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final table in BackupTables.ordered) {
      result[table] = await _readTable(table);
    }
    if (!includeApiKeys) {
      for (final row in result['ai_providers']!) {
        row['apiKey'] = null;
      }
    }
    return result;
  }

  /// 写入备份。[RestoreMode.replace] 会先清空所有表。
  Future<void> restore(
    Map<String, List<Map<String, dynamic>>> tables, {
    required RestoreMode mode,
  }) async {
    await _db.transaction(() async {
      if (mode == RestoreMode.replace) {
        for (final table in BackupTables.ordered.reversed) {
          await _deleteTable(table);
        }
      }
      for (final table in BackupTables.ordered) {
        for (final row in tables[table] ?? const <Map<String, dynamic>>[]) {
          await _insertRow(table, row);
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> _readTable(String table) async {
    switch (table) {
      case 'calendar_categories':
        final rows = await _db.select(_db.calendarCategories).get();
        return rows
            .map((CalendarCategoryRow r) =>
                r.toJson(serializer: _backupSerializer))
            .toList();
      case 'tasks':
        final rows = await _db.select(_db.tasks).get();
        return rows
            .map((TaskRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'calendar_events':
        final rows = await _db.select(_db.calendarEvents).get();
        return rows
            .map(
                (CalendarEventRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'countdowns':
        final rows = await _db.select(_db.countdowns).get();
        return rows
            .map((CountdownRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'reminders':
        final rows = await _db.select(_db.reminders).get();
        return rows
            .map((ReminderRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'ai_personas':
        final rows = await _db.select(_db.aiPersonas).get();
        return rows
            .map((AiPersonaRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'ai_providers':
        final rows = await _db.select(_db.aiProviders).get();
        return rows
            .map((AiProviderRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'chat_sessions':
        final rows = await _db.select(_db.chatSessions).get();
        return rows
            .map((ChatSessionRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'chat_messages':
        final rows = await _db.select(_db.chatMessages).get();
        return rows
            .map((ChatMessageRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'theme_configs':
        final rows = await _db.select(_db.themeConfigs).get();
        return rows
            .map((ThemeConfigRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'planning_preferences':
        final rows = await _db.select(_db.planningPreferenceSettings).get();
        return rows
            .map((PlanningPreferenceRow r) =>
                r.toJson(serializer: _backupSerializer))
            .toList();
      case 'daily_plans':
        final rows = await _db.select(_db.dailyPlans).get();
        return rows
            .map((DailyPlanRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'daily_plan_items':
        final rows = await _db.select(_db.dailyPlanItems).get();
        return rows
            .map(
                (DailyPlanItemRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      case 'daily_digests':
        final rows = await _db.select(_db.dailyDigests).get();
        return rows
            .map((DailyDigestRow r) => r.toJson(serializer: _backupSerializer))
            .toList();
      default:
        return const <Map<String, dynamic>>[];
    }
  }

  Future<void> _deleteTable(String table) async {
    switch (table) {
      case 'calendar_categories':
        await _db.delete(_db.calendarCategories).go();
      case 'tasks':
        await _db.delete(_db.tasks).go();
      case 'calendar_events':
        await _db.delete(_db.calendarEvents).go();
      case 'countdowns':
        await _db.delete(_db.countdowns).go();
      case 'reminders':
        await _db.delete(_db.reminders).go();
      case 'ai_personas':
        await _db.delete(_db.aiPersonas).go();
      case 'ai_providers':
        await _db.delete(_db.aiProviders).go();
      case 'chat_sessions':
        await _db.delete(_db.chatSessions).go();
      case 'chat_messages':
        await _db.delete(_db.chatMessages).go();
      case 'theme_configs':
        await _db.delete(_db.themeConfigs).go();
      case 'planning_preferences':
        await _db.delete(_db.planningPreferenceSettings).go();
      case 'daily_plans':
        await _db.delete(_db.dailyPlans).go();
      case 'daily_plan_items':
        await _db.delete(_db.dailyPlanItems).go();
      case 'daily_digests':
        await _db.delete(_db.dailyDigests).go();
    }
  }

  /// 单行写入失败时补上"是哪张表、哪一行"，避免只报一个 SQLite 错误码。
  Future<void> _insertRow(String table, Map<String, dynamic> row) async {
    final normalized = _withDefaults(table, row);
    try {
      switch (table) {
        case 'calendar_categories':
          await _db
              .into(_db.calendarCategories)
              .insertOnConflictUpdate(CalendarCategoryRow.fromJson(
                normalized,
                serializer: _backupSerializer,
              ));
        case 'tasks':
          await _db.into(_db.tasks).insertOnConflictUpdate(
              TaskRow.fromJson(normalized, serializer: _backupSerializer));
        case 'calendar_events':
          await _db
              .into(_db.calendarEvents)
              .insertOnConflictUpdate(CalendarEventRow.fromJson(
                normalized,
                serializer: _backupSerializer,
              ));
        case 'countdowns':
          await _db.into(_db.countdowns).insertOnConflictUpdate(
              CountdownRow.fromJson(normalized, serializer: _backupSerializer));
        case 'reminders':
          await _db.into(_db.reminders).insertOnConflictUpdate(
              ReminderRow.fromJson(normalized, serializer: _backupSerializer));
        case 'ai_personas':
          await _db.into(_db.aiPersonas).insertOnConflictUpdate(
              AiPersonaRow.fromJson(normalized, serializer: _backupSerializer));
        case 'ai_providers':
          await _db.into(_db.aiProviders).insertOnConflictUpdate(
              AiProviderRow.fromJson(normalized,
                  serializer: _backupSerializer));
        case 'chat_sessions':
          await _db.into(_db.chatSessions).insertOnConflictUpdate(
              ChatSessionRow.fromJson(normalized,
                  serializer: _backupSerializer));
        case 'chat_messages':
          await _db.into(_db.chatMessages).insertOnConflictUpdate(
              ChatMessageRow.fromJson(normalized,
                  serializer: _backupSerializer));
        case 'theme_configs':
          await _db.into(_db.themeConfigs).insertOnConflictUpdate(
              ThemeConfigRow.fromJson(normalized,
                  serializer: _backupSerializer));
        case 'planning_preferences':
          await _db.into(_db.planningPreferenceSettings).insertOnConflictUpdate(
                PlanningPreferenceRow.fromJson(
                  normalized,
                  serializer: _backupSerializer,
                ),
              );
        case 'daily_plans':
          await _db.into(_db.dailyPlans).insertOnConflictUpdate(
              DailyPlanRow.fromJson(normalized, serializer: _backupSerializer));
        case 'daily_plan_items':
          await _db
              .into(_db.dailyPlanItems)
              .insertOnConflictUpdate(DailyPlanItemRow.fromJson(
                normalized,
                serializer: _backupSerializer,
              ));
        case 'daily_digests':
          await _db
              .into(_db.dailyDigests)
              .insertOnConflictUpdate(DailyDigestRow.fromJson(
                normalized,
                serializer: _backupSerializer,
              ));
      }
    } catch (error) {
      throw BackupException(
        BackupErrorCode.corrupted,
        detail: '$table / ${row['id'] ?? row['sessionId'] ?? '?'} → $error',
      );
    }
  }

  /// 旧备份缺少后加的列时补上可空值 / 默认值，避免 fromJson 直接失败。
  /// 已有值优先，不会被默认值覆盖。
  Map<String, dynamic> _withDefaults(
    String table,
    Map<String, dynamic> row,
  ) {
    switch (table) {
      case 'calendar_events':
        return <String, dynamic>{'taskId': null, ...row};
      case 'daily_digests':
        return <String, dynamic>{
          'planId': null,
          'feedback': null,
          'metricsJson': null,
          'updatedAt': null,
          'userEdited': false,
          ...row,
        };
      default:
        return row;
    }
  }
}
