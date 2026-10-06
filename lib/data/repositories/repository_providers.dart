import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/countdown_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/connection.dart';
import 'drift_ai_repository.dart';
import 'drift_calendar_repository.dart';
import 'drift_countdown_repository.dart';
import 'drift_reminder_repository.dart';
import 'drift_theme_repository.dart';

/// 应用数据库。
///
/// 测试里 override 成内存数据库（`AppDatabase.memory()`）即可，
/// 仓储与 UI 代码完全不用改。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openAppDatabaseConnection());
  ref.onDispose(database.close);
  return database;
});

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => DriftCalendarRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final calendarCategoryRepositoryProvider = Provider<CalendarCategoryRepository>(
  (ref) => DriftCalendarCategoryRepository(ref.watch(appDatabaseProvider)),
);

final countdownRepositoryProvider = Provider<CountdownRepository>(
  (ref) => DriftCountdownRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => DriftReminderRepository(ref.watch(appDatabaseProvider)),
);

final themeRepositoryProvider = Provider<ThemeRepository>(
  (ref) => DriftThemeRepository(
    ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final aiPersonaRepositoryProvider = Provider<AiPersonaRepository>(
  (ref) => DriftAiPersonaRepository(ref.watch(appDatabaseProvider)),
);

final aiProviderRepositoryProvider = Provider<AiProviderRepository>(
  (ref) => DriftAiProviderRepository(ref.watch(appDatabaseProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => DriftChatRepository(ref.watch(appDatabaseProvider)),
);
