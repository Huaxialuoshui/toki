import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Toki'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Local-first AI calendar & reminders'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get navCountdown;

  /// No description provided for @navAi.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get navAi;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Planned for a later phase'**
  String get commonComingSoon;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeGreeting;

  /// No description provided for @homeWeatherPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get homeWeatherPlaceholder;

  /// No description provided for @homeWeatherHint.
  ///
  /// In en, this message translates to:
  /// **'Weather integration is reserved for a later phase'**
  String get homeWeatherHint;

  /// No description provided for @homeTodayEvents.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get homeTodayEvents;

  /// No description provided for @homeNoEvents.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled today'**
  String get homeNoEvents;

  /// No description provided for @homeCountdowns.
  ///
  /// In en, this message translates to:
  /// **'Countdowns'**
  String get homeCountdowns;

  /// No description provided for @homeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeUpcoming;

  /// No description provided for @homeAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask {personaName}'**
  String homeAskAi(String personaName);

  /// No description provided for @homeAskAiHint.
  ///
  /// In en, this message translates to:
  /// **'Chat, query your schedule, create reminders'**
  String get homeAskAiHint;

  /// No description provided for @homeOpenAi.
  ///
  /// In en, this message translates to:
  /// **'Open assistant'**
  String get homeOpenAi;

  /// No description provided for @homePhaseBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Phase 2 · local database'**
  String get homePhaseBannerTitle;

  /// No description provided for @homePhaseBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Events, countdowns and reminders are now stored in a local SQLite database on this device. Sample rows are only written in debug builds.'**
  String get homePhaseBannerBody;

  /// No description provided for @homePhaseBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get homePhaseBannerDismiss;

  /// No description provided for @countdownTimeUntil.
  ///
  /// In en, this message translates to:
  /// **'Time until {title}'**
  String countdownTimeUntil(String title);

  /// No description provided for @countdownTimeSince.
  ///
  /// In en, this message translates to:
  /// **'{title} has passed'**
  String countdownTimeSince(String title);

  /// No description provided for @countdownTargetAt.
  ///
  /// In en, this message translates to:
  /// **'Target {time}'**
  String countdownTargetAt(String time);

  /// No description provided for @countdownPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get countdownPinned;

  /// No description provided for @countdownEmpty.
  ///
  /// In en, this message translates to:
  /// **'No countdowns yet'**
  String get countdownEmpty;

  /// No description provided for @countdownNew.
  ///
  /// In en, this message translates to:
  /// **'New countdown'**
  String get countdownNew;

  /// No description provided for @countdownEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit countdown'**
  String get countdownEdit;

  /// No description provided for @countdownFieldTarget.
  ///
  /// In en, this message translates to:
  /// **'Target time'**
  String get countdownFieldTarget;

  /// No description provided for @countdownFieldStyle.
  ///
  /// In en, this message translates to:
  /// **'Display style'**
  String get countdownFieldStyle;

  /// No description provided for @countdownStyleBigNumber.
  ///
  /// In en, this message translates to:
  /// **'Big number'**
  String get countdownStyleBigNumber;

  /// No description provided for @countdownStyleFullText.
  ///
  /// In en, this message translates to:
  /// **'Full text'**
  String get countdownStyleFullText;

  /// No description provided for @countdownFieldPinned.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get countdownFieldPinned;

  /// No description provided for @countdownDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to reorder'**
  String get countdownDragHint;

  /// No description provided for @countdownDragHintLongPress.
  ///
  /// In en, this message translates to:
  /// **'Long-press the handle to reorder'**
  String get countdownDragHintLongPress;

  /// No description provided for @countdownDragHandle.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get countdownDragHandle;

  /// No description provided for @countdownDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this countdown?'**
  String get countdownDeleteConfirmTitle;

  /// No description provided for @countdownSaved.
  ///
  /// In en, this message translates to:
  /// **'Countdown saved'**
  String get countdownSaved;

  /// No description provided for @countdownDeleted.
  ///
  /// In en, this message translates to:
  /// **'Countdown deleted'**
  String get countdownDeleted;

  /// No description provided for @unitDay.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get unitDay;

  /// No description provided for @unitHour.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get unitHour;

  /// No description provided for @unitMinute.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMinute;

  /// No description provided for @unitSecond.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSecond;

  /// No description provided for @unitDayFull.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get unitDayFull;

  /// No description provided for @unitHourFull.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get unitHourFull;

  /// No description provided for @unitMinuteFull.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get unitMinuteFull;

  /// No description provided for @unitSecondFull.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get unitSecondFull;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarMonthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonthView;

  /// No description provided for @calendarWeekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeekView;

  /// No description provided for @calendarDayView.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarDayView;

  /// No description provided for @calendarNewEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarNewEvent;

  /// No description provided for @calendarEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get calendarEditEvent;

  /// No description provided for @calendarSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get calendarSave;

  /// No description provided for @calendarCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get calendarCancel;

  /// No description provided for @calendarDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get calendarDelete;

  /// No description provided for @calendarEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get calendarEdit;

  /// No description provided for @calendarDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this event?'**
  String get calendarDeleteConfirmTitle;

  /// No description provided for @calendarDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get calendarDeleteConfirmBody;

  /// No description provided for @calendarFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get calendarFieldTitle;

  /// No description provided for @calendarFieldTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get calendarFieldTitleRequired;

  /// No description provided for @calendarFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get calendarFieldDescription;

  /// No description provided for @calendarFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get calendarFieldLocation;

  /// No description provided for @calendarFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get calendarFieldCategory;

  /// No description provided for @calendarCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get calendarCategoryNone;

  /// No description provided for @calendarFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get calendarFieldColor;

  /// No description provided for @calendarColorDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get calendarColorDefault;

  /// No description provided for @calendarFieldReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get calendarFieldReminder;

  /// No description provided for @calendarReminderAtTime.
  ///
  /// In en, this message translates to:
  /// **'At start time'**
  String get calendarReminderAtTime;

  /// No description provided for @calendarReminderHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours before'**
  String calendarReminderHours(int hours);

  /// No description provided for @calendarReminderDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days before'**
  String calendarReminderDays(int days);

  /// No description provided for @calendarAllDayEvent.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDayEvent;

  /// No description provided for @calendarFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get calendarFieldStart;

  /// No description provided for @calendarFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get calendarFieldEnd;

  /// No description provided for @calendarEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get calendarEndBeforeStart;

  /// No description provided for @calendarEventSaved.
  ///
  /// In en, this message translates to:
  /// **'Event saved'**
  String get calendarEventSaved;

  /// No description provided for @calendarEventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get calendarEventDeleted;

  /// No description provided for @calendarEventsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get calendarEventsThisWeek;

  /// No description provided for @calendarNoEventsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled this week'**
  String get calendarNoEventsThisWeek;

  /// No description provided for @calendarEventsOn.
  ///
  /// In en, this message translates to:
  /// **'Events on {date}'**
  String calendarEventsOn(String date);

  /// No description provided for @calendarNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events on this day'**
  String get calendarNoEvents;

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only in this phase — creating and editing events arrives in Phase 3'**
  String get calendarReadOnlyHint;

  /// No description provided for @calendarEventDetail.
  ///
  /// In en, this message translates to:
  /// **'Event detail'**
  String get calendarEventDetail;

  /// No description provided for @calendarClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get calendarClose;

  /// No description provided for @calendarLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get calendarLocation;

  /// No description provided for @calendarReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get calendarReminder;

  /// No description provided for @calendarReminderMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String calendarReminderMinutes(int minutes);

  /// No description provided for @calendarNoReminder.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get calendarNoReminder;

  /// No description provided for @aiPersona.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get aiPersona;

  /// No description provided for @aiComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Message {personaName}…'**
  String aiComposerHint(String personaName);

  /// No description provided for @aiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiSend;

  /// No description provided for @aiMockNotice.
  ///
  /// In en, this message translates to:
  /// **'Mock conversation — the AI provider is not connected in this phase'**
  String get aiMockNotice;

  /// No description provided for @aiToolCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Tool call'**
  String get aiToolCallLabel;

  /// No description provided for @aiToolRunning.
  ///
  /// In en, this message translates to:
  /// **'Running: {tool}'**
  String aiToolRunning(String tool);

  /// No description provided for @aiToolDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aiToolDone;

  /// No description provided for @aiMockUser.
  ///
  /// In en, this message translates to:
  /// **'What\'s on my schedule next week?'**
  String get aiMockUser;

  /// No description provided for @aiMockToolSummary.
  ///
  /// In en, this message translates to:
  /// **'Found 4 events'**
  String get aiMockToolSummary;

  /// No description provided for @aiMockAssistant.
  ///
  /// In en, this message translates to:
  /// **'You have 4 events next week. The thesis defense on Wednesday at 15:00 is the one worth preparing for.'**
  String get aiMockAssistant;

  /// No description provided for @aiNoProvider.
  ///
  /// In en, this message translates to:
  /// **'No AI provider configured yet'**
  String get aiNoProvider;

  /// No description provided for @aiNoProviderHint.
  ///
  /// In en, this message translates to:
  /// **'Add a Base URL and model in Settings to start chatting.'**
  String get aiNoProviderHint;

  /// No description provided for @aiOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get aiOpenSettings;

  /// No description provided for @aiStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get aiStop;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiThinking;

  /// No description provided for @aiEmptyConversation.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {personaName}'**
  String aiEmptyConversation(String personaName);

  /// No description provided for @aiClearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get aiClearConversation;

  /// No description provided for @aiClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear this conversation?'**
  String get aiClearConfirm;

  /// No description provided for @aiStreamingHint.
  ///
  /// In en, this message translates to:
  /// **'Replying…'**
  String get aiStreamingHint;

  /// No description provided for @aiProviderName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get aiProviderName;

  /// No description provided for @aiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiBaseUrl;

  /// No description provided for @aiApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiApiKey;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// No description provided for @aiTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get aiTemperature;

  /// No description provided for @aiMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max tokens'**
  String get aiMaxTokens;

  /// No description provided for @aiStreamingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Streaming output'**
  String get aiStreamingEnabled;

  /// No description provided for @aiSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get aiSetDefault;

  /// No description provided for @aiDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get aiDefaultBadge;

  /// No description provided for @aiAddProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get aiAddProvider;

  /// No description provided for @aiEditProvider.
  ///
  /// In en, this message translates to:
  /// **'Edit provider'**
  String get aiEditProvider;

  /// No description provided for @aiNoProviders.
  ///
  /// In en, this message translates to:
  /// **'No providers configured'**
  String get aiNoProviders;

  /// No description provided for @aiPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick fill'**
  String get aiPresets;

  /// No description provided for @aiTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get aiTestConnection;

  /// No description provided for @aiTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connected: {reply}'**
  String aiTestOk(String reply);

  /// No description provided for @aiFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get aiFieldRequired;

  /// No description provided for @aiInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get aiInvalidUrl;

  /// No description provided for @aiShowKey.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get aiShowKey;

  /// No description provided for @aiHideKey.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get aiHideKey;

  /// No description provided for @aiKeyStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'Stored only on this device, never written to logs.'**
  String get aiKeyStoredLocally;

  /// No description provided for @aiPersonaSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get aiPersonaSectionTitle;

  /// No description provided for @aiAddPersona.
  ///
  /// In en, this message translates to:
  /// **'Add persona'**
  String get aiAddPersona;

  /// No description provided for @aiEditPersona.
  ///
  /// In en, this message translates to:
  /// **'Edit persona'**
  String get aiEditPersona;

  /// No description provided for @aiNoPersonas.
  ///
  /// In en, this message translates to:
  /// **'No personas yet'**
  String get aiNoPersonas;

  /// No description provided for @aiPersonaName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get aiPersonaName;

  /// No description provided for @aiPersonaIdentity.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get aiPersonaIdentity;

  /// No description provided for @aiPersonaPersonality.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get aiPersonaPersonality;

  /// No description provided for @aiPersonaSpeakingStyle.
  ///
  /// In en, this message translates to:
  /// **'Speaking style'**
  String get aiPersonaSpeakingStyle;

  /// No description provided for @aiPersonaNickname.
  ///
  /// In en, this message translates to:
  /// **'Calls you'**
  String get aiPersonaNickname;

  /// No description provided for @aiPersonaSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get aiPersonaSystemPrompt;

  /// No description provided for @aiPersonaAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get aiPersonaAvatar;

  /// No description provided for @aiPersonaAvatarHint.
  ///
  /// In en, this message translates to:
  /// **'An emoji, a single character, or an image path/URL'**
  String get aiPersonaAvatarHint;

  /// No description provided for @aiPersonaDefaultPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are the user\'s personal schedule assistant. Keep answers short and natural. Always use tools when changing the calendar, and never claim an action you did not perform.'**
  String get aiPersonaDefaultPrompt;

  /// No description provided for @aiPersonaSwitched.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String aiPersonaSwitched(String name);

  /// No description provided for @aiManagePersonas.
  ///
  /// In en, this message translates to:
  /// **'Manage personas'**
  String get aiManagePersonas;

  /// No description provided for @aiPermissionSection.
  ///
  /// In en, this message translates to:
  /// **'AI permissions'**
  String get aiPermissionSection;

  /// No description provided for @aiPermissionRead.
  ///
  /// In en, this message translates to:
  /// **'Read calendar & countdowns'**
  String get aiPermissionRead;

  /// No description provided for @aiPermissionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create events / countdowns'**
  String get aiPermissionCreate;

  /// No description provided for @aiPermissionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Modify existing items'**
  String get aiPermissionUpdate;

  /// No description provided for @aiPermissionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete items (dangerous)'**
  String get aiPermissionDelete;

  /// No description provided for @aiPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Refused tools are reported back to the assistant. Deletions always ask for your confirmation.'**
  String get aiPermissionHint;

  /// No description provided for @aiToolConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow this action?'**
  String get aiToolConfirmTitle;

  /// No description provided for @aiToolConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The assistant wants to run {tool} with:'**
  String aiToolConfirmBody(String tool);

  /// No description provided for @aiToolConfirmAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get aiToolConfirmAllow;

  /// No description provided for @aiToolConfirmDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get aiToolConfirmDeny;

  /// No description provided for @aiToolGetCurrentTime.
  ///
  /// In en, this message translates to:
  /// **'checking the time'**
  String get aiToolGetCurrentTime;

  /// No description provided for @aiToolGetTodayEvents.
  ///
  /// In en, this message translates to:
  /// **'reading today\'s schedule'**
  String get aiToolGetTodayEvents;

  /// No description provided for @aiToolGetEvents.
  ///
  /// In en, this message translates to:
  /// **'reading your schedule'**
  String get aiToolGetEvents;

  /// No description provided for @aiToolSearchEvents.
  ///
  /// In en, this message translates to:
  /// **'searching your events'**
  String get aiToolSearchEvents;

  /// No description provided for @aiToolSummary.
  ///
  /// In en, this message translates to:
  /// **'summarising your schedule'**
  String get aiToolSummary;

  /// No description provided for @aiToolCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'creating an event'**
  String get aiToolCreateEvent;

  /// No description provided for @aiToolUpdateEvent.
  ///
  /// In en, this message translates to:
  /// **'updating an event'**
  String get aiToolUpdateEvent;

  /// No description provided for @aiToolDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'deleting an event'**
  String get aiToolDeleteEvent;

  /// No description provided for @aiToolGetCountdowns.
  ///
  /// In en, this message translates to:
  /// **'reading countdowns'**
  String get aiToolGetCountdowns;

  /// No description provided for @aiToolCreateCountdown.
  ///
  /// In en, this message translates to:
  /// **'creating a countdown'**
  String get aiToolCreateCountdown;

  /// No description provided for @aiToolUpdateCountdown.
  ///
  /// In en, this message translates to:
  /// **'updating a countdown'**
  String get aiToolUpdateCountdown;

  /// No description provided for @aiToolDeleteCountdown.
  ///
  /// In en, this message translates to:
  /// **'deleting a countdown'**
  String get aiToolDeleteCountdown;

  /// No description provided for @aiToolCreateReminder.
  ///
  /// In en, this message translates to:
  /// **'creating a reminder'**
  String get aiToolCreateReminder;

  /// No description provided for @aiToolUpdateReminder.
  ///
  /// In en, this message translates to:
  /// **'updating a reminder'**
  String get aiToolUpdateReminder;

  /// No description provided for @aiToolDeleteReminder.
  ///
  /// In en, this message translates to:
  /// **'deleting a reminder'**
  String get aiToolDeleteReminder;

  /// No description provided for @chatAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Chat appearance'**
  String get chatAppearanceSection;

  /// No description provided for @chatBackground.
  ///
  /// In en, this message translates to:
  /// **'Chat background'**
  String get chatBackground;

  /// No description provided for @chatBackgroundSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get chatBackgroundSolid;

  /// No description provided for @chatBackgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get chatBackgroundGradient;

  /// No description provided for @chatBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatBackgroundImage;

  /// No description provided for @chatBackgroundPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chatBackgroundPickImage;

  /// No description provided for @chatBackgroundClearImage.
  ///
  /// In en, this message translates to:
  /// **'Clear image'**
  String get chatBackgroundClearImage;

  /// No description provided for @chatBackgroundImageHint.
  ///
  /// In en, this message translates to:
  /// **'Local path or image URL'**
  String get chatBackgroundImageHint;

  /// No description provided for @chatBackgroundOpacity.
  ///
  /// In en, this message translates to:
  /// **'Image opacity'**
  String get chatBackgroundOpacity;

  /// No description provided for @chatBackgroundBlur.
  ///
  /// In en, this message translates to:
  /// **'Background blur'**
  String get chatBackgroundBlur;

  /// No description provided for @chatOverlayOpacity.
  ///
  /// In en, this message translates to:
  /// **'Dark overlay'**
  String get chatOverlayOpacity;

  /// No description provided for @chatUserAvatar.
  ///
  /// In en, this message translates to:
  /// **'My avatar'**
  String get chatUserAvatar;

  /// No description provided for @chatUserAvatarHint.
  ///
  /// In en, this message translates to:
  /// **'Emoji, a single character, or an image path'**
  String get chatUserAvatarHint;

  /// No description provided for @chatBubbleOpacity.
  ///
  /// In en, this message translates to:
  /// **'Bubble opacity'**
  String get chatBubbleOpacity;

  /// No description provided for @chatBubbleRadius.
  ///
  /// In en, this message translates to:
  /// **'Bubble radius'**
  String get chatBubbleRadius;

  /// No description provided for @chatFontScale.
  ///
  /// In en, this message translates to:
  /// **'Chat font size'**
  String get chatFontScale;

  /// No description provided for @chatAnimation.
  ///
  /// In en, this message translates to:
  /// **'Message animation'**
  String get chatAnimation;

  /// No description provided for @chatAppearanceReset.
  ///
  /// In en, this message translates to:
  /// **'Reset appearance'**
  String get chatAppearanceReset;

  /// No description provided for @chatAppearancePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get chatAppearancePreview;

  /// No description provided for @chatPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a preview bubble'**
  String get chatPreviewMessage;

  /// No description provided for @chatBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get chatBackgroundColor;

  /// No description provided for @chatGradientColors.
  ///
  /// In en, this message translates to:
  /// **'Gradient colours'**
  String get chatGradientColors;

  /// No description provided for @themeEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme editor'**
  String get themeEditorTitle;

  /// No description provided for @themeEditorColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get themeEditorColors;

  /// No description provided for @themeColorPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get themeColorPrimary;

  /// No description provided for @themeColorSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get themeColorSecondary;

  /// No description provided for @themeColorBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeColorBackground;

  /// No description provided for @themeColorSurface.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get themeColorSurface;

  /// No description provided for @themeColorText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get themeColorText;

  /// No description provided for @themeEditorShape.
  ///
  /// In en, this message translates to:
  /// **'Shape & effects'**
  String get themeEditorShape;

  /// No description provided for @themeFieldCardOpacity.
  ///
  /// In en, this message translates to:
  /// **'Card opacity'**
  String get themeFieldCardOpacity;

  /// No description provided for @themeFieldBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get themeFieldBlur;

  /// No description provided for @themeFieldShadow.
  ///
  /// In en, this message translates to:
  /// **'Shadow'**
  String get themeFieldShadow;

  /// No description provided for @themeFieldAnimation.
  ///
  /// In en, this message translates to:
  /// **'Transitions'**
  String get themeFieldAnimation;

  /// No description provided for @themeBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get themeBrightness;

  /// No description provided for @themeBrightnessLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeBrightnessLight;

  /// No description provided for @themeBrightnessDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeBrightnessDark;

  /// No description provided for @themeEditorPreview.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get themeEditorPreview;

  /// No description provided for @themeSave.
  ///
  /// In en, this message translates to:
  /// **'Save theme'**
  String get themeSave;

  /// No description provided for @themeSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as new'**
  String get themeSaveAs;

  /// No description provided for @themeSaveName.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get themeSaveName;

  /// No description provided for @themeExport.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get themeExport;

  /// No description provided for @themeImport.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get themeImport;

  /// No description provided for @themeImportHint.
  ///
  /// In en, this message translates to:
  /// **'Paste theme JSON here'**
  String get themeImportHint;

  /// No description provided for @themeImported.
  ///
  /// In en, this message translates to:
  /// **'Imported theme: {name}'**
  String themeImported(String name);

  /// No description provided for @themeExported.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path} (also copied to clipboard)'**
  String themeExported(String path);

  /// No description provided for @themeExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String themeExportFailed(String error);

  /// No description provided for @themeImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed — please check the JSON'**
  String get themeImportFailed;

  /// No description provided for @themeSaved.
  ///
  /// In en, this message translates to:
  /// **'Theme saved'**
  String get themeSaved;

  /// No description provided for @themeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Theme deleted'**
  String get themeDeleted;

  /// No description provided for @themeDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete the theme \"{name}\"? This cannot be undone.'**
  String themeDeleteConfirmBody(String name);

  /// No description provided for @themeNew.
  ///
  /// In en, this message translates to:
  /// **'New theme'**
  String get themeNew;

  /// No description provided for @themeEditCurrent.
  ///
  /// In en, this message translates to:
  /// **'Edit current theme'**
  String get themeEditCurrent;

  /// No description provided for @themeMyThemes.
  ///
  /// In en, this message translates to:
  /// **'My themes'**
  String get themeMyThemes;

  /// No description provided for @themeBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get themeBuiltIn;

  /// No description provided for @themePreviewCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample card'**
  String get themePreviewCardTitle;

  /// No description provided for @themePreviewCardBody.
  ///
  /// In en, this message translates to:
  /// **'This is how cards, buttons and text will look.'**
  String get themePreviewCardBody;

  /// No description provided for @themePreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Primary action'**
  String get themePreviewAction;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsThemeFollowSystem;

  /// No description provided for @settingsThemeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsThemeDefault;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsFontScale.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get settingsFontScale;

  /// No description provided for @settingsCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get settingsCornerRadius;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsLanguageFollowSystem;

  /// No description provided for @settingsLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get settingsLanguageChinese;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsAiSection.
  ///
  /// In en, this message translates to:
  /// **'AI & providers'**
  String get settingsAiSection;

  /// No description provided for @settingsAiSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provider, persona and tool permissions (Phase 6-8)'**
  String get settingsAiSectionSubtitle;

  /// No description provided for @settingsNotificationSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationSection;

  /// No description provided for @settingsNotificationSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System notifications on Android, toasts on Windows'**
  String get settingsNotificationSectionSubtitle;

  /// No description provided for @settingsNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get settingsNotificationPermission;

  /// No description provided for @settingsNotificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get settingsNotificationPermissionGranted;

  /// No description provided for @settingsNotificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get settingsNotificationPermissionDenied;

  /// No description provided for @settingsNotificationRequest.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get settingsNotificationRequest;

  /// No description provided for @settingsNotificationExactAlarm.
  ///
  /// In en, this message translates to:
  /// **'Allow precise reminders'**
  String get settingsNotificationExactAlarm;

  /// No description provided for @settingsNotificationExactAlarmHint.
  ///
  /// In en, this message translates to:
  /// **'Without it the system may delay reminders by a few minutes.'**
  String get settingsNotificationExactAlarmHint;

  /// No description provided for @settingsNotificationTest.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification'**
  String get settingsNotificationTest;

  /// No description provided for @settingsNotificationTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification scheduled (5s)'**
  String get settingsNotificationTestSent;

  /// No description provided for @notificationDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Reminder from Toki'**
  String get notificationDefaultBody;

  /// No description provided for @notificationLeadNow.
  ///
  /// In en, this message translates to:
  /// **'Starting now'**
  String get notificationLeadNow;

  /// No description provided for @notificationLeadMinutes.
  ///
  /// In en, this message translates to:
  /// **'Starts in {minutes} min'**
  String notificationLeadMinutes(int minutes);

  /// No description provided for @notificationLeadHours.
  ///
  /// In en, this message translates to:
  /// **'Starts in {hours} h'**
  String notificationLeadHours(int hours);

  /// No description provided for @notificationLeadDays.
  ///
  /// In en, this message translates to:
  /// **'Starts in {days} d'**
  String notificationLeadDays(int days);

  /// No description provided for @settingsBackupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get settingsBackupSection;

  /// No description provided for @settingsBackupSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Versioned JSON export and import (Phase 12)'**
  String get settingsBackupSectionSubtitle;

  /// No description provided for @backupIntro.
  ///
  /// In en, this message translates to:
  /// **'Exports every table as one JSON file: events, countdowns, reminders, personas, providers, chats and themes. Restoring replaces or merges the local data.'**
  String get backupIntro;

  /// No description provided for @backupIncludeApiKeys.
  ///
  /// In en, this message translates to:
  /// **'Include API keys'**
  String get backupIncludeApiKeys;

  /// No description provided for @backupIncludeApiKeysHint.
  ///
  /// In en, this message translates to:
  /// **'Off by default. The file is plain text — only turn this on if you will keep it somewhere safe.'**
  String get backupIncludeApiKeysHint;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to {path} (also copied to clipboard)'**
  String backupExported(String path);

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String backupExportFailed(String error);

  /// No description provided for @backupRestoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get backupRestoreFromFile;

  /// No description provided for @backupRestoreFromPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON'**
  String get backupRestoreFromPaste;

  /// No description provided for @backupPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a Toki backup JSON here'**
  String get backupPasteHint;

  /// No description provided for @backupFileListTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup files'**
  String get backupFileListTitle;

  /// No description provided for @backupNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No backup files yet'**
  String get backupNoFiles;

  /// No description provided for @backupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get backupConfirmTitle;

  /// No description provided for @backupConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Exported {time} · {total} rows{apiKeys}'**
  String backupConfirmBody(String time, int total, String apiKeys);

  /// No description provided for @backupContainsApiKeys.
  ///
  /// In en, this message translates to:
  /// **' · contains API keys'**
  String get backupContainsApiKeys;

  /// No description provided for @backupModeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get backupModeReplace;

  /// No description provided for @backupModeReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Delete local data first, then write the backup'**
  String get backupModeReplaceHint;

  /// No description provided for @backupModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get backupModeMerge;

  /// No description provided for @backupModeMergeHint.
  ///
  /// In en, this message translates to:
  /// **'Keep local data; same ids are overwritten, new ones are added'**
  String get backupModeMergeHint;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} rows'**
  String backupRestored(int count);

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get backupRestoreFailed;

  /// No description provided for @backupDirectory.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get backupDirectory;

  /// No description provided for @backupErrorNotJson.
  ///
  /// In en, this message translates to:
  /// **'That is not valid JSON.'**
  String get backupErrorNotJson;

  /// No description provided for @backupErrorNotBackup.
  ///
  /// In en, this message translates to:
  /// **'That is not a Toki backup file.'**
  String get backupErrorNotBackup;

  /// No description provided for @backupErrorFormatVersion.
  ///
  /// In en, this message translates to:
  /// **'This backup was created by a newer version of Toki.'**
  String get backupErrorFormatVersion;

  /// No description provided for @backupErrorSchemaVersion.
  ///
  /// In en, this message translates to:
  /// **'This backup comes from a newer database version.'**
  String get backupErrorSchemaVersion;

  /// No description provided for @backupErrorMissingTables.
  ///
  /// In en, this message translates to:
  /// **'This backup has no data section.'**
  String get backupErrorMissingTables;

  /// No description provided for @backupErrorCorrupted.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged and cannot be restored.'**
  String get backupErrorCorrupted;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsVersion;

  /// No description provided for @settingsFlutterVersion.
  ///
  /// In en, this message translates to:
  /// **'Flutter'**
  String get settingsFlutterVersion;

  /// No description provided for @settingsDartVersion.
  ///
  /// In en, this message translates to:
  /// **'Dart'**
  String get settingsDartVersion;

  /// No description provided for @settingsProjectPath.
  ///
  /// In en, this message translates to:
  /// **'Project path'**
  String get settingsProjectPath;

  /// No description provided for @settingsPhaseNote.
  ///
  /// In en, this message translates to:
  /// **'Phase 12 — calendar, countdowns, notifications, the AI assistant (with tool calling), theme editing and backup/restore are working.'**
  String get settingsPhaseNote;

  /// No description provided for @mockEventDefense.
  ///
  /// In en, this message translates to:
  /// **'Thesis defense'**
  String get mockEventDefense;

  /// No description provided for @mockEventProjectDeadline.
  ///
  /// In en, this message translates to:
  /// **'Course project deadline'**
  String get mockEventProjectDeadline;

  /// No description provided for @mockEventLabMeeting.
  ///
  /// In en, this message translates to:
  /// **'Lab meeting'**
  String get mockEventLabMeeting;

  /// No description provided for @mockEventMorningPlan.
  ///
  /// In en, this message translates to:
  /// **'Morning planning'**
  String get mockEventMorningPlan;

  /// No description provided for @mockEventHealthCheck.
  ///
  /// In en, this message translates to:
  /// **'Health check-up'**
  String get mockEventHealthCheck;

  /// No description provided for @mockEventBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get mockEventBirthday;

  /// No description provided for @mockLocationLab.
  ///
  /// In en, this message translates to:
  /// **'Building A-302'**
  String get mockLocationLab;

  /// No description provided for @mockLocationOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get mockLocationOnline;

  /// No description provided for @mockPersonaName.
  ///
  /// In en, this message translates to:
  /// **'Xiaoxue'**
  String get mockPersonaName;

  /// No description provided for @mockPersonaDescription.
  ///
  /// In en, this message translates to:
  /// **'Personal schedule assistant'**
  String get mockPersonaDescription;

  /// No description provided for @mockPersonaPersonality.
  ///
  /// In en, this message translates to:
  /// **'Gentle and lively, occasionally nudging you to stop procrastinating'**
  String get mockPersonaPersonality;

  /// No description provided for @mockPersonaSpeakingStyle.
  ///
  /// In en, this message translates to:
  /// **'Short and natural, never overly formal'**
  String get mockPersonaSpeakingStyle;

  /// No description provided for @mockPersonaNickname.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get mockPersonaNickname;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
