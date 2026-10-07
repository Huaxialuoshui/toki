import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// `context.l10n.navHome` 这样的简写，避免每处都写 `AppLocalizations.of(context)`。
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 当前生效的语言代码（`zh` / `en`），用于日期格式化。
  String get localeCode => Localizations.localeOf(this).languageCode;
}

/// 提醒文案（`无` / `准时` / `提前 N 分钟|小时|天`）。
extension ReminderLabelExtension on AppLocalizations {
  String reminderLabel(int? minutes) {
    if (minutes == null) return calendarNoReminder;
    if (minutes == 0) return calendarReminderAtTime;
    // 用"能整除才换算"而不是"大于就换算"：自定义 90 分钟要显示 90 分钟，
    // 而不是被截断成 1 小时。
    if (minutes % Duration.minutesPerDay == 0) {
      return calendarReminderDays(minutes ~/ Duration.minutesPerDay);
    }
    if (minutes % Duration.minutesPerHour == 0) {
      return calendarReminderHours(minutes ~/ Duration.minutesPerHour);
    }
    return calendarReminderMinutes(minutes);
  }
}
