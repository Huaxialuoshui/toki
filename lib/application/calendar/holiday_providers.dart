import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/holiday_preferences.dart';
import '../../domain/services/holiday_service.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../notification/reminder_scheduler.dart';

final holidayServiceProvider = Provider<HolidayService>(
  (ref) => const HolidayService(),
);

class HolidayPreferencesController extends Notifier<HolidayPreferences> {
  AppSettingsStore get _store => ref.read(appSettingsStoreProvider);

  @override
  HolidayPreferences build() {
    final store = ref.watch(appSettingsStoreProvider);
    return HolidayPreferences(
      showInCalendar: store.readCalendarHolidays(),
      remindersEnabled: store.readHolidayReminders(),
      reminderDaysAhead: store.readHolidayReminderDays().clamp(0, 7).toInt(),
    );
  }

  Future<void> setShowInCalendar(bool value) async {
    await _store.writeCalendarHolidays(value);
    state = state.copyWith(showInCalendar: value);
  }

  Future<void> setRemindersEnabled(bool value) async {
    await _store.writeHolidayReminders(value);
    state = state.copyWith(remindersEnabled: value);
  }

  Future<void> setReminderDaysAhead(int value) async {
    final normalized = value.clamp(0, 7).toInt();
    await _store.writeHolidayReminderDays(normalized);
    state = state.copyWith(reminderDaysAhead: normalized);
  }
}

final holidayPreferencesProvider =
    NotifierProvider<HolidayPreferencesController, HolidayPreferences>(
  HolidayPreferencesController.new,
);

/// 节日通知设置变化时立即重新排期。
final holidayReminderAutoSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(reminderSchedulerProvider);
  ref.listen<HolidayPreferences>(
    holidayPreferencesProvider,
    (HolidayPreferences? previous, HolidayPreferences next) {
      if (previous != next) {
        unawaited(scheduler.sync());
      }
    },
  );
});
