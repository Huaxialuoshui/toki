import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Toki';

  @override
  String get appTagline => 'Local-first AI calendar & reminders';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navCountdown => 'Countdown';

  @override
  String get navAi => 'AI Assistant';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonComingSoon => 'Planned for a later phase';

  @override
  String get commonViewAll => 'View all';

  @override
  String get homeGreeting => 'Welcome back';

  @override
  String get homeWeatherPlaceholder => 'Weather';

  @override
  String get homeWeatherHint => 'Weather integration is reserved for a later phase';

  @override
  String get homeTodayEvents => 'Today\'s schedule';

  @override
  String get homeNoEvents => 'Nothing scheduled today';

  @override
  String get homeCountdowns => 'Countdowns';

  @override
  String get homeUpcoming => 'Upcoming';

  @override
  String homeAskAi(String personaName) {
    return 'Ask $personaName';
  }

  @override
  String get homeAskAiHint => 'Chat, query your schedule, create reminders';

  @override
  String get homeOpenAi => 'Open assistant';

  @override
  String get homePhaseBannerTitle => 'Phase 2 · local database';

  @override
  String get homePhaseBannerBody => 'Events, countdowns and reminders are now stored in a local SQLite database on this device. Sample rows are only written in debug builds.';

  @override
  String get homePhaseBannerDismiss => 'Got it';

  @override
  String countdownTimeUntil(String title) {
    return 'Time until $title';
  }

  @override
  String countdownTimeSince(String title) {
    return '$title has passed';
  }

  @override
  String countdownTargetAt(String time) {
    return 'Target $time';
  }

  @override
  String get countdownPinned => 'Pinned';

  @override
  String get countdownEmpty => 'No countdowns yet';

  @override
  String get countdownNew => 'New countdown';

  @override
  String get countdownEdit => 'Edit countdown';

  @override
  String get countdownFieldTarget => 'Target time';

  @override
  String get countdownFieldStyle => 'Display style';

  @override
  String get countdownStyleBigNumber => 'Big number';

  @override
  String get countdownStyleFullText => 'Full text';

  @override
  String get countdownFieldPinned => 'Pin to top';

  @override
  String get countdownDragHint => 'Drag the handle to reorder';

  @override
  String get countdownDragHintLongPress => 'Long-press the handle to reorder';

  @override
  String get countdownDragHandle => 'Reorder';

  @override
  String get countdownDeleteConfirmTitle => 'Delete this countdown?';

  @override
  String get countdownSaved => 'Countdown saved';

  @override
  String get countdownDeleted => 'Countdown deleted';

  @override
  String get unitDay => 'd';

  @override
  String get unitHour => 'h';

  @override
  String get unitMinute => 'm';

  @override
  String get unitSecond => 's';

  @override
  String get unitDayFull => 'days';

  @override
  String get unitHourFull => 'hours';

  @override
  String get unitMinuteFull => 'minutes';

  @override
  String get unitSecondFull => 'seconds';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarMonthView => 'Month';

  @override
  String get calendarWeekView => 'Week';

  @override
  String get calendarDayView => 'Day';

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarEditEvent => 'Edit event';

  @override
  String get calendarSave => 'Save';

  @override
  String get calendarCancel => 'Cancel';

  @override
  String get calendarDelete => 'Delete';

  @override
  String get calendarEdit => 'Edit';

  @override
  String get calendarDeleteConfirmTitle => 'Delete this event?';

  @override
  String get calendarDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get calendarFieldTitle => 'Title';

  @override
  String get calendarFieldTitleRequired => 'Please enter a title';

  @override
  String get calendarFieldDescription => 'Description';

  @override
  String get calendarFieldLocation => 'Location';

  @override
  String get calendarFieldCategory => 'Category';

  @override
  String get calendarCategoryNone => 'No category';

  @override
  String get calendarFieldColor => 'Color';

  @override
  String get calendarColorDefault => 'Default';

  @override
  String get calendarFieldReminder => 'Reminder';

  @override
  String get calendarReminderAtTime => 'At start time';

  @override
  String calendarReminderHours(int hours) {
    return '$hours hours before';
  }

  @override
  String calendarReminderDays(int days) {
    return '$days days before';
  }

  @override
  String get calendarAllDayEvent => 'All day';

  @override
  String get calendarFieldStart => 'Starts';

  @override
  String get calendarFieldEnd => 'Ends';

  @override
  String get calendarEndBeforeStart => 'End time must be after start time';

  @override
  String get calendarEventSaved => 'Event saved';

  @override
  String get calendarEventDeleted => 'Event deleted';

  @override
  String get calendarEventsThisWeek => 'This week';

  @override
  String get calendarNoEventsThisWeek => 'Nothing scheduled this week';

  @override
  String calendarEventsOn(String date) {
    return 'Events on $date';
  }

  @override
  String get calendarNoEvents => 'No events on this day';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarReadOnlyHint => 'Read-only in this phase — creating and editing events arrives in Phase 3';

  @override
  String get calendarEventDetail => 'Event detail';

  @override
  String get calendarClose => 'Close';

  @override
  String get calendarLocation => 'Location';

  @override
  String get calendarReminder => 'Reminder';

  @override
  String calendarReminderMinutes(int minutes) {
    return '$minutes min before';
  }

  @override
  String get calendarNoReminder => 'None';

  @override
  String get aiPersona => 'Persona';

  @override
  String get aiPersonaSwitchSoon => 'Persona switching arrives in Phase 7';

  @override
  String aiComposerHint(String personaName) {
    return 'Message $personaName…';
  }

  @override
  String get aiSend => 'Send';

  @override
  String get aiMockNotice => 'Mock conversation — the AI provider is not connected in this phase';

  @override
  String get aiToolCallLabel => 'Tool call';

  @override
  String get aiToolRunning => 'Looking up your schedule…';

  @override
  String get aiToolDone => 'Done';

  @override
  String get aiMockUser => 'What\'s on my schedule next week?';

  @override
  String get aiMockToolSummary => 'Found 4 events';

  @override
  String get aiMockAssistant => 'You have 4 events next week. The thesis defense on Wednesday at 15:00 is the one worth preparing for.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeFollowSystem => 'Follow system';

  @override
  String get settingsThemeDefault => 'Default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsFontScale => 'Font size';

  @override
  String get settingsCornerRadius => 'Corner radius';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageFollowSystem => 'Follow system';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAiSection => 'AI & providers';

  @override
  String get settingsAiSectionSubtitle => 'Provider, persona and tool permissions (Phase 6-8)';

  @override
  String get settingsNotificationSection => 'Notifications';

  @override
  String get settingsNotificationSectionSubtitle => 'System notifications on Android, toasts on Windows';

  @override
  String get settingsNotificationPermission => 'Permission';

  @override
  String get settingsNotificationPermissionGranted => 'Allowed';

  @override
  String get settingsNotificationPermissionDenied => 'Not allowed';

  @override
  String get settingsNotificationRequest => 'Request permission';

  @override
  String get settingsNotificationExactAlarm => 'Allow precise reminders';

  @override
  String get settingsNotificationExactAlarmHint => 'Without it the system may delay reminders by a few minutes.';

  @override
  String get settingsNotificationTest => 'Send a test notification';

  @override
  String get settingsNotificationTestSent => 'Test notification scheduled (5s)';

  @override
  String get notificationDefaultBody => 'Reminder from Toki';

  @override
  String get notificationLeadNow => 'Starting now';

  @override
  String notificationLeadMinutes(int minutes) {
    return 'Starts in $minutes min';
  }

  @override
  String notificationLeadHours(int hours) {
    return 'Starts in $hours h';
  }

  @override
  String notificationLeadDays(int days) {
    return 'Starts in $days d';
  }

  @override
  String get settingsBackupSection => 'Backup & restore';

  @override
  String get settingsBackupSectionSubtitle => 'Versioned JSON export and import (Phase 12)';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'App version';

  @override
  String get settingsFlutterVersion => 'Flutter';

  @override
  String get settingsDartVersion => 'Dart';

  @override
  String get settingsProjectPath => 'Project path';

  @override
  String get settingsPhaseNote => 'Phase 5 — calendar, countdowns and system notifications are working; the AI assistant comes next.';

  @override
  String get mockEventDefense => 'Thesis defense';

  @override
  String get mockEventProjectDeadline => 'Course project deadline';

  @override
  String get mockEventLabMeeting => 'Lab meeting';

  @override
  String get mockEventMorningPlan => 'Morning planning';

  @override
  String get mockEventHealthCheck => 'Health check-up';

  @override
  String get mockEventBirthday => 'Birthday';

  @override
  String get mockLocationLab => 'Building A-302';

  @override
  String get mockLocationOnline => 'Online';

  @override
  String get mockPersonaName => 'Xiaoxue';

  @override
  String get mockPersonaDescription => 'Personal schedule assistant';

  @override
  String get mockPersonaPersonality => 'Gentle and lively, occasionally nudging you to stop procrastinating';

  @override
  String get mockPersonaSpeakingStyle => 'Short and natural, never overly formal';

  @override
  String get mockPersonaNickname => 'you';
}
