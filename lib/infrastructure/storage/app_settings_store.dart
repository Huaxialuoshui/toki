import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用级轻量设置存储。
///
/// 边界（重要）：这里**只**放应用级轻量设置——语言、当前主题 id、是否跟随系统、
/// 字号 / 圆角微调、首次启动标记。
///
/// 领域数据（日程、倒计时、提醒、人设、会话）以及**用户自建 / 导入导出的主题**
/// 归数据库负责；Phase 2 建库时不会迁移这里的任何键，两类数据互不承担。
class AppSettingsStore {
  AppSettingsStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _localeKey = 'settings.locale';
  static const String _themeIdKey = 'settings.themeId';
  static const String _followSystemKey = 'settings.followSystem';
  static const String _fontScaleKey = 'settings.fontScale';
  static const String _borderRadiusKey = 'settings.borderRadius';
  static const String _firstLaunchSeenKey = 'settings.firstLaunchSeen';
  static const String _scheduledNotificationIdsKey =
      'settings.scheduledNotificationIds';
  static const String _aiAllowReadKey = 'settings.ai.allowRead';
  static const String _aiAllowCreateKey = 'settings.ai.allowCreate';
  static const String _aiAllowUpdateKey = 'settings.ai.allowUpdate';
  static const String _aiAllowDeleteKey = 'settings.ai.allowDelete';
  static const String _chatAppearanceKey = 'settings.chatAppearance';
  static const String _activeChatSessionKey = 'settings.chatSessionId';
  static const String _weatherCityKey = 'settings.weatherCity';
  static const String _weatherCacheKey = 'settings.weatherCache';
  static const String _weatherLocationsKey = 'settings.weatherLocations';
  static const String _widgetConfigKey = 'settings.widgetConfig';
  static const String _appBackgroundKey = 'settings.appBackground';
  static const String _iconStyleKey = 'settings.iconStyle';
  static const String _appIconKey = 'settings.appIcon';
  static const String _digestMorningKey = 'settings.digest.morning';
  static const String _digestEveningKey = 'settings.digest.evening';

  /// 语言代码；返回 null 表示"跟随系统"。
  String? readLocaleCode() => _preferences.getString(_localeKey);

  Future<void> writeLocaleCode(String? code) async {
    if (code == null) {
      await _preferences.remove(_localeKey);
    } else {
      await _preferences.setString(_localeKey, code);
    }
  }

  String? readThemeId() => _preferences.getString(_themeIdKey);

  Future<void> writeThemeId(String id) =>
      _preferences.setString(_themeIdKey, id);

  bool? readFollowSystem() => _preferences.getBool(_followSystemKey);

  Future<void> writeFollowSystem(bool value) =>
      _preferences.setBool(_followSystemKey, value);

  double? readFontScale() => _preferences.getDouble(_fontScaleKey);

  Future<void> writeFontScale(double? value) async {
    if (value == null) {
      await _preferences.remove(_fontScaleKey);
    } else {
      await _preferences.setDouble(_fontScaleKey, value);
    }
  }

  double? readBorderRadius() => _preferences.getDouble(_borderRadiusKey);

  Future<void> writeBorderRadius(double? value) async {
    if (value == null) {
      await _preferences.remove(_borderRadiusKey);
    } else {
      await _preferences.setDouble(_borderRadiusKey, value);
    }
  }

  bool readFirstLaunchSeen() =>
      _preferences.getBool(_firstLaunchSeenKey) ?? false;

  Future<void> markFirstLaunchSeen() =>
      _preferences.setBool(_firstLaunchSeenKey, true);

  /// 最近一次已排期的通知 id（用于取消已删除/已停用提醒留下的排期）。
  List<int> readScheduledNotificationIds() {
    final raw = _preferences.getStringList(_scheduledNotificationIdsKey);
    if (raw == null) return const <int>[];
    return raw.map(int.tryParse).whereType<int>().toList(growable: false);
  }

  Future<void> writeScheduledNotificationIds(List<int> ids) =>
      _preferences.setStringList(
        _scheduledNotificationIdsKey,
        ids.map((int id) => '$id').toList(growable: false),
      );

  Future<void> clearScheduledNotificationIds() =>
      _preferences.remove(_scheduledNotificationIdsKey);

