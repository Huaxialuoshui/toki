import 'dart:math' as math;

import '../entities/calendar_holiday.dart';

/// 本地节日规则。
///
/// * 公历节日直接按日期生成；
/// * 农历节日通过 1900–2100 年的农历数据换算；
/// * 二十四节气按太阳黄经的日期公式计算，清明同时属于公共节日和节气；
/// * 不依赖网络，也不把节日写进用户数据库。
class HolidayService {
  const HolidayService();

  /// 返回 `[start, end)` 内的节日，按日期排序。
  List<CalendarHoliday> occurrencesInRange(
    DateTime start,
    DateTime end,
  ) {
    if (!end.isAfter(start)) return const <CalendarHoliday>[];

    final firstYear = start.year - 1;
    final lastYear = end.year;
    final result = <CalendarHoliday>[
      for (var year = firstYear; year <= lastYear; year++)
        ...holidaysForYear(year),
    ];
    result.retainWhere(
      (CalendarHoliday holiday) =>
          !holiday.date.isBefore(start) && holiday.date.isBefore(end),
    );
    result.sort(
      (CalendarHoliday a, CalendarHoliday b) => a.date.compareTo(b.date),
    );
    return result;
  }

  List<CalendarHoliday> holidaysForYear(int year) {
    final result = <CalendarHoliday>[];

    void solar(
      int month,
      int day,
      String id,
      String nameZh,
      String nameEn,
      String shortZh,
      String shortEn,
      HolidayKind kind,
    ) {
      result.add(
        CalendarHoliday(
          id: id,
          date: DateTime(year, month, day),
          nameZh: nameZh,
          nameEn: nameEn,
          shortNameZh: shortZh,
          shortNameEn: shortEn,
          kind: kind,
        ),
      );
    }

    void lunar(
      int month,
      int day,
      String id,
      String nameZh,
      String nameEn,
      String shortZh,
      String shortEn,
      HolidayKind kind,
    ) {
      final date = _lunarToSolar(year, month, day);
      if (date == null) return;
      result.add(
        CalendarHoliday(
          id: id,
          date: date,
          nameZh: nameZh,
          nameEn: nameEn,
          shortNameZh: shortZh,
          shortNameEn: shortEn,
          kind: kind,
        ),
      );
    }

    solar(1, 1, 'new-year', '元旦', "New Year's Day", '元旦', 'New Year',
        HolidayKind.publicHoliday);
    solar(2, 14, 'valentines-day', '情人节', "Valentine's Day", '情人节', 'Valentine',
        HolidayKind.observance);
    solar(3, 8, 'womens-day', '妇女节', "Women's Day", '妇女节', 'Women',
        HolidayKind.observance);
    solar(3, 12, 'arbor-day', '植树节', 'Arbor Day', '植树节', 'Arbor',
        HolidayKind.observance);
    solar(5, 1, 'labour-day', '劳动节', 'Labour Day', '劳动节', 'Labour',
        HolidayKind.publicHoliday);
    solar(5, 4, 'youth-day', '青年节', 'Youth Day', '青年节', 'Youth',
        HolidayKind.observance);
    solar(6, 1, 'childrens-day', '儿童节', "Children's Day", '儿童节', 'Children',
        HolidayKind.observance);
    solar(9, 10, 'teachers-day', '教师节', "Teachers' Day", '教师节', 'Teachers',
        HolidayKind.observance);
    solar(10, 1, 'national-day', '国庆节', 'National Day', '国庆节', 'National Day',
        HolidayKind.publicHoliday);
    solar(12, 25, 'christmas', '圣诞节', 'Christmas', '圣诞节', 'Christmas',
        HolidayKind.observance);

    final qingming = DateTime(year, 4, _solarTermDay(year, 6));
    result.add(
      CalendarHoliday(
        id: 'qingming',
        date: qingming,
        nameZh: '清明节',
        nameEn: 'Qingming Festival',
        shortNameZh: '清明',
        shortNameEn: 'Qingming',
        kind: HolidayKind.publicHoliday,
        isSolarTerm: true,
      ),
    );

    for (var index = 0; index < _solarTerms.length; index++) {
      // 清明已经作为公共节日加入；保留一个条目，避免日历和通知重复。
      if (index == 6) continue;
      final term = _solarTerms[index];
      result.add(
        CalendarHoliday(
          id: term.id,
          date: DateTime(year, term.month, _solarTermDay(year, index)),
          nameZh: term.nameZh,
          nameEn: term.nameEn,
          shortNameZh: term.nameZh,
          shortNameEn: term.shortNameEn,
          kind: HolidayKind.solarTerm,
          isSolarTerm: true,
        ),
      );
    }

    lunar(1, 1, 'spring-festival', '春节', 'Spring Festival', '春节', 'Spring',
        HolidayKind.publicHoliday);
    lunar(1, 15, 'lantern-festival', '元宵节', 'Lantern Festival', '元宵', 'Lantern',
        HolidayKind.traditional);
    lunar(5, 5, 'dragon-boat', '端午节', 'Dragon Boat Festival', '端午',
        'Dragon Boat', HolidayKind.publicHoliday);
    lunar(7, 7, 'qixi', '七夕节', 'Qixi Festival', '七夕', 'Qixi',
        HolidayKind.traditional);
    lunar(8, 15, 'mid-autumn', '中秋节', 'Mid-Autumn Festival', '中秋', 'Mid-Autumn',
        HolidayKind.publicHoliday);
    lunar(9, 9, 'double-ninth', '重阳节', 'Double Ninth Festival', '重阳',
        'Double Ninth', HolidayKind.traditional);
    lunar(12, 8, 'laba', '腊八节', 'Laba Festival', '腊八', 'Laba',
        HolidayKind.traditional);

    final springFestival = _lunarToSolar(year, 1, 1);
    final lunarNewYearEve = springFestival?.subtract(const Duration(days: 1));
    if (lunarNewYearEve != null) {
      result.add(
        CalendarHoliday(
          id: 'lunar-new-years-eve',
          date: lunarNewYearEve,
          nameZh: '除夕',
          nameEn: "Lunar New Year's Eve",
          shortNameZh: '除夕',
          shortNameEn: 'New Year Eve',
          kind: HolidayKind.traditional,
        ),
      );
    }

    result.sort(
      (CalendarHoliday a, CalendarHoliday b) => a.date.compareTo(b.date),
    );
    return result;
  }

