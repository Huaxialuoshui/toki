import 'package:flutter/material.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/calendar_category.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/theme_config.dart';
import '../../infrastructure/database/app_database.dart';
import '../repositories/mappers.dart';

/// 示例数据。
///
/// 只在 **debug 构建** 且数据库为空时写入：
/// * 开发时首页 / 日历 / 倒计时有内容可看，方便 Phase 3 做增删改；
/// * release 构建不会写入任何假数据，用户从空库开始。
///
/// 文本使用中文样例（这是示例数据，不是本地化 UI 文案）。
Future<void> seedDemoDataIfEmpty(
  AppDatabase database, {
  required DateTime now,
}) async {
  final countExpression = database.calendarEvents.id.count();
  final countRow = await (database.selectOnly(database.calendarEvents)
        ..addColumns(<Expression<Object>>[countExpression]))
      .getSingle();
  final existing = countRow.read(countExpression) ?? 0;
  if (existing > 0) return;

  final today = DateTime(now.year, now.month, now.day);
  DateTime todayAt(int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, today.day, hour, minute);
  DateTime dayAt(int day, int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, day, hour, minute);

  final categories = <CalendarCategory>[
    CalendarCategory(
      id: 'demo-cat-study',
      name: '学习',
      color: const Color(0xFF5A6BF0),
      createdAt: now,
      updatedAt: now,
    ),
    CalendarCategory(
      id: 'demo-cat-work',
      name: '工作',
      color: const Color(0xFFE4577B),
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    ),
    CalendarCategory(
      id: 'demo-cat-life',
      name: '生活',
      color: const Color(0xFF12B5A5),
      sortOrder: 2,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  CalendarEvent event({
    required String id,
    required String title,
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    String categoryId = 'demo-cat-study',
    String? location,
    int color = 0xFF5A6BF0,
    int? reminderMinutes,
    bool allDay = false,
  }) {
    return CalendarEvent(
      id: id,
      title: title,
      startTime: start,
      endTime: start.add(duration),
      allDay: allDay,
      location: location,
      categoryId: categoryId,
      color: Color(color),
      reminderMinutes: reminderMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  final events = <CalendarEvent>[
    event(
      id: 'demo-event-morning',
      title: '晨间计划',
      start: todayAt(9),
      duration: const Duration(minutes: 30),
      categoryId: 'demo-cat-life',
      color: 0xFF12B5A5,
    ),
    event(
      id: 'demo-event-defense',
      title: '毕业设计答辩',
      start: todayAt(15),
      duration: const Duration(hours: 1, minutes: 30),
      location: '教学楼 A-302',
      reminderMinutes: 60,
    ),
    event(
      id: 'demo-event-project',
      title: '课程项目截止',
      start: todayAt(20),
      duration: const Duration(hours: 2),
      categoryId: 'demo-cat-work',
      location: '线上',
      color: 0xFFE4577B,
      reminderMinutes: 30,
    ),
    event(
      id: 'demo-event-lab',
      title: '课题组例会',
      start: dayAt(5, 19),
      location: '教学楼 A-302',
    ),
    event(
      id: 'demo-event-health',
      title: '体检预约',
      start: dayAt(12, 8, 30),
      duration: const Duration(hours: 2),
      categoryId: 'demo-cat-life',
      location: '校医院',
      color: 0xFF12B5A5,
      reminderMinutes: 1440,
    ),
    event(
      id: 'demo-event-defense-20',
      title: '毕业设计答辩',
      start: dayAt(20, 15),
      duration: const Duration(hours: 1, minutes: 30),
      location: '教学楼 A-302',
      reminderMinutes: 60,
    ),
    event(
      id: 'demo-event-birthday',
      title: '生日',
      start: dayAt(26, 0),
      duration: const Duration(hours: 24),
      categoryId: 'demo-cat-life',
      color: 0xFFF0A05A,
      allDay: true,
    ),
    event(
      id: 'demo-event-lab-2',
      title: '课题组例会',
      start: dayAt(28, 19),
      location: '线上',
    ),
  ];

  final countdowns = <CountdownItem>[
    CountdownItem(
      id: 'demo-countdown-defense',
      title: '毕业设计答辩',
      targetTime: now.add(const Duration(days: 13, hours: 8, minutes: 21)),
      color: const Color(0xFF5A6BF0),
      displayStyle: CountdownDisplayStyle.bigNumber,
      isPinned: true,
      createdAt: now,
      updatedAt: now,
    ),
    CountdownItem(
      id: 'demo-countdown-project',
      title: '课程项目截止',
      targetTime: now.add(const Duration(days: 3, hours: 4)),
      color: const Color(0xFFE4577B),
      isPinned: true,
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    ),
    CountdownItem(
      id: 'demo-countdown-birthday',
      title: '生日',
      targetTime: now.add(const Duration(days: 57)),
      color: const Color(0xFFF0A05A),
      sortOrder: 2,
      createdAt: now,
      updatedAt: now,
    ),
    CountdownItem(
      id: 'demo-countdown-past',
      title: '晨间计划',
      targetTime: now.subtract(const Duration(hours: 2)),
      color: const Color(0xFF12B5A5),
      sortOrder: 3,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final reminders = <Reminder>[
    Reminder(
      id: 'demo-reminder-defense',
      eventId: 'demo-event-defense',
      title: '毕业设计答辩',
      triggerTime: todayAt(14),
      createdAt: now,
    ),
    Reminder(
      id: 'demo-reminder-project',
      eventId: 'demo-event-project',
      title: '课程项目截止',
      triggerTime: todayAt(19, 30),
      createdAt: now,
    ),
  ];

  final persona = AiPersona(
    id: 'demo-persona-xiaoxue',
    name: '小雪',
    description: '私人日程助手',
    personality: '温柔、活泼，偶尔提醒主人不要拖延',
    speakingStyle: '简短、自然，不要过度正式',
    userNickname: '主人',
    systemPrompt: '你是用户的私人日程助手。回答自然简洁，修改日程时必须使用工具操作。',
    temperature: 0.7,
    createdAt: now,
    updatedAt: now,
  );

  const demoTheme = ThemeConfig(
    id: 'demo-theme-glass',
    name: '示例玻璃',
    brightness: Brightness.dark,
    primaryColor: Color(0xFF8AB4FF),
    secondaryColor: Color(0xFFB48CFF),
    backgroundColor: Color(0xFF10131C),
    surfaceColor: Color(0xFF1B2030),
    textColor: Color(0xFFEDF1FA),
    borderRadius: 22,
    cardOpacity: 0.78,
    blurAmount: 18,
  );

  await database.transaction(() async {
    await database.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        database.calendarCategories,
        categories.map(calendarCategoryToCompanion),
      );
      batch.insertAllOnConflictUpdate(
        database.calendarEvents,
        events.map(calendarEventToCompanion),
      );
      batch.insertAllOnConflictUpdate(
        database.countdowns,
        countdowns.map(countdownToCompanion),
      );
      batch.insertAllOnConflictUpdate(
        database.reminders,
        reminders.map(reminderToCompanion),
      );
      batch.insertAllOnConflictUpdate(
        database.aiPersonas,
        <AiPersonasCompanion>[aiPersonaToCompanion(persona)],
      );
      batch.insertAllOnConflictUpdate(
        database.themeConfigs,
        <ThemeConfigsCompanion>[
          themeConfigToCompanion(
            demoTheme,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
    });
  });
}
