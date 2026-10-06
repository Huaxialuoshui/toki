import '../../l10n/generated/app_localizations.dart';

/// 把工具名翻译成给用户看的短语（规格 §12：不要给普通用户看复杂 JSON）。
String toolLabel(AppLocalizations l10n, String toolName) => switch (toolName) {
      'get_current_time' => l10n.aiToolGetCurrentTime,
      'get_today_events' => l10n.aiToolGetTodayEvents,
      'get_events' => l10n.aiToolGetEvents,
      'search_events' => l10n.aiToolSearchEvents,
      'get_calendar_summary' => l10n.aiToolSummary,
      'create_event' => l10n.aiToolCreateEvent,
      'update_event' => l10n.aiToolUpdateEvent,
      'delete_event' => l10n.aiToolDeleteEvent,
      'get_countdowns' => l10n.aiToolGetCountdowns,
      'create_countdown' => l10n.aiToolCreateCountdown,
      'update_countdown' => l10n.aiToolUpdateCountdown,
      'delete_countdown' => l10n.aiToolDeleteCountdown,
      'create_reminder' => l10n.aiToolCreateReminder,
      'update_reminder' => l10n.aiToolUpdateReminder,
      'delete_reminder' => l10n.aiToolDeleteReminder,
      _ => toolName,
    };