  /// 农历数据覆盖 1900-01-31（农历 1900 年正月初一）到 2100 年。
  static const List<int> _lunarInfo = <int>[
    0x04bd8,
    0x04ae0,
    0x0a570,
    0x054d5,
    0x0d260,
    0x0d950,
    0x16554,
    0x056a0,
    0x09ad0,
    0x055d2,
    0x04ae0,
    0x0a5b6,
    0x0a4d0,
    0x0d250,
    0x1d255,
    0x0b540,
    0x0d6a0,
    0x0ada2,
    0x095b0,
    0x14977,
    0x04970,
    0x0a4b0,
    0x0b4b5,
    0x06a50,
    0x06d40,
    0x1ab54,
    0x02b60,
    0x09570,
    0x052f2,
    0x04970,
    0x06566,
    0x0d4a0,
    0x0ea50,
    0x06e95,
    0x05ad0,
    0x02b60,
    0x186e3,
    0x092e0,
    0x1c8d7,
    0x0c950,
    0x0d4a0,
    0x1d8a6,
    0x0b550,
    0x056a0,
    0x1a5b4,
    0x025d0,
    0x092d0,
    0x0d2b2,
    0x0a950,
    0x0b557,
    0x06ca0,
    0x0b550,
    0x15355,
    0x04da0,
    0x0a5b0,
    0x14573,
    0x052b0,
    0x0a9a8,
    0x0e950,
    0x06aa0,
    0x0aea6,
    0x0ab50,
    0x04b60,
    0x0aae4,
    0x0a570,
    0x05260,
    0x0f263,
    0x0d950,
    0x05b57,
    0x056a0,
    0x096d0,
    0x04dd5,
    0x04ad0,
    0x0a4d0,
    0x0d4d4,
    0x0d250,
    0x0d558,
    0x0b540,
    0x0b6a0,
    0x195a6,
    0x095b0,
    0x049b0,
    0x0a974,
    0x0a4b0,
    0x0b27a,
    0x06a50,
    0x06d40,
    0x0af46,
    0x0ab60,
    0x09570,
    0x04af5,
    0x04970,
    0x064b0,
    0x074a3,
    0x0ea50,
    0x06b58,
    0x055c0,
    0x0ab60,
    0x096d5,
    0x092e0,
    0x0c960,
    0x0d954,
    0x0d4a0,
    0x0da50,
    0x07552,
    0x056a0,
    0x0abb7,
    0x025d0,
    0x092d0,
    0x0cab5,
    0x0a950,
    0x0b4a0,
    0x0baa4,
    0x0ad50,
    0x055d9,
    0x04ba0,
    0x0a5b0,
    0x15176,
    0x052b0,
    0x0a930,
    0x07954,
    0x06aa0,
    0x0ad50,
    0x05b52,
    0x04b60,
    0x0a6e6,
    0x0a4e0,
    0x0d260,
    0x0ea65,
    0x0d530,
    0x05aa0,
    0x076a3,
    0x096d0,
    0x04afb,
    0x04ad0,
    0x0a4d0,
    0x1d0b6,
    0x0d250,
    0x0d520,
    0x0dd45,
    0x0b5a0,
    0x056d0,
    0x055b2,
    0x049b0,
    0x0a577,
    0x0a4b0,
    0x0aa50,
    0x1b255,
    0x06d20,
    0x0ada0,
    0x14b63,
    0x09370,
    0x049f8,
    0x04970,
    0x064b0,
    0x168a6,
    0x0ea50,
    0x06b20,
    0x1a6c4,
    0x0aae0,
    0x0a2e0,
    0x0d2e3,
    0x0c960,
    0x0d557,
    0x0d4a0,
    0x0da50,
    0x05d55,
    0x056a0,
    0x0a6d0,
    0x055d4,
    0x052d0,
    0x0a9b8,
    0x0a950,
    0x0b4a0,
    0x0b6a6,
    0x0ad50,
    0x055a0,
    0x0aba4,
    0x0a5b0,
    0x052b0,
    0x0b273,
    0x06930,
    0x07337,
    0x06aa0,
    0x0ad50,
    0x14b55,
    0x04b60,
    0x0a570,
    0x054e4,
    0x0d160,
    0x0e968,
    0x0d520,
    0x0daa0,
    0x16aa6,
    0x056d0,
    0x04ae0,
    0x0a9d4,
    0x0a2d0,
    0x0d150,
    0x0f252,
    0x0d520,
  ];

