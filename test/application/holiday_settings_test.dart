import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/calendar/holiday_providers.dart';
import 'package:toki/domain/entities/holiday_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  test('节日设置默认开启，并持久化显示、提醒与提前天数', () async {
    final container = await createTestContainer();

    expect(container.read(holidayPreferencesProvider).showInCalendar, isTrue);
    expect(
      container.read(holidayPreferencesProvider).remindersEnabled,
      isTrue,
    );
    expect(
      container.read(holidayPreferencesProvider).reminderDaysAhead,
      1,
    );

    final controller = container.read(holidayPreferencesProvider.notifier);
    await controller.setShowInCalendar(false);
    await controller.setRemindersEnabled(false);
    await controller.setReminderDaysAhead(3);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('settings.calendarHolidays'), isFalse);
    expect(preferences.getBool('settings.holidayReminders'), isFalse);
    expect(preferences.getInt('settings.holidayReminderDays'), 3);
    expect(
      container.read(holidayPreferencesProvider),
      const HolidayPreferences(
        showInCalendar: false,
        remindersEnabled: false,
        reminderDaysAhead: 3,
      ),
    );
  });
}
