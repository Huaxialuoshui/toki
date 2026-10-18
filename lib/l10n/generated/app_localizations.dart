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
  /// **'Tap to add a city or use your current location'**
  String get homeWeatherHint;

  /// No description provided for @homeWeatherUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String homeWeatherUpdated(String time);

  /// No description provided for @homeWeatherDetail.
  ///
  /// In en, this message translates to:
  /// **'{city} · Low {min}° / High {max}°'**
  String homeWeatherDetail(String city, String min, String max);

  /// No description provided for @weatherCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get weatherCity;

  /// No description provided for @weatherCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shanghai / 上海'**
  String get weatherCityHint;

  /// No description provided for @weatherCitySaved.
  ///
  /// In en, this message translates to:
  /// **'City saved'**
  String get weatherCitySaved;

  /// No description provided for @weatherSection.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherSection;

  /// No description provided for @weatherSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses Open-Meteo, no API key needed. Add a city or use your current location to show live weather on the home page.'**
  String get weatherSectionSubtitle;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherThunder.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunder;

  /// No description provided for @weatherUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get weatherUnknown;

  /// No description provided for @weatherSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get weatherSave;

  /// No description provided for @weatherClearCity.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClearCity;

  /// No description provided for @weatherUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get weatherUseCurrentLocation;

  /// No description provided for @weatherLocationUsed.
  ///
  /// In en, this message translates to:
  /// **'Current location saved'**
  String get weatherLocationUsed;

  /// No description provided for @weatherLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Location failed'**
  String get weatherLocationFailed;

  /// No description provided for @weatherNoLocations.
  ///
  /// In en, this message translates to:
  /// **'No saved locations yet — add a city or use your current location.'**
  String get weatherNoLocations;

  /// No description provided for @weatherDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherDetailTitle;

  /// No description provided for @weatherHourly.
  ///
  /// In en, this message translates to:
  /// **'Next hours'**
  String get weatherHourly;

  /// No description provided for @weatherDaily.
  ///
  /// In en, this message translates to:
  /// **'Next days'**
  String get weatherDaily;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherToday;

  /// No description provided for @weatherNoForecast.
  ///
  /// In en, this message translates to:
  /// **'No forecast data'**
  String get weatherNoForecast;

  /// No description provided for @appBackground.
  ///
  /// In en, this message translates to:
  /// **'App background'**
  String get appBackground;

  /// No description provided for @appBackgroundHint.
  ///
  /// In en, this message translates to:
  /// **'Applies behind every page. Chat has its own background in the section above.'**
  String get appBackgroundHint;

  /// No description provided for @appAutoContrast.
  ///
  /// In en, this message translates to:
  /// **'Adapt text colour automatically'**
  String get appAutoContrast;

  /// No description provided for @appAutoContrastHint.
  ///
  /// In en, this message translates to:
  /// **'Switches between light and dark text based on the background, and adds a subtle scrim when the image mixes light and dark areas.'**
  String get appAutoContrastHint;

  /// No description provided for @iconStyle.
  ///
  /// In en, this message translates to:
  /// **'Icon style'**
  String get iconStyle;

  /// No description provided for @iconStyleOutlined.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get iconStyleOutlined;

  /// No description provided for @iconStyleFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get iconStyleFilled;

  /// No description provided for @appIcon.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get appIcon;

  /// No description provided for @appIconHint.
  ///
  /// In en, this message translates to:
  /// **'Use your own picture as the icon. Android: swaps the icon in Recents and creates a home-screen shortcut with this picture (the system asks for confirmation — tap Add; the launcher-drawn app icon itself cannot be changed from inside the app). Windows: swaps the window and taskbar icon; the exe\'s own icon needs a rebuild.'**
  String get appIconHint;

  /// No description provided for @appIconPick.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get appIconPick;

  /// No description provided for @appIconApply.
  ///
  /// In en, this message translates to:
  /// **'Apply to system'**
  String get appIconApply;

  /// No description provided for @appIconReset.
  ///
  /// In en, this message translates to:
  /// **'Restore default'**
  String get appIconReset;

  /// No description provided for @appIconApplied.
  ///
  /// In en, this message translates to:
  /// **'Recents icon updated'**
  String get appIconApplied;

  /// No description provided for @appIconAppliedShortcut.
  ///
  /// In en, this message translates to:
  /// **'Applied — tap Add when the system asks to create the shortcut'**
  String get appIconAppliedShortcut;

  /// No description provided for @appIconResetDone.
  ///
  /// In en, this message translates to:
  /// **'Default icon restored'**
  String get appIconResetDone;

  /// No description provided for @appIconFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not set the app icon'**
  String get appIconFailed;

  /// No description provided for @editImage.
  ///
  /// In en, this message translates to:
  /// **'Edit with system tool'**
  String get editImage;

  /// No description provided for @editImageDone.
  ///
  /// In en, this message translates to:
  /// **'Image updated'**
  String get editImageDone;

  /// No description provided for @editImageUnchanged.
  ///
  /// In en, this message translates to:
  /// **'No changes were made'**
  String get editImageUnchanged;

  /// No description provided for @editImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the image editor'**
  String get editImageFailed;

  /// No description provided for @aiAvatarMenu.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get aiAvatarMenu;

  /// No description provided for @aiAvatarMine.
  ///
  /// In en, this message translates to:
  /// **'My avatar'**
  String get aiAvatarMine;

  /// No description provided for @aiAvatarAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant avatar'**
  String get aiAvatarAssistant;

  /// No description provided for @aiAvatarSaved.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get aiAvatarSaved;

  /// No description provided for @aiAvatarOnlyLocal.
  ///
  /// In en, this message translates to:
  /// **'Only local images can be edited with the system editor'**
  String get aiAvatarOnlyLocal;

  /// No description provided for @digestSection.
  ///
  /// In en, this message translates to:
  /// **'Daily briefings'**
  String get digestSection;

  /// No description provided for @digestSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant to write a morning plan and an evening recap. Off by default; generated at most once per day.'**
  String get digestSectionSubtitle;

  /// No description provided for @digestMorningToggle.
  ///
  /// In en, this message translates to:
  /// **'Morning plan'**
  String get digestMorningToggle;

  /// No description provided for @digestEveningToggle.
  ///
  /// In en, this message translates to:
  /// **'Evening recap'**
  String get digestEveningToggle;

  /// No description provided for @digestMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan'**
  String get digestMorningTitle;

  /// No description provided for @digestEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s recap'**
  String get digestEveningTitle;

  /// No description provided for @digestGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get digestGenerate;

  /// No description provided for @digestRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get digestRegenerate;

  /// No description provided for @digestGenerating.
  ///
  /// In en, this message translates to:
  /// **'The assistant is writing…'**
  String get digestGenerating;

  /// No description provided for @digestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate'**
  String get digestFailed;

  /// No description provided for @syncSection.
  ///
  /// In en, this message translates to:
  /// **'Data sync'**
  String get syncSection;

  /// No description provided for @syncLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'This device only'**
  String get syncLocalTitle;

  /// No description provided for @syncLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version 1 is local-first: everything lives in the local database. WebDAV / self-hosted / cloud sync is planned behind the same SyncService interface.'**
  String get syncLocalSubtitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Check local data'**
  String get syncNow;

  /// No description provided for @syncLocalDone.
  ///
  /// In en, this message translates to:
  /// **'Local data is ready ({message})'**
  String syncLocalDone(String message);

  /// No description provided for @widgetSection.
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget'**
  String get widgetSection;

  /// No description provided for @widgetSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows the nearest countdown or event on your Android home screen. Skin, icon and background image are up to you.'**
  String get widgetSectionSubtitle;

  /// No description provided for @widgetBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get widgetBackground;

  /// No description provided for @widgetSkinSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get widgetSkinSolid;

  /// No description provided for @widgetSkinGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get widgetSkinGradient;

  /// No description provided for @widgetSkinImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get widgetSkinImage;

  /// No description provided for @widgetBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Background image'**
  String get widgetBackgroundImage;

  /// No description provided for @widgetPickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick image'**
  String get widgetPickImage;

  /// No description provided for @widgetClearImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get widgetClearImage;

  /// No description provided for @widgetTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text colour'**
  String get widgetTextColor;

  /// No description provided for @widgetAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get widgetAccentColor;

  /// No description provided for @widgetIconStyle.
  ///
  /// In en, this message translates to:
  /// **'Icon style'**
  String get widgetIconStyle;

  /// No description provided for @widgetIconOutlined.
  ///
  /// In en, this message translates to:
  /// **'Outlined'**
  String get widgetIconOutlined;

  /// No description provided for @widgetIconFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get widgetIconFilled;

  /// No description provided for @widgetCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get widgetCornerRadius;

  /// No description provided for @widgetShowCountdown.
  ///
  /// In en, this message translates to:
  /// **'Show countdown'**
  String get widgetShowCountdown;

  /// No description provided for @widgetShowEvent.
  ///
  /// In en, this message translates to:
  /// **'Show next event'**
  String get widgetShowEvent;

  /// No description provided for @widgetTransparent.
  ///
  /// In en, this message translates to:
  /// **'Translucent background'**
  String get widgetTransparent;

  /// No description provided for @widgetRefreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh widget now'**
  String get widgetRefreshNow;

  /// No description provided for @widgetAutoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Automatic refresh'**
  String get widgetAutoRefresh;

  /// No description provided for @widgetAutoRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Redraws the widget in the background at the chosen frequency, without opening the app.'**
  String get widgetAutoRefreshHint;

  /// No description provided for @widgetRefreshFrequency.
  ///
  /// In en, this message translates to:
  /// **'Refresh frequency'**
  String get widgetRefreshFrequency;

  /// No description provided for @widgetRefreshEveryMinutes.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min'**
  String widgetRefreshEveryMinutes(int minutes);

  /// No description provided for @widgetRefreshEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} h'**
  String widgetRefreshEveryHours(int hours);

  /// No description provided for @widgetRefreshDaily.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get widgetRefreshDaily;

  /// No description provided for @widgetDailyRefreshTime.
  ///
  /// In en, this message translates to:
  /// **'Daily refresh time'**
  String get widgetDailyRefreshTime;

  /// No description provided for @widgetRefreshManual.
  ///
  /// In en, this message translates to:
  /// **'Automatic refresh is off'**
  String get widgetRefreshManual;

  /// No description provided for @widgetRefreshScheduled.
  ///
  /// In en, this message translates to:
  /// **'Next refresh: {time}'**
  String widgetRefreshScheduled(String time);

  /// No description provided for @widgetAddToHome.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get widgetAddToHome;

  /// No description provided for @widgetAddToHomeHint.
  ///
  /// In en, this message translates to:
  /// **'If the launcher supports it, confirm the system dialog to pin the widget.'**
  String get widgetAddToHomeHint;

  /// No description provided for @widgetRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Widget refreshed'**
  String get widgetRefreshed;

  /// No description provided for @widgetBackgroundService.
  ///
  /// In en, this message translates to:
  /// **'Keep running in background'**
  String get widgetBackgroundService;

  /// No description provided for @widgetBackgroundServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Android requires a silent, minimal notification for this. It keeps widget refreshes and reminders alive when the system would otherwise kill the process.'**
  String get widgetBackgroundServiceHint;

  /// No description provided for @widgetBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Ignore battery optimizations'**
  String get widgetBatteryOptimization;

  /// No description provided for @widgetBatteryOptimizationHint.
  ///
  /// In en, this message translates to:
  /// **'Lets the system stop killing Toki in the background. Opens a system dialog.'**
  String get widgetBatteryOptimizationHint;

  /// No description provided for @widgetBatteryOptimizationDone.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get widgetBatteryOptimizationDone;

  /// No description provided for @widgetNextEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Next event'**
  String get widgetNextEventTitle;

  /// No description provided for @widgetNextEvent.
  ///
  /// In en, this message translates to:
  /// **'Next: {name} · {time}'**
  String widgetNextEvent(String name, String time);

  /// No description provided for @widgetNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get widgetNoUpcoming;

  /// No description provided for @widgetUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String widgetUpdatedAt(Object time);

  /// No description provided for @widgetCountdownPast.
  ///
  /// In en, this message translates to:
  /// **'Already passed'**
  String get widgetCountdownPast;

  /// No description provided for @widgetRemainingDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d {hours} h left'**
  String widgetRemainingDays(int days, int hours);

  /// No description provided for @widgetRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min left'**
  String widgetRemainingHours(int hours, int minutes);

  /// No description provided for @widgetRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String widgetRemainingMinutes(int minutes);

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

  /// No description provided for @countdownFieldBackground.
  ///
  /// In en, this message translates to:
  /// **'Card background'**
  String get countdownFieldBackground;

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

  /// No description provided for @calendarFieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get calendarFieldRepeat;

  /// No description provided for @calendarRepeatNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get calendarRepeatNone;

  /// No description provided for @calendarRepeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get calendarRepeatDaily;

  /// No description provided for @calendarRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get calendarRepeatWeekly;

  /// No description provided for @calendarRepeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get calendarRepeatMonthly;

  /// No description provided for @calendarRepeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get calendarRepeatYearly;

  /// No description provided for @calendarRepeatForever.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get calendarRepeatForever;

  /// No description provided for @calendarRepeatUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String calendarRepeatUntil(String date);

  /// No description provided for @calendarReminderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom lead time'**
  String get calendarReminderCustom;

  /// No description provided for @calendarCategorySection.
  ///
  /// In en, this message translates to:
  /// **'Calendar categories'**
  String get calendarCategorySection;

  /// No description provided for @calendarCategoryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get calendarCategoryAdd;

  /// No description provided for @calendarCategoryEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get calendarCategoryEdit;

  /// No description provided for @calendarCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get calendarCategoryName;

  /// No description provided for @calendarCategoryColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get calendarCategoryColor;

  /// No description provided for @calendarCategoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get calendarCategoryEmpty;

  /// No description provided for @calendarCategorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get calendarCategorySaved;

  /// No description provided for @calendarCategoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get calendarCategoryDeleted;

  /// No description provided for @calendarCategoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get calendarCategoryDeleteTitle;

  /// No description provided for @calendarCategoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Events in \"{name}\" will become uncategorised. The events themselves are kept.'**
  String calendarCategoryDeleteBody(String name);

  /// No description provided for @calendarUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get calendarUnitMinutes;

  /// No description provided for @calendarUnitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get calendarUnitHours;

  /// No description provided for @calendarUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get calendarUnitDays;

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

  /// No description provided for @aiSessions.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get aiSessions;

  /// No description provided for @aiNewSession.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get aiNewSession;

  /// No description provided for @aiSessionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get aiSessionEmpty;

  /// No description provided for @aiDeleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get aiDeleteSession;

  /// No description provided for @aiDeleteSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat and all of its messages?'**
  String get aiDeleteSessionConfirm;

  /// No description provided for @aiMessageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiMessageCopy;

  /// No description provided for @aiMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aiMessageCopied;

  /// No description provided for @aiMessageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit and resend'**
  String get aiMessageEdit;

  /// No description provided for @aiMessageRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get aiMessageRegenerate;

  /// No description provided for @aiMessageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get aiMessageDelete;

  /// No description provided for @aiReasoningTitle.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get aiReasoningTitle;

  /// No description provided for @aiReasoningShow.
  ///
  /// In en, this message translates to:
  /// **'Thought for {count} characters · tap to view'**
  String aiReasoningShow(int count);

  /// No description provided for @aiReasoningHide.
  ///
  /// In en, this message translates to:
  /// **'Hide reasoning'**
  String get aiReasoningHide;

  /// No description provided for @aiThinkingHard.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiThinkingHard;

  /// No description provided for @aiEditMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get aiEditMessageTitle;

  /// No description provided for @aiSwitchProvider.
  ///
  /// In en, this message translates to:
  /// **'AI provider'**
  String get aiSwitchProvider;

  /// No description provided for @aiNoProviderShort.
  ///
  /// In en, this message translates to:
  /// **'No provider'**
  String get aiNoProviderShort;

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

  /// No description provided for @aiSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Choose model'**
  String get aiSelectModel;

  /// No description provided for @aiModelPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get aiModelPickerTitle;

  /// No description provided for @aiModelSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter models'**
  String get aiModelSearchHint;

  /// No description provided for @aiModelsLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count} models available'**
  String aiModelsLoaded(int count);

  /// No description provided for @aiNoModels.
  ///
  /// In en, this message translates to:
  /// **'The provider returned no models. Use manual input below.'**
  String get aiNoModels;

  /// No description provided for @aiFetchModelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch models'**
  String get aiFetchModelsFailed;

  /// No description provided for @aiRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get aiRetry;

  /// No description provided for @aiModelManual.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get aiModelManual;

  /// No description provided for @aiModelManualHint.
  ///
  /// In en, this message translates to:
  /// **'Type the model name if the provider has no model list.'**
  String get aiModelManualHint;

  /// No description provided for @aiModelSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected model: {model}'**
  String aiModelSelected(String model);

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

  /// No description provided for @avatarEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarEditorTitle;

  /// No description provided for @avatarKindEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get avatarKindEmoji;

  /// No description provided for @avatarKindText.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get avatarKindText;

  /// No description provided for @avatarKindImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get avatarKindImage;

  /// No description provided for @avatarPickEmoji.
  ///
  /// In en, this message translates to:
  /// **'Pick an emoji'**
  String get avatarPickEmoji;

  /// No description provided for @avatarEmojiHint.
  ///
  /// In en, this message translates to:
  /// **'Or type any emoji'**
  String get avatarEmojiHint;

  /// No description provided for @avatarTextHint.
  ///
  /// In en, this message translates to:
  /// **'One or two characters'**
  String get avatarTextHint;

  /// No description provided for @avatarPickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get avatarPickImage;

  /// No description provided for @avatarImageHint.
  ///
  /// In en, this message translates to:
  /// **'Image path or https URL'**
  String get avatarImageHint;

  /// No description provided for @avatarColor.
  ///
  /// In en, this message translates to:
  /// **'Background colour'**
  String get avatarColor;

  /// No description provided for @avatarClear.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get avatarClear;

  /// No description provided for @avatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get avatarChange;

  /// No description provided for @aiPersonaDefaultPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are the user\'s personal schedule assistant. Keep answers short and natural. Always use tools when changing the calendar, and never claim an action you did not perform.'**
  String get aiPersonaDefaultPrompt;

  /// No description provided for @aiPersonaCalendarAssistant.
  ///
  /// In en, this message translates to:
  /// **'Acting as a calendar assistant'**
  String get aiPersonaCalendarAssistant;

  /// No description provided for @aiPersonaCalendarAssistantHint.
  ///
  /// In en, this message translates to:
  /// **'On: today\'s events and countdowns are sent to the AI as context, and it may add, edit or delete them with tools. Off: pure chat / roleplay — no schedule data is sent, no tools are offered, and schedule talk stays conversation and reminders.'**
  String get aiPersonaCalendarAssistantHint;

  /// No description provided for @aiPersonaChatOnly.
  ///
  /// In en, this message translates to:
  /// **'Chat only'**
  String get aiPersonaChatOnly;

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

  /// No description provided for @chatBackgroundOverlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get chatBackgroundOverlay;

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

  /// No description provided for @themeEditorAreas.
  ///
  /// In en, this message translates to:
  /// **'Per-area colours'**
  String get themeEditorAreas;

  /// No description provided for @themeEditorAreasHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave any of them on \"Default\" to follow the theme colours above.'**
  String get themeEditorAreasHint;

  /// No description provided for @themeAreaNavBar.
  ///
  /// In en, this message translates to:
  /// **'Nav bar'**
  String get themeAreaNavBar;

  /// No description provided for @themeAreaSidebar.
  ///
  /// In en, this message translates to:
  /// **'Sidebar'**
  String get themeAreaSidebar;

  /// No description provided for @themeAreaEvent.
  ///
  /// In en, this message translates to:
  /// **'Calendar events'**
  String get themeAreaEvent;

  /// No description provided for @themeAreaCountdown.
  ///
  /// In en, this message translates to:
  /// **'Countdowns'**
  String get themeAreaCountdown;

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
