/// 节日类型。用于在日历里做轻量区分，不参与日程的增删改。
enum HolidayKind {
  traditional,
  publicHoliday,
  observance,
  solarTerm,
}

/// 一个具体的节日日期。
///
/// 节日由本地规则生成，不写入数据库：同一年的同一天永远得到同一个 id，
/// 因此也可以安全地映射成稳定的系统通知 id。
class CalendarHoliday {
  const CalendarHoliday({
    required this.id,
    required this.date,
    required this.nameZh,
    required this.nameEn,
    required this.shortNameZh,
    required this.shortNameEn,
    required this.kind,
    this.isSolarTerm = false,
  });

  final String id;
  final DateTime date;
  final String nameZh;
  final String nameEn;
  final String shortNameZh;
  final String shortNameEn;
  final HolidayKind kind;
  final bool isSolarTerm;

  String name({required bool chinese}) => chinese ? nameZh : nameEn;

  String shortName({required bool chinese}) =>
      chinese ? shortNameZh : shortNameEn;
}
