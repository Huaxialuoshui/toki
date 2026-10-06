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
  String get homePhaseBannerTitle => 'Phase 1 skeleton';

  @override
  String get homePhaseBannerBody => 'Layout, theming and both languages are wired up. All data below is mock content until the database lands in Phase 2.';

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
  String get countdownReadOnlyHint => 'Creating, editing and reordering countdowns arrives in Phase 4';

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
  String get calendarWeekDayComingSoon => 'Week and day views arrive in Phase 3';

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
  String get settingsNotificationSectionSubtitle => 'Local notifications and toasts (Phase 5)';

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
  String get settingsPhaseNote => 'Phase 1 — environment, app shell, responsive layout, theming and i18n.';

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