  bool? readAiAllowRead() => _preferences.getBool(_aiAllowReadKey);
  Future<void> writeAiAllowRead(bool value) =>
      _preferences.setBool(_aiAllowReadKey, value);

  bool? readAiAllowCreate() => _preferences.getBool(_aiAllowCreateKey);
  Future<void> writeAiAllowCreate(bool value) =>
      _preferences.setBool(_aiAllowCreateKey, value);

  bool? readAiAllowUpdate() => _preferences.getBool(_aiAllowUpdateKey);
  Future<void> writeAiAllowUpdate(bool value) =>
      _preferences.setBool(_aiAllowUpdateKey, value);

  bool? readAiAllowDelete() => _preferences.getBool(_aiAllowDeleteKey);
  Future<void> writeAiAllowDelete(bool value) =>
      _preferences.setBool(_aiAllowDeleteKey, value);

  /// 聊天外观（背景 / 头像 / 气泡 / 字号 / 动画），JSON 字符串。
  String? readChatAppearance() => _preferences.getString(_chatAppearanceKey);

  Future<void> writeChatAppearance(String json) =>
      _preferences.setString(_chatAppearanceKey, json);

  /// 上次打开的会话 id（多会话；找不到就回落到最近的会话）。
  String? readActiveChatSessionId() =>
      _preferences.getString(_activeChatSessionKey);

  Future<void> writeActiveChatSessionId(String id) =>
      _preferences.setString(_activeChatSessionKey, id);

  /// 天气城市（为空表示不显示天气，首页保留占位）。
  String? readWeatherCity() => _preferences.getString(_weatherCityKey);

  Future<void> writeWeatherCity(String? city) async {
    if (city == null || city.trim().isEmpty) {
      await _preferences.remove(_weatherCityKey);
    } else {
      await _preferences.setString(_weatherCityKey, city.trim());
    }
  }

  /// 天气缓存（JSON 字符串），避免每次打开首页都打网络。
  String? readWeatherCache() => _preferences.getString(_weatherCacheKey);

  Future<void> writeWeatherCache(String? json) async {
    if (json == null) {
      await _preferences.remove(_weatherCacheKey);
    } else {
      await _preferences.setString(_weatherCacheKey, json);
    }
  }

  /// 天气历史位置（JSON 数组字符串）。
  String? readWeatherLocations() =>
      _preferences.getString(_weatherLocationsKey);

  Future<void> writeWeatherLocations(String json) =>
      _preferences.setString(_weatherLocationsKey, json);

  /// 桌面小组件外观配置（JSON 字符串）。
  String? readWidgetConfig() => _preferences.getString(_widgetConfigKey);

  Future<void> writeWidgetConfig(String json) =>
      _preferences.setString(_widgetConfigKey, json);

  /// 应用级背景（JSON），复用聊天背景的配置结构。
  String? readAppBackground() => _preferences.getString(_appBackgroundKey);

  Future<void> writeAppBackground(String json) =>
      _preferences.setString(_appBackgroundKey, json);

  /// 图标风格：`outlined` / `filled`。
  String? readIconStyle() => _preferences.getString(_iconStyleKey);

  Future<void> writeIconStyle(String value) =>
      _preferences.setString(_iconStyleKey, value);

  /// 自定义应用图标的图片路径（本机文件；空表示用默认图标）。
  String? readAppIcon() => _preferences.getString(_appIconKey);

  Future<void> writeAppIcon(String? path) => path == null
      ? _preferences.remove(_appIconKey)
      : _preferences.setString(_appIconKey, path);

  /// AI 每日计划 / 每日总结开关（规格 §14），默认都关闭。
  bool readMorningDigestEnabled() =>
      _preferences.getBool(_digestMorningKey) ?? false;

  Future<void> writeMorningDigestEnabled(bool value) =>
      _preferences.setBool(_digestMorningKey, value);

  bool readEveningDigestEnabled() =>
      _preferences.getBool(_digestEveningKey) ?? false;

  Future<void> writeEveningDigestEnabled(bool value) =>
      _preferences.setBool(_digestEveningKey, value);
}

/// 必须在 `main()` 中 override（见 `lib/main.dart`）。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider 必须在 ProviderScope 中被 override。',
  ),
);

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => AppSettingsStore(ref.watch(sharedPreferencesProvider)),
);
