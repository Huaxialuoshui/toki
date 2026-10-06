import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Toki';

  @override
  String get appTagline => '本地优先的 AI 日历与提醒';

  @override
  String get navHome => '首页';

  @override
  String get navCalendar => '日历';

  @override
  String get navCountdown => '倒计时';

  @override
  String get navAi => 'AI 助手';

  @override
  String get navSettings => '设置';

  @override
  String get commonComingSoon => '后续阶段提供';

  @override
  String get commonViewAll => '查看全部';

  @override
  String get homeGreeting => '欢迎回来';

  @override
  String get homeWeatherPlaceholder => '天气';

  @override
  String get homeWeatherHint => '天气接入将在后续阶段提供';

  @override
  String get homeTodayEvents => '今日事项';

  @override
  String get homeNoEvents => '今天没有安排';

  @override
  String get homeCountdowns => '倒计时';

  @override
  String get homeUpcoming => '未来事件';

  @override
  String homeAskAi(String personaName) {
    return '问问$personaName';
  }

  @override
  String get homeAskAiHint => '聊天、查询日程、创建提醒';

  @override
  String get homeOpenAi => '打开助手';

  @override
  String get homePhaseBannerTitle => 'Phase 1 骨架';

  @override
  String get homePhaseBannerBody => '布局、主题与中英双语已就绪。下面的数据都是 mock，Phase 2 接入数据库后替换。';

  @override
  String get homePhaseBannerDismiss => '知道了';

  @override
  String countdownTimeUntil(String title) {
    return '距离「$title」还有';
  }

  @override
  String countdownTimeSince(String title) {
    return '「$title」已经过去';
  }

  @override
  String countdownTargetAt(String time) {
    return '目标时间 $time';
  }

  @override
  String get countdownPinned => '已置顶';

  @override
  String get countdownReadOnlyHint => '倒计时的创建、编辑与拖动排序将在 Phase 4 提供';

  @override
  String get unitDay => '天';

  @override
  String get unitHour => '小时';

  @override
  String get unitMinute => '分钟';

  @override
  String get unitSecond => '秒';

  @override
  String get unitDayFull => '天';

  @override
  String get unitHourFull => '小时';

  @override
  String get unitMinuteFull => '分钟';

  @override
  String get unitSecondFull => '秒';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarMonthView => '月';

  @override
  String get calendarWeekView => '周';

  @override
  String get calendarDayView => '日';

  @override
  String get calendarWeekDayComingSoon => '周视图与日视图将在 Phase 3 提供';

  @override
  String calendarEventsOn(String date) {
    return '$date 的日程';
  }

  @override
  String get calendarNoEvents => '这一天没有日程';

  @override
  String get calendarAllDay => '全天';

  @override
  String get calendarReadOnlyHint => '本阶段只读，创建与编辑日程在 Phase 3 提供';

  @override
  String get calendarEventDetail => '日程详情';

  @override
  String get calendarClose => '关闭';

  @override
  String get calendarLocation => '地点';

  @override
  String get calendarReminder => '提醒';

  @override
  String calendarReminderMinutes(int minutes) {
    return '提前 $minutes 分钟';
  }

  @override
  String get calendarNoReminder => '无';

  @override
  String get aiPersona => '人设';

  @override
  String get aiPersonaSwitchSoon => '切换人设将在 Phase 7 提供';

  @override
  String aiComposerHint(String personaName) {
    return '给$personaName发消息…';
  }

  @override
  String get aiSend => '发送';

  @override
  String get aiMockNotice => '这是 mock 会话，本阶段尚未接入 AI Provider';

  @override
  String get aiToolCallLabel => '工具调用';

  @override
  String get aiToolRunning => '正在查询日程…';

  @override
  String get aiToolDone => '已完成';

  @override
  String get aiMockUser => '我下周有什么安排？';

  @override
  String get aiMockToolSummary => '已查询到 4 条日程';

  @override
  String get aiMockAssistant => '下周你有 4 条安排。周三 15:00 的毕业答辩最需要提前准备。';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeFollowSystem => '跟随系统';

  @override
  String get settingsThemeDefault => '默认';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsFontScale => '字体大小';

  @override
  String get settingsCornerRadius => '圆角';

  @override
  String get settingsReset => '重置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageFollowSystem => '跟随系统';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsAiSection => 'AI 与服务商';

  @override
  String get settingsAiSectionSubtitle => '服务商、人设与工具权限设置（Phase 6-8）';

  @override
  String get settingsNotificationSection => '通知提醒';

  @override
  String get settingsNotificationSectionSubtitle => '本地通知与系统提醒（Phase 5）';

  @override
  String get settingsBackupSection => '备份与恢复';

  @override
  String get settingsBackupSectionSubtitle => '带版本控制的 JSON 导入导出（Phase 12）';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsVersion => '应用版本';

  @override
  String get settingsFlutterVersion => 'Flutter';

  @override
  String get settingsDartVersion => 'Dart';

  @override
  String get settingsProjectPath => '项目路径';

  @override
  String get settingsPhaseNote => 'Phase 1 — 环境、App Shell、响应式布局、主题与中英双语。';

  @override
  String get mockEventDefense => '毕业设计答辩';

  @override
  String get mockEventProjectDeadline => '课程项目截止';

  @override
  String get mockEventLabMeeting => '课题组例会';

  @override
  String get mockEventMorningPlan => '晨间计划';

  @override
  String get mockEventHealthCheck => '体检预约';

  @override
  String get mockEventBirthday => '生日';

  @override
  String get mockLocationLab => '教学楼 A-302';

  @override
  String get mockLocationOnline => '线上';

  @override
  String get mockPersonaName => '小雪';

  @override
  String get mockPersonaDescription => '私人日程助手';

  @override
  String get mockPersonaPersonality => '温柔、活泼，偶尔提醒主人不要拖延';

  @override
  String get mockPersonaSpeakingStyle => '简短、自然，不要过度正式';

  @override
  String get mockPersonaNickname => '主人';
}
