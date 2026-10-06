import 'package:flutter/material.dart';

import '../../domain/entities/ai_persona.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/countdown_item.dart';
import '../../l10n/generated/app_localizations.dart';

/// Phase 1 的 mock 内容。
///
/// 这里刻意放在 infrastructure：Phase 2 接入 Drift 之后整体删除，页面只需要
/// 换成读数据库的 provider，UI 代码不动。文本全部来自 [AppLocalizations]，
/// 保证英文界面下不会漏出中文 mock 数据。

const String mockSessionId = 'session-mock-1';

List<CalendarEvent> buildMockEvents({
  required DateTime now,
  required AppLocalizations l10n,
}) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime todayAt(int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, today.day, hour, minute);
  DateTime dayAt(int day, int hour, [int minute = 0]) =>
      DateTime(today.year, today.month, day, hour, minute);

  CalendarEvent event({
    required String id,
    required String title,
    required DateTime start,
    Duration duration = const Duration(hours: 1),
    String? location,
    required Color color,
    int? reminderMinutes,
  }) {
    return CalendarEvent(
      id: id,
      title: title,
      startTime: start,
      endTime: start.add(duration),
      location: location,
      color: color,
      reminderMinutes: reminderMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  return <CalendarEvent>[
    // 今天
    event(
      id: 'mock-morning-plan',
      title: l10n.mockEventMorningPlan,
      start: todayAt(9),
      duration: const Duration(minutes: 30),
      color: const Color(0xFF12B5A5),
    ),
    event(
      id: 'mock-defense',
      title: l10n.mockEventDefense,
      start: todayAt(15),
      duration: const Duration(hours: 1, minutes: 30),
      location: l10n.mockLocationLab,
      color: const Color(0xFF5A6BF0),
      reminderMinutes: 60,
    ),
    event(
      id: 'mock-project-deadline',
      title: l10n.mockEventProjectDeadline,
      start: todayAt(20),
      duration: const Duration(hours: 2),
      location: l10n.mockLocationOnline,
      color: const Color(0xFFE4577B),
      reminderMinutes: 30,
    ),
    // 本月其它日期（让月视图有内容）
    event(
      id: 'mock-lab-meeting',
      title: l10n.mockEventLabMeeting,
      start: dayAt(5, 19),
      location: l10n.mockLocationLab,
      color: const Color(0xFF7C8CFF),
      reminderMinutes: 15,
    ),
    event(
      id: 'mock-health-check',
      title: l10n.mockEventHealthCheck,
      start: dayAt(12, 8, 30),
      duration: const Duration(hours: 2),
      location: l10n.mockLocationLab,
      color: const Color(0xFF12B5A5),
      reminderMinutes: 1440,
    ),
    event(
      id: 'mock-defense-20',
      title: l10n.mockEventDefense,
      start: dayAt(20, 15),
      duration: const Duration(hours: 1, minutes: 30),
      location: l10n.mockLocationLab,
      color: const Color(0xFF5A6BF0),
      reminderMinutes: 60,
    ),
    event(
      id: 'mock-birthday',
      title: l10n.mockEventBirthday,
      start: dayAt(26, 0),
      duration: const Duration(hours: 24),
      color: const Color(0xFFF0A05A),
    ),
    event(
      id: 'mock-lab-meeting-next',
      title: l10n.mockEventLabMeeting,
      start: dayAt(28, 19),
      location: l10n.mockLocationOnline,
      color: const Color(0xFF7C8CFF),
    ),
  ];
}

List<CountdownItem> buildMockCountdowns({
  required DateTime now,
  required AppLocalizations l10n,
}) {
  CountdownItem item({
    required String id,
    required String title,
    required Duration offset,
    required Color color,
    CountdownDisplayStyle style = CountdownDisplayStyle.fullText,
    bool isPinned = false,
    int sortOrder = 0,
  }) {
    return CountdownItem(
      id: id,
      title: title,
      targetTime: now.add(offset),
      color: color,
      displayStyle: style,
      isPinned: isPinned,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  return <CountdownItem>[
    item(
      id: 'mock-cd-defense',
      title: l10n.mockEventDefense,
      offset: const Duration(days: 13, hours: 8, minutes: 21),
      color: const Color(0xFF5A6BF0),
      style: CountdownDisplayStyle.bigNumber,
      isPinned: true,
    ),
    item(
      id: 'mock-cd-project',
      title: l10n.mockEventProjectDeadline,
      offset: const Duration(days: 3, hours: 4),
      color: const Color(0xFFE4577B),
      isPinned: true,
      sortOrder: 1,
    ),
    item(
      id: 'mock-cd-birthday',
      title: l10n.mockEventBirthday,
      offset: const Duration(days: 57),
      color: const Color(0xFFF0A05A),
      sortOrder: 2,
    ),
    item(
      id: 'mock-cd-passed',
      title: l10n.mockEventMorningPlan,
      offset: const Duration(hours: -2),
      color: const Color(0xFF12B5A5),
      sortOrder: 3,
    ),
  ];
}

AiPersona buildMockPersona({required DateTime now, required AppLocalizations l10n}) {
  return AiPersona(
    id: 'persona-xiaoxue',
    name: l10n.mockPersonaName,
    description: l10n.mockPersonaDescription,
    personality: l10n.mockPersonaPersonality,
    speakingStyle: l10n.mockPersonaSpeakingStyle,
    userNickname: l10n.mockPersonaNickname,
    systemPrompt: '你是用户的私人日程助手。回答自然简洁，修改日程时必须使用工具操作。',
    temperature: 0.7,
    createdAt: now,
    updatedAt: now,
  );
}

ChatSession buildMockSession({
  required DateTime now,
  required AppLocalizations l10n,
  required String personaId,
}) {
  return ChatSession(
    id: mockSessionId,
    title: l10n.mockEventMorningPlan,
    personaId: personaId,
    createdAt: now,
    updatedAt: now,
  );
}

/// mock 会话：一条用户消息 + 一次工具调用 + 一条助手回复。
///
/// 工具调用只展示人类可读的摘要（规格 §12：不要把复杂 JSON 摊给用户）。
List<ChatMessage> buildMockConversation({
  required DateTime now,
  required AppLocalizations l10n,
}) {
  return <ChatMessage>[
    ChatMessage(
      id: 'mock-msg-1',
      sessionId: mockSessionId,
      role: ChatRole.user,
      content: l10n.aiMockUser,
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: 'mock-msg-2',
      sessionId: mockSessionId,
      role: ChatRole.tool,
      content: l10n.aiMockToolSummary,
      toolCall: const ToolCallInfo(
        toolName: 'get_events',
        status: ToolCallStatus.succeeded,
      ),
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
    ChatMessage(
      id: 'mock-msg-3',
      sessionId: mockSessionId,
      role: ChatRole.assistant,
      content: l10n.aiMockAssistant,
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
  ];
}
