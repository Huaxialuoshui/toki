import 'package:intl/intl.dart';

/// 与语言相关的日期 / 时间格式化。
///
/// 统一放在这里，避免各页面各自写死 pattern。
abstract final class DateFormats {
  /// 例：`2026年10月6日 星期二` / `Tuesday, October 6, 2026`
  static String fullDate(DateTime date, String locale) => DateFormat(
        locale == 'zh' ? 'yyyy年M月d日 EEEE' : 'EEEE, MMMM d, yyyy',
        locale,
      ).format(date);

  /// 例：`2026年10月` / `October 2026`
  static String monthTitle(DateTime date, String locale) => DateFormat(
        locale == 'zh' ? 'yyyy年M月' : 'MMMM yyyy',
        locale,
      ).format(date);

  /// 例：`15:30` / `3:30 PM`
  static String time(DateTime dateTime, String locale) => DateFormat(
        locale == 'zh' ? 'HH:mm' : 'h:mm a',
        locale,
      ).format(dateTime);

  /// 例：`10月20日` / `Oct 20`
  static String shortDate(DateTime date, String locale) => DateFormat(
        locale == 'zh' ? 'M月d日' : 'MMM d',
        locale,
      ).format(date);

  /// 月视图星期表头（周一开始）。
  static List<String> weekdayHeaders(String locale) {
    final monday = DateTime(2024, 1, 1); // 2024-01-01 是星期一
    final format = DateFormat.E(locale);
    return List<String>.generate(
      7,
      (index) => format.format(monday.add(Duration(days: index))),
    );
  }
}