  static final DateTime _lunarBase = DateTime(1900, 1, 31);

  static int _lunarYearDays(int year) {
    var sum = 348;
    final info = _lunarInfo[year - 1900];
    for (var mask = 0x8000; mask > 0x8; mask >>= 1) {
      if ((info & mask) != 0) sum++;
    }
    return sum + _leapDays(year);
  }

  static int _leapMonth(int year) => _lunarInfo[year - 1900] & 0xf;

  static int _leapDays(int year) {
    if (_leapMonth(year) == 0) return 0;
    return (_lunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29;
  }

  static int _lunarMonthDays(int year, int month) {
    if ((_lunarInfo[year - 1900] & (0x10000 >> month)) == 0) return 29;
    return 30;
  }

  static DateTime? _lunarToSolar(int year, int month, int day) {
    if (year < 1900 || year > 2100 || month < 1 || month > 12) return null;
    if (day < 1 || day > _lunarMonthDays(year, month)) return null;

    var offset = 0;
    for (var y = 1900; y < year; y++) {
      offset += _lunarYearDays(y);
    }
    final leap = _leapMonth(year);
    for (var m = 1; m < month; m++) {
      offset += _lunarMonthDays(year, m);
      if (leap > 0 && m == leap) offset += _leapDays(year);
    }
    return _lunarBase.add(Duration(days: offset + day - 1));
  }

  static const List<_SolarTerm> _solarTerms = <_SolarTerm>[
    _SolarTerm('solar-term-minor-cold', 1, '小寒', 'Minor Cold', 'Minor Cold'),
    _SolarTerm('solar-term-major-cold', 1, '大寒', 'Major Cold', 'Major Cold'),
    _SolarTerm(
      'solar-term-start-spring',
      2,
      '立春',
      'Start of Spring',
      'Spring',
    ),
    _SolarTerm('solar-term-rain-water', 2, '雨水', 'Rain Water', 'Rain'),
    _SolarTerm(
      'solar-term-awakening',
      3,
      '惊蛰',
      'Awakening of Insects',
      'Awakening',
    ),
    _SolarTerm(
      'solar-term-spring-equinox',
      3,
      '春分',
      'Spring Equinox',
      'Equinox',
    ),
    _SolarTerm('solar-term-qingming', 4, '清明', 'Qingming', 'Qingming'),
    _SolarTerm(
      'solar-term-grain-rain',
      4,
      '谷雨',
      'Grain Rain',
      'Grain Rain',
    ),
    _SolarTerm(
      'solar-term-start-summer',
      5,
      '立夏',
      'Start of Summer',
      'Summer',
    ),
    _SolarTerm('solar-term-grain-full', 5, '小满', 'Grain Full', 'Grain Full'),
    _SolarTerm(
      'solar-term-grain-ear',
      6,
      '芒种',
      'Grain in Ear',
      'Grain Ear',
    ),
    _SolarTerm(
      'solar-term-summer-solstice',
      6,
      '夏至',
      'Summer Solstice',
      'Solstice',
    ),
    _SolarTerm(
      'solar-term-minor-heat',
      7,
      '小暑',
      'Minor Heat',
      'Minor Heat',
    ),
    _SolarTerm(
      'solar-term-major-heat',
      7,
      '大暑',
      'Major Heat',
      'Major Heat',
    ),
    _SolarTerm(
      'solar-term-start-autumn',
      8,
      '立秋',
      'Start of Autumn',
      'Autumn',
    ),
    _SolarTerm(
      'solar-term-end-heat',
      8,
      '处暑',
      'End of Heat',
      'End Heat',
    ),
    _SolarTerm(
      'solar-term-white-dew',
      9,
      '白露',
      'White Dew',
      'White Dew',
    ),
    _SolarTerm(
      'solar-term-autumn-equinox',
      9,
      '秋分',
      'Autumn Equinox',
      'Equinox',
    ),
    _SolarTerm(
      'solar-term-cold-dew',
      10,
      '寒露',
      'Cold Dew',
      'Cold Dew',
    ),
    _SolarTerm(
      'solar-term-frost-descent',
      10,
      '霜降',
      "Frost's Descent",
      'Frost',
    ),
    _SolarTerm(
      'solar-term-start-winter',
      11,
      '立冬',
      'Start of Winter',
      'Winter',
    ),
    _SolarTerm(
      'solar-term-minor-snow',
      11,
      '小雪',
      'Minor Snow',
      'Minor Snow',
    ),
    _SolarTerm(
      'solar-term-major-snow',
      12,
      '大雪',
      'Major Snow',
      'Major Snow',
    ),
    _SolarTerm(
      'solar-term-winter-solstice',
      12,
      '冬至',
      'Winter Solstice',
      'Solstice',
    ),
  ];

  /// 24 节气的常用日期常数与少量历史修正。
  ///
  /// 公式基于公历世纪内的太阳黄经近似值，覆盖 1900–2100 年；修正表补上
  /// 少数因闰年累积造成的一天偏差。结果只保留自然日，不依赖设备时区。
  static const List<double> _solarTermConstants = <double>[
    5.4055,
    20.12,
    3.87,
    18.73,
    5.63,
    20.646,
    4.81,
    20.1,
    5.52,
    21.04,
    5.678,
    21.37,
    7.108,
    22.83,
    7.5,
    23.13,
    7.646,
    23.042,
    8.318,
    23.438,
    7.438,
    22.36,
    7.18,
    21.94,
  ];

  static const Map<int, Map<int, int>> _solarTermCorrections =
      <int, Map<int, int>>{
    0: <int, int>{1982: 1, 2019: 1},
    1: <int, int>{2000: -1, 2082: 1},
    2: <int, int>{2002: -1},
    3: <int, int>{2026: -1},
    4: <int, int>{2084: 1},
    5: <int, int>{2084: 1},
    6: <int, int>{2008: 1},
    8: <int, int>{1911: 1},
    9: <int, int>{2008: 1},
    10: <int, int>{1902: 1},
    11: <int, int>{1928: 1},
    12: <int, int>{1925: 1, 2016: 1},
    13: <int, int>{1922: 1},
    14: <int, int>{2002: 1},
    16: <int, int>{1927: 1},
    17: <int, int>{1942: 1},
    18: <int, int>{2089: 1},
    19: <int, int>{2089: 1},
    20: <int, int>{2089: 1},
    21: <int, int>{1978: 1},
    22: <int, int>{1954: 1},
    23: <int, int>{1918: -1, 2021: -1},
  };

  static int _solarTermDay(int year, int index) {
    final y = year % 100;
    var day = (y * 0.2422 + _solarTermConstants[index]).floor() - (y ~/ 4);
    day += _solarTermCorrections[index]?[year] ?? 0;
    return day;
  }
}

class _SolarTerm {
  const _SolarTerm(
    this.id,
    this.month,
    this.nameZh,
    this.nameEn,
    this.shortNameEn,
  );

  final String id;
  final int month;
  final String nameZh;
  final String nameEn;
  final String shortNameEn;
}

/// 暴露给测试和调用方的最小工具，避免重复写日期归一化。
DateTime holidayDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// 计算两个日期相差的自然日数（忽略时分秒）。
int holidayDaysBetween(DateTime from, DateTime to) {
  final start = holidayDateOnly(from);
  final end = holidayDateOnly(to);
  return math.max(0, end.difference(start).inDays);
}
