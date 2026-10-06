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

  /// No description provided for @aiPersonaSwitchSoon.
  ///
  /// In en, this message translates to:
  /// **'Persona switching arrives in Phase 7'**
  String get aiPersonaSwitchSoon;

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
  /// **'Looking up your schedule…'**
  String get aiToolRunning;

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
  /// **'Local notifications and toasts (Phase 5)'**
  String get settingsNotificationSectionSubtitle;

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
  /// **'Phase 2 — local database (Drift + SQLite), repositories and migration tests.'**
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
