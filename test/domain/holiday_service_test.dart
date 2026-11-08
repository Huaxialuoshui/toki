import 'package:flutter_test/flutter_test.dart';
import 'package:toki/domain/services/holiday_service.dart';

void main() {
  const service = HolidayService();

  test('2026 年农历与清明节日日期正确', () {
    final holidays = service.holidaysForYear(2026);
    DateTime dateOf(String id) =>
        holidays.firstWhere((holiday) => holiday.id == id).date;

    expect(dateOf('lunar-new-years-eve'), DateTime(2026, 2, 16));
    expect(dateOf('spring-festival'), DateTime(2026, 2, 17));
    expect(dateOf('lantern-festival'), DateTime(2026, 3, 3));
    expect(dateOf('qingming'), DateTime(2026, 4, 5));
    expect(dateOf('dragon-boat'), DateTime(2026, 6, 19));
    expect(dateOf('qixi'), DateTime(2026, 8, 19));
    expect(dateOf('mid-autumn'), DateTime(2026, 9, 25));
    expect(dateOf('double-ninth'), DateTime(2026, 10, 18));
  });

  test('2026 年包含完整且不重复的二十四节气', () {
    final terms = service
        .holidaysForYear(2026)
        .where((holiday) => holiday.isSolarTerm)
        .toList(growable: false);
    final dates = terms.map((holiday) => holiday.date).toSet();

    expect(terms, hasLength(24));
    expect(dates, hasLength(24));
    expect(
      terms.firstWhere((holiday) => holiday.id == 'solar-term-rain-water').date,
      DateTime(2026, 2, 18),
    );
    expect(
      terms
          .firstWhere(
            (holiday) => holiday.id == 'solar-term-winter-solstice',
          )
          .date,
      DateTime(2026, 12, 22),
    );
    expect(
      terms.where((holiday) => holiday.shortNameZh == '清明'),
      hasLength(1),
    );
  });

  test('2027 年春节与中秋日期正确', () {
    final holidays = service.holidaysForYear(2027);
    DateTime dateOf(String id) =>
        holidays.firstWhere((holiday) => holiday.id == id).date;

    expect(dateOf('spring-festival'), DateTime(2027, 2, 6));
    expect(dateOf('dragon-boat'), DateTime(2027, 6, 9));
    expect(dateOf('mid-autumn'), DateTime(2027, 9, 15));
  });

  test('范围查询包含起点、不包含终点，并按日期排序', () {
    final holidays = service.occurrencesInRange(
      DateTime(2026, 2, 16),
      DateTime(2026, 3, 4),
    );

    expect(
      holidays.map((holiday) => holiday.id),
      <String>[
        'lunar-new-years-eve',
        'spring-festival',
        'solar-term-rain-water',
        'lantern-festival',
      ],
    );
    expect(
        service.occurrencesInRange(DateTime(2026, 1, 1), DateTime(2026, 1, 1)),
        isEmpty);
  });
}
