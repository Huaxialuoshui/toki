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
  String get homeWeatherHint =>
      'Weather integration is reserved for a later phase';

  @override
  String homeWeatherDetail(String city, String min, String max) {
    return '$city · Low $min° / High $max°';
  }

  @override
  String get weatherCity => 'City';

  @override
  String get weatherCityHint => 'e.g. Shanghai / 上海';

  @override
  String get weatherCitySaved => 'City saved';

  @override
  String get weatherSection => 'Weather';

  @override
  String get weatherSectionSubtitle =>
      'Uses Open-Meteo, no API key needed. The card on the home page stays a placeholder while the city is empty.';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Overcast';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherThunder => 'Thunderstorm';

  @override
  String get weatherUnknown => 'Unknown';

  @override
  String get weatherSave => 'Save';

  @override
  String get weatherClearCity => 'Clear';

  @override
  String get digestSection => 'Daily briefings';

  @override
  String get digestSectionSubtitle =>
      'Ask the assistant to write a morning plan and an evening recap. Off by default; generated at most once per day.';

  @override
  String get digestMorningToggle => 'Morning plan';

  @override
  String get digestEveningToggle => 'Evening recap';

  @override
  String get digestMorningTitle => 'Today\'s plan';

  @override
  String get digestEveningTitle => 'Today\'s recap';

  @override
  String get digestGenerate => 'Generate';

  @override
  String get digestRegenerate => 'Regenerate';

  @override
  String get digestGenerating => 'The assistant is writing…';

  @override
  String get digestFailed => 'Could not generate';

  @override
  String get syncSection => 'Data sync';

  @override
  String get syncLocalTitle => 'This device only';

  @override
  String get syncLocalSubtitle =>
      'Version 1 is local-first: everything lives in the local database. WebDAV / self-hosted / cloud sync is planned behind the same SyncService interface.';

  @override
  String get syncNow => 'Check local data';

  @override
  String syncLocalDone(String message) {
    return 'Local data is ready ($message)';
  }

  @override
  String get widgetSection => 'Home-screen widget';

  @override
  String get widgetSectionSubtitle =>
      'Shows the nearest countdown or event on your Android home screen. Skin, icon and background image are up to you.';

  @override
  String get widgetBackground => 'Background';

  @override
  String get widgetSkinSolid => 'Solid';

  @override
  String get widgetSkinGradient => 'Gradient';

  @override
  String get widgetSkinImage => 'Image';

  @override
  String get widgetBackgroundImage => 'Background image';

  @override
  String get widgetPickImage => 'Pick image';

  @override
  String get widgetClearImage => 'Remove image';

  @override
  String get widgetTextColor => 'Text colour';

  @override
  String get widgetAccentColor => 'Accent colour';

  @override
  String get widgetIconStyle => 'Icon style';

  @override
  String get widgetIconOutlined => 'Outlined';

  @override
  String get widgetIconFilled => 'Filled';

  @override
  String get widgetCornerRadius => 'Corner radius';

  @override
  String get widgetShowCountdown => 'Show countdown';

  @override
  String get widgetShowEvent => 'Show next event';

  @override
  String get widgetTransparent => 'Translucent background';

  @override
  String get widgetRefreshNow => 'Refresh widget now';

  @override
  String get widgetAddToHome => 'Add to home screen';

  @override
  String get widgetAddToHomeHint =>
      'If the launcher supports it, confirm the system dialog to pin the widget.';

  @override
  String get widgetRefreshed => 'Widget refreshed';

  @override
  String get widgetBackgroundService => 'Keep running in background';

  @override
  String get widgetBackgroundServiceHint =>
      'Android requires a silent, minimal notification for this. It keeps widget refreshes and reminders alive when the system would otherwise kill the process.';

  @override
  String get widgetBatteryOptimization => 'Ignore battery optimizations';

  @override
  String get widgetBatteryOptimizationHint =>
      'Lets the system stop killing Toki in the background. Opens a system dialog.';

  @override
  String get widgetBatteryOptimizationDone => 'Requested';

  @override
  String get widgetNextEventTitle => 'Next event';

  @override
  String widgetNextEvent(String name, String time) {
    return 'Next: $name · $time';
  }

  @override
  String get widgetNoUpcoming => 'Nothing scheduled';

  @override
  String widgetUpdatedAt(Object time) {
    return 'Updated $time';
  }

  @override
  String get widgetCountdownPast => 'Already passed';

  @override
  String widgetRemainingDays(int days, int hours) {
    return '$days d $hours h left';
  }

  @override
  String widgetRemainingHours(int hours, int minutes) {
    return '$hours h $minutes min left';
  }

  @override
  String widgetRemainingMinutes(int minutes) {
    return '$minutes min left';
  }

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
  String get homePhaseBannerBody =>
      'Events, countdowns and reminders are now stored in a local SQLite database on this device. Sample rows are only written in debug builds.';

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
  String get countdownFieldBackground => 'Card background';

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
  String get calendarFieldRepeat => 'Repeat';

  @override
  String get calendarRepeatNone => 'Does not repeat';

  @override
  String get calendarRepeatDaily => 'Every day';

  @override
  String get calendarRepeatWeekly => 'Every week';

  @override
  String get calendarRepeatMonthly => 'Every month';

  @override
  String get calendarRepeatYearly => 'Every year';

  @override
  String get calendarRepeatForever => 'No end date';

  @override
  String calendarRepeatUntil(String date) {
    return 'Until $date';
  }

  @override
  String get calendarReminderCustom => 'Custom lead time';

  @override
  String get calendarCategorySection => 'Calendar categories';

  @override
  String get calendarCategoryAdd => 'Add category';

  @override
  String get calendarCategoryEdit => 'Edit category';

  @override
  String get calendarCategoryName => 'Name';

  @override
  String get calendarCategoryColor => 'Colour';

  @override
  String get calendarCategoryEmpty => 'No categories yet';

  @override
  String get calendarCategorySaved => 'Category saved';

  @override
  String get calendarCategoryDeleted => 'Category deleted';

  @override
  String get calendarCategoryDeleteTitle => 'Delete this category?';

  @override
  String calendarCategoryDeleteBody(String name) {
    return 'Events in \"$name\" will become uncategorised. The events themselves are kept.';
  }

  @override
  String get calendarUnitMinutes => 'minutes';

  @override
  String get calendarUnitHours => 'hours';

  @override
  String get calendarUnitDays => 'days';

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
  String get calendarReadOnlyHint =>
      'Read-only in this phase — creating and editing events arrives in Phase 3';

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
  String aiComposerHint(String personaName) {
    return 'Message $personaName…';
  }

  @override
  String get aiSend => 'Send';

  @override
  String get aiMockNotice =>
      'Mock conversation — the AI provider is not connected in this phase';

  @override
  String get aiToolCallLabel => 'Tool call';

  @override
  String aiToolRunning(String tool) {
    return 'Running: $tool';
  }

  @override
  String get aiToolDone => 'Done';

  @override
  String get aiMockUser => 'What\'s on my schedule next week?';

  @override
  String get aiMockToolSummary => 'Found 4 events';

  @override
  String get aiMockAssistant =>
      'You have 4 events next week. The thesis defense on Wednesday at 15:00 is the one worth preparing for.';

  @override
  String get aiNoProvider => 'No AI provider configured yet';

  @override
  String get aiNoProviderHint =>
      'Add a Base URL and model in Settings to start chatting.';

  @override
  String get aiOpenSettings => 'Open settings';

  @override
  String get aiStop => 'Stop';

  @override
  String get aiThinking => 'Thinking…';

  @override
  String aiEmptyConversation(String personaName) {
    return 'Say hello to $personaName';
  }

  @override
  String get aiClearConversation => 'Clear conversation';

  @override
  String get aiSessions => 'Chats';

  @override
  String get aiNewSession => 'New chat';

  @override
  String get aiSessionEmpty => 'No chats yet';

  @override
  String get aiDeleteSession => 'Delete chat';

  @override
  String get aiDeleteSessionConfirm =>
      'Delete this chat and all of its messages?';

  @override
  String get aiMessageCopy => 'Copy';

  @override
  String get aiMessageCopied => 'Copied';

  @override
  String get aiMessageEdit => 'Edit and resend';

  @override
  String get aiMessageRegenerate => 'Regenerate';

  @override
  String get aiMessageDelete => 'Delete message';

  @override
  String get aiReasoningTitle => 'Reasoning';

  @override
  String aiReasoningShow(int count) {
    return 'Thought for $count characters · tap to view';
  }

  @override
  String get aiReasoningHide => 'Hide reasoning';

  @override
  String get aiThinkingHard => 'Thinking…';

  @override
  String get aiEditMessageTitle => 'Edit message';

  @override
  String get aiSwitchProvider => 'AI provider';

  @override
  String get aiNoProviderShort => 'No provider';

  @override
  String get aiClearConfirm => 'Clear this conversation?';

  @override
  String get aiStreamingHint => 'Replying…';

  @override
  String get aiProviderName => 'Name';

  @override
  String get aiBaseUrl => 'Base URL';

  @override
  String get aiApiKey => 'API Key';

  @override
  String get aiModel => 'Model';

  @override
  String get aiSelectModel => 'Choose model';

  @override
  String get aiModelPickerTitle => 'Choose a model';

  @override
  String get aiModelSearchHint => 'Filter models';

  @override
  String aiModelsLoaded(int count) {
    return '$count models available';
  }

  @override
  String get aiNoModels =>
      'The provider returned no models. Use manual input below.';

  @override
  String get aiFetchModelsFailed => 'Could not fetch models';

  @override
  String get aiRetry => 'Retry';

  @override
  String get aiModelManual => 'Enter manually';

  @override
  String get aiModelManualHint =>
      'Type the model name if the provider has no model list.';

  @override
  String aiModelSelected(String model) {
    return 'Selected model: $model';
  }

  @override
  String get aiTemperature => 'Temperature';

  @override
  String get aiMaxTokens => 'Max tokens';

  @override
  String get aiStreamingEnabled => 'Streaming output';

  @override
  String get aiSetDefault => 'Set as default';

  @override
  String get aiDefaultBadge => 'Default';

  @override
  String get aiAddProvider => 'Add provider';

  @override
  String get aiEditProvider => 'Edit provider';

  @override
  String get aiNoProviders => 'No providers configured';

  @override
  String get aiPresets => 'Quick fill';

  @override
  String get aiTestConnection => 'Test connection';

  @override
  String aiTestOk(String reply) {
    return 'Connected: $reply';
  }

  @override
  String get aiFieldRequired => 'Required';

  @override
  String get aiInvalidUrl => 'URL must start with http:// or https://';

  @override
  String get aiShowKey => 'Show';

  @override
  String get aiHideKey => 'Hide';

  @override
  String get aiKeyStoredLocally =>
      'Stored only on this device, never written to logs.';

  @override
  String get aiPersonaSectionTitle => 'Personas';

  @override
  String get aiAddPersona => 'Add persona';

  @override
  String get aiEditPersona => 'Edit persona';

  @override
  String get aiNoPersonas => 'No personas yet';

  @override
  String get aiPersonaName => 'Name';

  @override
  String get aiPersonaIdentity => 'Role';

  @override
  String get aiPersonaPersonality => 'Personality';

  @override
  String get aiPersonaSpeakingStyle => 'Speaking style';

  @override
  String get aiPersonaNickname => 'Calls you';

  @override
  String get aiPersonaSystemPrompt => 'System prompt';

  @override
  String get aiPersonaAvatar => 'Avatar';

  @override
  String get aiPersonaAvatarHint =>
      'An emoji, a single character, or an image path/URL';

  @override
  String get aiPersonaDefaultPrompt =>
      'You are the user\'s personal schedule assistant. Keep answers short and natural. Always use tools when changing the calendar, and never claim an action you did not perform.';

  @override
  String aiPersonaSwitched(String name) {
    return 'Switched to $name';
  }

  @override
  String get aiManagePersonas => 'Manage personas';

  @override
  String get aiPermissionSection => 'AI permissions';

  @override
  String get aiPermissionRead => 'Read calendar & countdowns';

  @override
  String get aiPermissionCreate => 'Create events / countdowns';

  @override
  String get aiPermissionUpdate => 'Modify existing items';

  @override
  String get aiPermissionDelete => 'Delete items (dangerous)';

  @override
  String get aiPermissionHint =>
      'Refused tools are reported back to the assistant. Deletions always ask for your confirmation.';

  @override
  String get aiToolConfirmTitle => 'Allow this action?';

  @override
  String aiToolConfirmBody(String tool) {
    return 'The assistant wants to run $tool with:';
  }

  @override
  String get aiToolConfirmAllow => 'Allow';

  @override
  String get aiToolConfirmDeny => 'Deny';

  @override
  String get aiToolGetCurrentTime => 'checking the time';

  @override
  String get aiToolGetTodayEvents => 'reading today\'s schedule';

  @override
  String get aiToolGetEvents => 'reading your schedule';

  @override
  String get aiToolSearchEvents => 'searching your events';

  @override
  String get aiToolSummary => 'summarising your schedule';

  @override
  String get aiToolCreateEvent => 'creating an event';

  @override
  String get aiToolUpdateEvent => 'updating an event';

  @override
  String get aiToolDeleteEvent => 'deleting an event';

  @override
  String get aiToolGetCountdowns => 'reading countdowns';

  @override
  String get aiToolCreateCountdown => 'creating a countdown';

  @override
  String get aiToolUpdateCountdown => 'updating a countdown';

  @override
  String get aiToolDeleteCountdown => 'deleting a countdown';

  @override
  String get aiToolCreateReminder => 'creating a reminder';

  @override
  String get aiToolUpdateReminder => 'updating a reminder';

  @override
  String get aiToolDeleteReminder => 'deleting a reminder';

  @override
  String get chatAppearanceSection => 'Chat appearance';

  @override
  String get chatBackground => 'Chat background';

  @override
  String get chatBackgroundSolid => 'Solid';

  @override
  String get chatBackgroundGradient => 'Gradient';

  @override
  String get chatBackgroundImage => 'Image';

  @override
  String get chatBackgroundPickImage => 'Choose image';

  @override
  String get chatBackgroundClearImage => 'Clear image';

  @override
  String get chatBackgroundImageHint => 'Local path or image URL';

  @override
  String get chatBackgroundOpacity => 'Image opacity';

  @override
  String get chatBackgroundBlur => 'Background blur';

  @override
  String get chatOverlayOpacity => 'Dark overlay';

  @override
  String get chatUserAvatar => 'My avatar';

  @override
  String get chatUserAvatarHint =>
      'Emoji, a single character, or an image path';

  @override
  String get chatBubbleOpacity => 'Bubble opacity';

  @override
  String get chatBubbleRadius => 'Bubble radius';

  @override
  String get chatFontScale => 'Chat font size';

  @override
  String get chatAnimation => 'Message animation';

  @override
  String get chatAppearanceReset => 'Reset appearance';

  @override
  String get chatAppearancePreview => 'Preview';

  @override
  String get chatPreviewMessage => 'This is a preview bubble';

  @override
  String get chatBackgroundColor => 'Colour';

  @override
  String get chatGradientColors => 'Gradient colours';

  @override
  String get themeEditorTitle => 'Theme editor';

  @override
  String get themeEditorColors => 'Colours';

  @override
  String get themeColorPrimary => 'Primary';

  @override
  String get themeColorSecondary => 'Secondary';

  @override
  String get themeColorBackground => 'Background';

  @override
  String get themeColorSurface => 'Cards';

  @override
  String get themeColorText => 'Text';

  @override
  String get themeEditorShape => 'Shape & effects';

  @override
  String get themeFieldCardOpacity => 'Card opacity';

  @override
  String get themeFieldBlur => 'Blur';

  @override
  String get themeFieldShadow => 'Shadow';

  @override
  String get themeFieldAnimation => 'Transitions';

  @override
  String get themeBrightness => 'Brightness';

  @override
  String get themeBrightnessLight => 'Light';

  @override
  String get themeBrightnessDark => 'Dark';

  @override
  String get themeEditorPreview => 'Live preview';

  @override
  String get themeEditorAreas => 'Per-area colours';

  @override
  String get themeEditorAreasHint =>
      'Optional. Leave any of them on \"Default\" to follow the theme colours above.';

  @override
  String get themeAreaNavBar => 'Nav bar';

  @override
  String get themeAreaSidebar => 'Sidebar';

  @override
  String get themeAreaEvent => 'Calendar events';

  @override
  String get themeAreaCountdown => 'Countdowns';

  @override
  String get themeSave => 'Save theme';

  @override
  String get themeSaveAs => 'Save as new';

  @override
  String get themeSaveName => 'Theme name';

  @override
  String get themeExport => 'Export JSON';

  @override
  String get themeImport => 'Import JSON';

  @override
  String get themeImportHint => 'Paste theme JSON here';

  @override
  String themeImported(String name) {
    return 'Imported theme: $name';
  }

  @override
  String themeExported(String path) {
    return 'Exported to $path (also copied to clipboard)';
  }

  @override
  String themeExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get themeImportFailed => 'Import failed — please check the JSON';

  @override
  String get themeSaved => 'Theme saved';

  @override
  String get themeDeleted => 'Theme deleted';

  @override
  String themeDeleteConfirmBody(String name) {
    return 'Delete the theme \"$name\"? This cannot be undone.';
  }

  @override
  String get themeNew => 'New theme';

  @override
  String get themeEditCurrent => 'Edit current theme';

  @override
  String get themeMyThemes => 'My themes';

  @override
  String get themeBuiltIn => 'Built-in';

  @override
  String get themePreviewCardTitle => 'Sample card';

  @override
  String get themePreviewCardBody =>
      'This is how cards, buttons and text will look.';

  @override
  String get themePreviewAction => 'Primary action';

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
  String get settingsAiSectionSubtitle =>
      'Provider, persona and tool permissions (Phase 6-8)';

  @override
  String get settingsNotificationSection => 'Notifications';

  @override
  String get settingsNotificationSectionSubtitle =>
      'System notifications on Android, toasts on Windows';

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
  String get settingsNotificationExactAlarmHint =>
      'Without it the system may delay reminders by a few minutes.';

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
  String get settingsBackupSectionSubtitle =>
      'Versioned JSON export and import (Phase 12)';

  @override
  String get backupIntro =>
      'Exports every table as one JSON file: events, countdowns, reminders, personas, providers, chats and themes. Restoring replaces or merges the local data.';

  @override
  String get backupIncludeApiKeys => 'Include API keys';

  @override
  String get backupIncludeApiKeysHint =>
      'Off by default. The file is plain text — only turn this on if you will keep it somewhere safe.';

  @override
  String get backupExport => 'Export backup';

  @override
  String backupExported(String path) {
    return 'Backup saved to $path (also copied to clipboard)';
  }

  @override
  String backupExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get backupRestoreFromFile => 'Restore from file';

  @override
  String get backupRestoreFromPaste => 'Paste JSON';

  @override
  String get backupPasteHint => 'Paste a Toki backup JSON here';

  @override
  String get backupFileListTitle => 'Backup files';

  @override
  String get backupNoFiles => 'No backup files yet';

  @override
  String get backupConfirmTitle => 'Restore this backup?';

  @override
  String backupConfirmBody(String time, int total, String apiKeys) {
    return 'Exported $time · $total rows$apiKeys';
  }

  @override
  String get backupContainsApiKeys => ' · contains API keys';

  @override
  String get backupModeReplace => 'Replace';

  @override
  String get backupModeReplaceHint =>
      'Delete local data first, then write the backup';

  @override
  String get backupModeMerge => 'Merge';

  @override
  String get backupModeMergeHint =>
      'Keep local data; same ids are overwritten, new ones are added';

  @override
  String backupRestored(int count) {
    return 'Restored $count rows';
  }

  @override
  String get backupRestoreFailed => 'Restore failed';

  @override
  String get backupDirectory => 'Backup folder';

  @override
  String get backupErrorNotJson => 'That is not valid JSON.';

  @override
  String get backupErrorNotBackup => 'That is not a Toki backup file.';

  @override
  String get backupErrorFormatVersion =>
      'This backup was created by a newer version of Toki.';

  @override
  String get backupErrorSchemaVersion =>
      'This backup comes from a newer database version.';

  @override
  String get backupErrorMissingTables => 'This backup has no data section.';

  @override
  String get backupErrorCorrupted =>
      'This backup is damaged and cannot be restored.';

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
  String get settingsPhaseNote =>
      'Phase 12 — calendar, countdowns, notifications, the AI assistant (with tool calling), theme editing and backup/restore are working.';

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
  String get mockPersonaPersonality =>
      'Gentle and lively, occasionally nudging you to stop procrastinating';

  @override
  String get mockPersonaSpeakingStyle =>
      'Short and natural, never overly formal';

  @override
  String get mockPersonaNickname => 'you';
}
