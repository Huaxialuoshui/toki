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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 测试用：内存数据库。
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 是初始版本，尚无升级路径；后续版本在这里按 from → to 增量迁移。
        },
        beforeOpen: (OpeningDetails details) async {
          // 打开外键约束（SQLite 默认关闭）。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
