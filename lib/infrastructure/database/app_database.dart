import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// 生成的 app_database.g.dart 是同一 library 的 part，因此这里导入的领域枚举
// （EventStatus / CountdownDisplayStyle / ChatRole）对生成代码同样可见。
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/entities/task_item.dart';
import 'converters.dart';
import 'tables/ai_tables.dart';
import 'tables/calendar_tables.dart';
import 'tables/countdown_tables.dart';
import 'tables/digest_tables.dart';
import 'tables/reminder_tables.dart';
import 'tables/task_tables.dart';
import 'tables/theme_tables.dart';

part 'app_database.g.dart';

/// Toki 的本地数据库（Drift + SQLite）。
///
/// * 领域数据都在这里；应用级轻量设置（语言 / 当前主题 id 等）仍然放在
///   shared_preferences，两者互不迁移。
/// * 时间统一以 UTC 微秒存整数，见 UtcDateTimeConverter。
/// * schemaVersion 从 1 开始，升级时必须补 onUpgrade 并跑迁移测试。
@DriftDatabase(
  tables: <Type>[
    CalendarCategories,
    CalendarEvents,
    Countdowns,
    Reminders,
    AiPersonas,
    AiProviders,
    ChatSessions,
    ChatMessages,
    ThemeConfigs,
    DailyDigests,
    Tasks,
    DailyPlans,
    DailyPlanItems,
    PlanningPreferenceSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 测试用：内存数据库。
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// 当前结构版本。备份文件里会带上它，用来判断"这份备份能不能直接恢复"。
  static const int currentSchemaVersion = 8;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // v2：聊天消息增加 tool_call_id（AI 工具调用需要）。
            await m.addColumn(chatMessages, chatMessages.toolCallId);
          }
          if (from < 3) {
            // v3：用户主题增加阴影强度（主题编辑器可调）。
            await m.addColumn(themeConfigs, themeConfigs.shadowStrength);
          }
          if (from < 4) {
            // v4：会话记住用哪个服务商；倒计时支持背景色；日程支持重复结束日期；
            //     新增 AI 每日计划 / 总结表。
            await m.addColumn(chatSessions, chatSessions.providerId);
            await m.addColumn(countdowns, countdowns.backgroundColor);
            await m.addColumn(calendarEvents, calendarEvents.repeatUntil);
            await m.createTable(dailyDigests);
          }
          if (from < 5) {
            // v5：主题支持区域配色（导航栏 / 侧边栏 / 日历 / 倒计时默认色）。
            await m.addColumn(themeConfigs, themeConfigs.navigationBarColor);
            await m.addColumn(themeConfigs, themeConfigs.sidebarColor);
            await m.addColumn(themeConfigs, themeConfigs.eventColor);
            await m.addColumn(themeConfigs, themeConfigs.countdownColor);
          }
          if (from < 6) {
            // v6：助手消息保存思考内容（多轮工具调用时回传）；人设头像支持底色。
            await m.addColumn(chatMessages, chatMessages.reasoningContent);
            await m.addColumn(aiPersonas, aiPersonas.avatarColor);
          }
          if (from < 7) {
            // v7：人设可以关掉"作为日历助手"，变成纯聊天 / 扮演。
            await m.addColumn(
              aiPersonas,
              aiPersonas.calendarAssistantEnabled,
            );
          }
          if (from < 8) {
            // v8：任务、结构化计划、计划条目和规划偏好；日程关联任务，
            //     摘要关联计划并保存用户反馈 / 本地复盘指标。
            await m.createTable(tasks);
            await m.createTable(planningPreferenceSettings);
            await m.createTable(dailyPlans);
            if (!await _hasColumn('calendar_events', 'task_id')) {
              await m.addColumn(calendarEvents, calendarEvents.taskId);
            }
            await m.createTable(dailyPlanItems);
            if (!await _hasColumn('daily_digests', 'plan_id')) {
              await m.addColumn(dailyDigests, dailyDigests.planId);
            }
            if (!await _hasColumn('daily_digests', 'feedback')) {
              await m.addColumn(dailyDigests, dailyDigests.feedback);
            }
            if (!await _hasColumn('daily_digests', 'metrics_json')) {
              await m.addColumn(dailyDigests, dailyDigests.metricsJson);
            }
            if (!await _hasColumn('daily_digests', 'user_edited')) {
              await m.addColumn(dailyDigests, dailyDigests.userEdited);
            }
            if (!await _hasColumn('daily_digests', 'updated_at')) {
              await m.addColumn(dailyDigests, dailyDigests.updatedAt);
            }

            // createTable 只建表，不自动创建索引。
            await customStatement(
              'CREATE INDEX idx_tasks_status_due '
              'ON tasks (status, due_at)',
            );
            await customStatement(
              'CREATE INDEX idx_tasks_archived_updated '
              'ON tasks (archived_at, updated_at)',
            );
            await customStatement(
              'CREATE INDEX idx_events_task_id ON calendar_events (task_id)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX idx_daily_plans_day_revision '
              'ON daily_plans (day_key, revision)',
            );
            await customStatement(
              'CREATE INDEX idx_daily_plan_items_plan_sort '
              'ON daily_plan_items (plan_id, sort_order)',
            );
            await customStatement(
              'CREATE INDEX idx_daily_plan_items_task_status '
              'ON daily_plan_items (task_id, status)',
            );
          }
        },
        beforeOpen: (OpeningDetails details) async {
          // 打开外键约束（SQLite 默认关闭）。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// 旧版本迁移里可能用“当前表定义”创建过表，因此 v8 加列必须幂等。
  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info("$table")').get();
    return rows.any((QueryRow row) => row.read<String>('name') == column);
  }
}
