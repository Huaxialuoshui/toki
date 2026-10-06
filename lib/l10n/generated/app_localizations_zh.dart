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
  String get homePhaseBannerTitle => 'Phase 2 · 本地数据库';

  @override
  String get homePhaseBannerBody => '日程、倒计时与提醒现在都存在本机的 SQLite 数据库里；示例数据只会在 debug 构建写入。';

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
  String get countdownEmpty => '还没有倒计时';

  @override
  String get countdownNew => '新建倒计时';

  @override
  String get countdownEdit => '编辑倒计时';

  @override
  String get countdownFieldTarget => '目标时间';

  @override
  String get countdownFieldStyle => '显示样式';

  @override
  String get countdownStyleBigNumber => '大数字';

  @override
  String get countdownStyleFullText => '完整文本';

  @override
  String get countdownFieldPinned => '置顶';

  @override
  String get countdownDragHint => '拖动右侧手柄可以排序';

  @override
  String get countdownDragHintLongPress => '长按右侧手柄可以拖动排序';

  @override
  String get countdownDragHandle => '拖动排序';

  @override
  String get countdownDeleteConfirmTitle => '删除这个倒计时？';

  @override
  String get countdownSaved => '倒计时已保存';

  @override
  String get countdownDeleted => '倒计时已删除';

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
  String get calendarNewEvent => '新建日程';

  @override
  String get calendarEditEvent => '编辑日程';

  @override
  String get calendarSave => '保存';

  @override
  String get calendarCancel => '取消';

  @override
  String get calendarDelete => '删除';

  @override
  String get calendarEdit => '编辑';

  @override
  String get calendarDeleteConfirmTitle => '删除这个日程？';

  @override
  String get calendarDeleteConfirmBody => '删除后无法恢复。';

  @override
  String get calendarFieldTitle => '标题';

  @override
  String get calendarFieldTitleRequired => '请输入标题';

  @override
  String get calendarFieldDescription => '描述';

  @override
  String get calendarFieldLocation => '地点';

  @override
  String get calendarFieldCategory => '分类';

  @override
  String get calendarCategoryNone => '无分类';

  @override
  String get calendarFieldColor => '颜色';

  @override
  String get calendarColorDefault => '默认';

  @override
  String get calendarFieldReminder => '提醒';

  @override
  String get calendarReminderAtTime => '准时提醒';

  @override
  String calendarReminderHours(int hours) {
    return '提前 $hours 小时';
  }

  @override
  String calendarReminderDays(int days) {
    return '提前 $days 天';
  }

  @override
  String get calendarAllDayEvent => '全天';

  @override
  String get calendarFieldStart => '开始';

  @override
  String get calendarFieldEnd => '结束';

  @override
  String get calendarEndBeforeStart => '结束时间必须晚于开始时间';

  @override
  String get calendarEventSaved => '日程已保存';

  @override
  String get calendarEventDeleted => '日程已删除';

  @override
  String get calendarEventsThisWeek => '本周';

  @override
  String get calendarNoEventsThisWeek => '本周没有日程';

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
  String get aiNoProvider => '还没有配置 AI 服务商';

  @override
  String get aiNoProviderHint => '在设置里填上 Base URL 与模型就能开始聊天。';

  @override
  String get aiOpenSettings => '去设置';

  @override
  String get aiStop => '停止';

  @override
  String get aiThinking => '正在思考…';

  @override
  String aiEmptyConversation(String personaName) {
    return '和$personaName打个招呼吧';
  }

  @override
  String get aiClearConversation => '清空对话';

  @override
  String get aiClearConfirm => '清空这段对话？';

  @override
  String get aiStreamingHint => '正在回复…';

  @override
  String get aiProviderName => '名称';

  @override
  String get aiBaseUrl => 'Base URL';

  @override
  String get aiApiKey => 'API Key';

  @override
  String get aiModel => '模型';

  @override
  String get aiTemperature => '温度';

  @override
  String get aiMaxTokens => '最大 Token';

  @override
  String get aiStreamingEnabled => '流式输出';

  @override
  String get aiSetDefault => '设为默认';

  @override
  String get aiDefaultBadge => '默认';

  @override
  String get aiAddProvider => '添加服务商';

  @override
  String get aiEditProvider => '编辑服务商';

  @override
  String get aiNoProviders => '还没有服务商';

  @override
  String get aiPresets => '快速填充';

  @override
  String get aiTestConnection => '测试连接';

  @override
  String aiTestOk(String reply) {
    return '连接成功：$reply';
  }

  @override
  String get aiFieldRequired => '必填';

  @override
  String get aiInvalidUrl => 'URL 需要以 http:// 或 https:// 开头';

  @override
  String get aiShowKey => '显示';

  @override
  String get aiHideKey => '隐藏';

  @override
  String get aiKeyStoredLocally => '只保存在本机，不会写入日志。';

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
  String get settingsNotificationSectionSubtitle => 'Android 用系统本地通知，Windows 用系统 Toast';

  @override
  String get settingsNotificationPermission => '通知权限';

  @override
  String get settingsNotificationPermissionGranted => '已允许';

  @override
  String get settingsNotificationPermissionDenied => '未允许';

  @override
  String get settingsNotificationRequest => '请求权限';

  @override
  String get settingsNotificationExactAlarm => '允许精确提醒';

  @override
  String get settingsNotificationExactAlarmHint => '不开启时系统可能把提醒推迟几分钟。';

  @override
  String get settingsNotificationTest => '发送一条测试通知';

  @override
  String get settingsNotificationTestSent => '测试通知已排期（5 秒后）';

  @override
  String get notificationDefaultBody => 'Toki 日程提醒';

  @override
  String get notificationLeadNow => '现在开始';

  @override
  String notificationLeadMinutes(int minutes) {
    return '$minutes 分钟后开始';
  }

  @override
  String notificationLeadHours(int hours) {
    return '$hours 小时后开始';
  }

  @override
  String notificationLeadDays(int days) {
    return '$days 天后开始';
  }

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
  String get settingsPhaseNote => 'Phase 5 — 日历、倒计时与系统通知已可用；接下来接入 AI 助手。';

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
