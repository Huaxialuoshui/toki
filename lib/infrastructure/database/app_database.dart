import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// 生成的 app_database.g.dart 是同一 library 的 part，因此这里导入的领域枚举
// （EventStatus / CountdownDisplayStyle / ChatRole）对生成代码同样可见。
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/countdown_item.dart';
import 'converters.dart';
import 'tables/ai_tables.dart';
import 'tables/calendar_tables.dart';
import 'tables/countdown_tables.dart';
import 'tables/digest_tables.dart';
import 'tables/reminder_tables.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 测试用：内存数据库。
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// 当前结构版本。备份文件里会带上它，用来判断"这份备份能不能直接恢复"。
  static const int currentSchemaVersion = 6;

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
        },
        beforeOpen: (OpeningDetails details) async {
          // 打开外键约束（SQLite 默认关闭）。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
