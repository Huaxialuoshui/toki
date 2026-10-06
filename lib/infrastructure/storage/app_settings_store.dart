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
    return raw
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }

  Future<void> writeScheduledNotificationIds(List<int> ids) =>
      _preferences.setStringList(
        _scheduledNotificationIdsKey,
        ids.map((int id) => '$id').toList(growable: false),
      );

  Future<void> clearScheduledNotificationIds() =>
      _preferences.remove(_scheduledNotificationIdsKey);
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
