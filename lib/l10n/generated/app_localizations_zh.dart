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
  String homeWeatherDetail(String city, String min, String max) {
    return '$city · 最低 $min° / 最高 $max°';
  }

  @override
  String get weatherCity => '城市';

  @override
  String get weatherCityHint => '例如 上海 / Shanghai';

  @override
  String get weatherCitySaved => '城市已保存';

  @override
  String get weatherSection => '天气';

  @override
  String get weatherSectionSubtitle => '用 Open-Meteo，不需要 API Key。城市留空时首页还是占位卡。';

  @override
  String get weatherClear => '晴';

  @override
  String get weatherPartlyCloudy => '多云';

  @override
  String get weatherCloudy => '阴';

  @override
  String get weatherFog => '雾';

  @override
  String get weatherDrizzle => '小雨';

  @override
  String get weatherRain => '雨';

  @override
  String get weatherSnow => '雪';

  @override
  String get weatherThunder => '雷阵雨';

  @override
  String get weatherUnknown => '未知';

  @override
  String get weatherSave => '保存';

  @override
  String get weatherClearCity => '清除';

  @override
  String get weatherUseCurrentLocation => '使用当前位置';

  @override
  String get weatherLocationUsed => '已保存当前位置';

  @override
  String get weatherLocationFailed => '定位失败';

  @override
  String get weatherNoLocations => '还没有保存的位置，可以添加城市或用当前位置。';

  @override
  String get weatherDetailTitle => '天气';

  @override
  String get weatherHourly => '未来几小时';

  @override
  String get weatherDaily => '未来几天';

  @override
  String get weatherToday => '今天';

  @override
  String get weatherNoForecast => '暂无预报数据';

  @override
  String get appBackground => '应用背景';

  @override
  String get appBackgroundHint => '作用于所有页面；聊天页有自己独立的背景（见上面的区块）。';

  @override
  String get iconStyle => '图标风格';

  @override
  String get iconStyleOutlined => '描边';

  @override
  String get iconStyleFilled => '实心';

  @override
  String get appIcon => '应用图标';

  @override
  String get appIconHint => '用自己的图片做图标。Android：换掉「最近任务」里的图标，并生成一个带这张图的桌面快捷方式（系统会弹一次确认，点「添加」即可；桌面原图标由启动器绘制，改不了）。Windows：换掉窗口标题栏与任务栏图标，exe 自身的图标需要重新打包。';

  @override
  String get appIconPick => '选择图片';

  @override
  String get appIconApply => '应用到系统';

  @override
  String get appIconReset => '恢复默认';

  @override
  String get appIconApplied => '已换掉最近任务里的图标';

  @override
  String get appIconAppliedShortcut => '已应用；系统弹出确认框时点「添加」即可';

  @override
  String get appIconResetDone => '已恢复默认图标';

  @override
  String get appIconFailed => '设置应用图标失败';

  @override
  String get editImage => '用系统工具编辑';

  @override
  String get editImageDone => '图片已更新';

  @override
  String get editImageUnchanged => '图片没有改动';

  @override
  String get editImageFailed => '打开图片编辑器失败';

  @override
  String get aiAvatarMenu => '头像';

  @override
  String get aiAvatarMine => '我的头像';

  @override
  String get aiAvatarAssistant => '助手头像';

  @override
  String get aiAvatarSaved => '头像已更新';

  @override
  String get aiAvatarOnlyLocal => '只有本地图片才能用系统编辑器修改';

  @override
  String get digestSection => 'AI 每日简报';

  @override
  String get digestSectionSubtitle => '让助手写一份早间计划和晚间总结。默认关闭，每天最多生成一次。';

  @override
  String get digestMorningToggle => '早间计划';

  @override
  String get digestEveningToggle => '晚间总结';

  @override
  String get digestMorningTitle => '今日计划';

  @override
  String get digestEveningTitle => '今日总结';

  @override
  String get digestGenerate => '生成';

  @override
  String get digestRegenerate => '重新生成';

  @override
  String get digestGenerating => '助手正在写…';

  @override
  String get digestFailed => '生成失败';

  @override
  String get syncSection => '数据同步';

  @override
  String get syncLocalTitle => '仅本机';

  @override
  String get syncLocalSubtitle => '第一版是本地优先：数据都在本机数据库里。WebDAV / 自建服务器 / 云同步会复用同一个 SyncService 接口，属于后续阶段。';

  @override
  String get syncNow => '检查本地数据';

  @override
  String syncLocalDone(String message) {
    return '本地数据正常（$message）';
  }

  @override
  String get widgetSection => '桌面小组件';

  @override
  String get widgetSectionSubtitle => '在 Android 桌面显示最近的倒计时或日程；皮肤、图标、背景图片都可以自己定。';

  @override
  String get widgetBackground => '背景';

  @override
  String get widgetSkinSolid => '纯色';

  @override
  String get widgetSkinGradient => '渐变';

  @override
  String get widgetSkinImage => '图片';

  @override
  String get widgetBackgroundImage => '背景图片';

  @override
  String get widgetPickImage => '选择图片';

  @override
  String get widgetClearImage => '移除图片';

  @override
  String get widgetTextColor => '文字颜色';

  @override
  String get widgetAccentColor => '强调色';

  @override
  String get widgetIconStyle => '图标风格';

  @override
  String get widgetIconOutlined => '描边';

  @override
  String get widgetIconFilled => '实心';

  @override
  String get widgetCornerRadius => '圆角';

  @override
  String get widgetShowCountdown => '显示倒计时';

  @override
  String get widgetShowEvent => '显示下一个日程';

  @override
  String get widgetTransparent => '半透明背景';

  @override
  String get widgetRefreshNow => '立即刷新小组件';

  @override
  String get widgetAddToHome => '添加到桌面';

  @override
  String get widgetAddToHomeHint => '启动器支持的话，确认系统弹窗即可把小组件钉到桌面。';

  @override
  String get widgetRefreshed => '小组件已刷新';

  @override
  String get widgetBackgroundService => '常驻后台运行';

  @override
  String get widgetBackgroundServiceHint => 'Android 要求前台服务显示一条静音通知；它能让小组件刷新与提醒在系统回收进程时依然存活。';

  @override
  String get widgetBatteryOptimization => '加入电池优化白名单';

  @override
  String get widgetBatteryOptimizationHint => '让系统尽量不杀 Toki 的后台进程，会打开系统确认框。';

  @override
  String get widgetBatteryOptimizationDone => '已发起请求';

  @override
  String get widgetNextEventTitle => '下一个日程';

  @override
  String widgetNextEvent(String name, String time) {
    return '下一个：$name · $time';
  }

  @override
  String get widgetNoUpcoming => '暂时没有安排';

  @override
  String widgetUpdatedAt(Object time) {
    return '更新于 $time';
  }

  @override
  String get widgetCountdownPast => '已过期';

  @override
  String widgetRemainingDays(int days, int hours) {
    return '还有 $days 天 $hours 小时';
  }

  @override
  String widgetRemainingHours(int hours, int minutes) {
    return '还有 $hours 小时 $minutes 分';
  }

  @override
  String widgetRemainingMinutes(int minutes) {
    return '还有 $minutes 分钟';
  }

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
  String get countdownFieldBackground => '卡片背景';

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
  String get calendarFieldRepeat => '重复';

  @override
  String get calendarRepeatNone => '不重复';

  @override
  String get calendarRepeatDaily => '每天';

  @override
  String get calendarRepeatWeekly => '每周';

  @override
  String get calendarRepeatMonthly => '每月';

  @override
  String get calendarRepeatYearly => '每年';

  @override
  String get calendarRepeatForever => '不设结束日期';

  @override
  String calendarRepeatUntil(String date) {
    return '截止 $date';
  }

  @override
  String get calendarReminderCustom => '自定义提前量';

  @override
  String get calendarCategorySection => '日历分类';

  @override
  String get calendarCategoryAdd => '新建分类';

  @override
  String get calendarCategoryEdit => '编辑分类';

  @override
  String get calendarCategoryName => '名称';

  @override
  String get calendarCategoryColor => '颜色';

  @override
  String get calendarCategoryEmpty => '还没有分类';

  @override
  String get calendarCategorySaved => '分类已保存';

  @override
  String get calendarCategoryDeleted => '分类已删除';

  @override
  String get calendarCategoryDeleteTitle => '删除这个分类？';

  @override
  String calendarCategoryDeleteBody(String name) {
    return '「$name」下的事件会变成无分类，事件本身不会被删除。';
  }

  @override
  String get calendarUnitMinutes => '分钟';

  @override
  String get calendarUnitHours => '小时';

  @override
  String get calendarUnitDays => '天';

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
  String aiToolRunning(String tool) {
    return '正在$tool…';
  }

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
  String get aiSessions => '会话';

  @override
  String get aiNewSession => '新建会话';

  @override
  String get aiSessionEmpty => '还没有会话';

  @override
  String get aiDeleteSession => '删除会话';

  @override
  String get aiDeleteSessionConfirm => '删除这个会话以及它的全部消息？';

  @override
  String get aiMessageCopy => '复制';

  @override
  String get aiMessageCopied => '已复制';

  @override
  String get aiMessageEdit => '编辑并重发';

  @override
  String get aiMessageRegenerate => '重新生成';

  @override
  String get aiMessageDelete => '删除这条消息';

  @override
  String get aiReasoningTitle => '推理过程';

  @override
  String aiReasoningShow(int count) {
    return '已思考 $count 字 · 点击查看';
  }

  @override
  String get aiReasoningHide => '收起推理过程';

  @override
  String get aiThinkingHard => '正在思考…';

  @override
  String get aiEditMessageTitle => '编辑消息';

  @override
  String get aiSwitchProvider => 'AI 服务商';

  @override
  String get aiNoProviderShort => '未配置';

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
  String get aiSelectModel => '选择模型';

  @override
  String get aiModelPickerTitle => '选择模型';

  @override
  String get aiModelSearchHint => '筛选模型';

  @override
  String aiModelsLoaded(int count) {
    return '共 $count 个可用模型';
  }

  @override
  String get aiNoModels => '服务商没有返回模型，可在下面切到手动输入。';

  @override
  String get aiFetchModelsFailed => '获取模型失败';

  @override
  String get aiRetry => '重试';

  @override
  String get aiModelManual => '手动输入';

  @override
  String get aiModelManualHint => '服务商不提供模型列表时，可以手动输入模型名。';

  @override
  String aiModelSelected(String model) {
    return '已选择模型：$model';
  }

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
  String get aiPersonaSectionTitle => 'AI 人设';

  @override
  String get aiAddPersona => '添加人设';

  @override
  String get aiEditPersona => '编辑人设';

  @override
  String get aiNoPersonas => '还没有人设';

  @override
  String get aiPersonaName => '名称';

  @override
  String get aiPersonaIdentity => '身份';

  @override
  String get aiPersonaPersonality => '性格';

  @override
  String get aiPersonaSpeakingStyle => '说话方式';

  @override
  String get aiPersonaNickname => '对你的称呼';

  @override
  String get aiPersonaSystemPrompt => '系统提示词';

  @override
  String get aiPersonaAvatar => '头像';

  @override
  String get aiPersonaAvatarHint => '可以填 emoji、1 个字，或图片路径 / URL';

  @override
  String get avatarEditorTitle => '头像';

  @override
  String get avatarKindEmoji => '表情';

  @override
  String get avatarKindText => '文字';

  @override
  String get avatarKindImage => '图片';

  @override
  String get avatarPickEmoji => '挑一个表情';

  @override
  String get avatarEmojiHint => '也可以直接输入任意 emoji';

  @override
  String get avatarTextHint => '一到两个字';

  @override
  String get avatarPickImage => '从相册选择';

  @override
  String get avatarImageHint => '图片路径或 https 链接';

  @override
  String get avatarColor => '底色';

  @override
  String get avatarClear => '移除';

  @override
  String get avatarChange => '更换头像';

  @override
  String get aiPersonaDefaultPrompt => '你是用户的私人日程助手。回答自然简洁。修改日程时必须使用工具，不要虚构已经完成的操作。';

  @override
  String aiPersonaSwitched(String name) {
    return '已切换到 $name';
  }

  @override
  String get aiManagePersonas => '管理人设';

  @override
  String get aiPermissionSection => 'AI 权限';

  @override
  String get aiPermissionRead => '允许查询日程 / 倒计时';

  @override
  String get aiPermissionCreate => '允许创建日程 / 倒计时';

  @override
  String get aiPermissionUpdate => '允许修改已有内容';

  @override
  String get aiPermissionDelete => '允许删除（危险）';

  @override
  String get aiPermissionHint => '被拒绝的工具会如实告诉 AI；删除操作始终需要你确认。';

  @override
  String get aiToolConfirmTitle => '允许执行这个操作？';

  @override
  String aiToolConfirmBody(String tool) {
    return 'AI 想要$tool，参数如下：';
  }

  @override
  String get aiToolConfirmAllow => '允许';

  @override
  String get aiToolConfirmDeny => '拒绝';

  @override
  String get aiToolGetCurrentTime => '查询当前时间';

  @override
  String get aiToolGetTodayEvents => '查询今日日程';

  @override
  String get aiToolGetEvents => '查询日程';

  @override
  String get aiToolSearchEvents => '搜索日程';

  @override
  String get aiToolSummary => '统计日程';

  @override
  String get aiToolCreateEvent => '创建日程';

  @override
  String get aiToolUpdateEvent => '修改日程';

  @override
  String get aiToolDeleteEvent => '删除日程';

  @override
  String get aiToolGetCountdowns => '查询倒计时';

  @override
  String get aiToolCreateCountdown => '创建倒计时';

  @override
  String get aiToolUpdateCountdown => '修改倒计时';

  @override
  String get aiToolDeleteCountdown => '删除倒计时';

  @override
  String get aiToolCreateReminder => '创建提醒';

  @override
  String get aiToolUpdateReminder => '修改提醒';

  @override
  String get aiToolDeleteReminder => '删除提醒';

  @override
  String get chatAppearanceSection => '聊天外观';

  @override
  String get chatBackground => '聊天背景';

  @override
  String get chatBackgroundSolid => '纯色';

  @override
  String get chatBackgroundGradient => '渐变';

  @override
  String get chatBackgroundImage => '图片';

  @override
  String get chatBackgroundPickImage => '选择图片';

  @override
  String get chatBackgroundClearImage => '清除图片';

  @override
  String get chatBackgroundImageHint => '本地路径或图片 URL';

  @override
  String get chatBackgroundOpacity => '图片透明度';

  @override
  String get chatBackgroundBlur => '背景模糊';

  @override
  String get chatOverlayOpacity => '暗色遮罩';

  @override
  String get chatUserAvatar => '我的头像';

  @override
  String get chatUserAvatarHint => 'emoji、单个字，或图片路径';

  @override
  String get chatBubbleOpacity => '气泡透明度';

  @override
  String get chatBubbleRadius => '气泡圆角';

  @override
  String get chatFontScale => '聊天字号';

  @override
  String get chatAnimation => '消息动画';

  @override
  String get chatAppearanceReset => '恢复默认外观';

  @override
  String get chatAppearancePreview => '预览';

  @override
  String get chatPreviewMessage => '这是一条预览气泡';

  @override
  String get chatBackgroundColor => '颜色';

  @override
  String get chatGradientColors => '渐变颜色';

  @override
  String get chatBackgroundOverlay => '遮罩';

  @override
  String get themeEditorTitle => '主题编辑器';

  @override
  String get themeEditorColors => '颜色';

  @override
  String get themeColorPrimary => '主色';

  @override
  String get themeColorSecondary => '次要色';

  @override
  String get themeColorBackground => '背景';

  @override
  String get themeColorSurface => '卡片';

  @override
  String get themeColorText => '文字';

  @override
  String get themeEditorShape => '形状与效果';

  @override
  String get themeFieldCardOpacity => '卡片透明度';

  @override
  String get themeFieldBlur => '背景模糊';

  @override
  String get themeFieldShadow => '阴影强度';

  @override
  String get themeFieldAnimation => '过渡动画';

  @override
  String get themeBrightness => '明暗';

  @override
  String get themeBrightnessLight => '浅色';

  @override
  String get themeBrightnessDark => '深色';

  @override
  String get themeEditorPreview => '实时预览';

  @override
  String get themeEditorAreas => '区域配色（可选）';

  @override
  String get themeEditorAreasHint => '都可以留「默认」，跟随上面的主题色。';

  @override
  String get themeAreaNavBar => '导航栏';

  @override
  String get themeAreaSidebar => '侧边栏';

  @override
  String get themeAreaEvent => '日历事件';

  @override
  String get themeAreaCountdown => '倒计时';

  @override
  String get themeSave => '保存主题';

  @override
  String get themeSaveAs => '另存为新主题';

  @override
  String get themeSaveName => '主题名称';

  @override
  String get themeExport => '导出 JSON';

  @override
  String get themeImport => '导入 JSON';

  @override
  String get themeImportHint => '把主题 JSON 粘贴到这里';

  @override
  String themeImported(String name) {
    return '已导入主题：$name';
  }

  @override
  String themeExported(String path) {
    return '已导出到 $path（同时复制到剪贴板）';
  }

  @override
  String themeExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get themeImportFailed => '导入失败，请检查 JSON';

  @override
  String get themeSaved => '主题已保存';

  @override
  String get themeDeleted => '主题已删除';

  @override
  String themeDeleteConfirmBody(String name) {
    return '删除主题「$name」？删除后无法恢复。';
  }

  @override
  String get themeNew => '新建主题';

  @override
  String get themeEditCurrent => '编辑当前主题';

  @override
  String get themeMyThemes => '我的主题';

  @override
  String get themeBuiltIn => '内置主题';

  @override
  String get themePreviewCardTitle => '示例卡片';

  @override
  String get themePreviewCardBody => '卡片、按钮和文字大概就是这个样子。';

  @override
  String get themePreviewAction => '主要操作';

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
  String get backupIntro => '把全部数据导出成一个 JSON 文件：日程、倒计时、提醒、人设、服务商、聊天记录与主题。恢复时可选择覆盖或合并。';

  @override
  String get backupIncludeApiKeys => '导出时包含 API Key';

  @override
  String get backupIncludeApiKeysHint => '默认关闭。备份文件是明文，只有你确认能妥善保管时再打开。';

  @override
  String get backupExport => '导出备份';

  @override
  String backupExported(String path) {
    return '已导出到 $path（同时复制到剪贴板）';
  }

  @override
  String backupExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get backupRestoreFromFile => '从文件恢复';

  @override
  String get backupRestoreFromPaste => '粘贴 JSON';

  @override
  String get backupPasteHint => '把 Toki 备份 JSON 粘贴到这里';

  @override
  String get backupFileListTitle => '备份文件';

  @override
  String get backupNoFiles => '还没有备份文件';

  @override
  String get backupConfirmTitle => '恢复这份备份？';

  @override
  String backupConfirmBody(String time, int total, String apiKeys) {
    return '导出于 $time · 共 $total 条$apiKeys';
  }

  @override
  String get backupContainsApiKeys => ' · 含 API Key';

  @override
  String get backupModeReplace => '覆盖';

  @override
  String get backupModeReplaceHint => '先清空本机数据，再整体写入备份';

  @override
  String get backupModeMerge => '合并';

  @override
  String get backupModeMergeHint => '保留本机数据，同 id 覆盖、新 id 追加';

  @override
  String backupRestored(int count) {
    return '已恢复 $count 条数据';
  }

  @override
  String get backupRestoreFailed => '恢复失败';

  @override
  String get backupDirectory => '备份目录';

  @override
  String get backupErrorNotJson => '这不是合法的 JSON。';

  @override
  String get backupErrorNotBackup => '这不是 Toki 备份文件。';

  @override
  String get backupErrorFormatVersion => '这份备份来自更新版本的 Toki。';

  @override
  String get backupErrorSchemaVersion => '这份备份的数据库版本比当前应用新。';

  @override
  String get backupErrorMissingTables => '这份备份里没有数据段。';

  @override
  String get backupErrorCorrupted => '这份备份已损坏，无法恢复。';

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
  String get settingsPhaseNote => 'Phase 12 — 日历、倒计时、系统通知、AI 助手（含工具调用）、主题编辑器与备份恢复均已可用。';

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
