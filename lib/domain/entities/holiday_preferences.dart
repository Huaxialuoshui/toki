import 'package:flutter/foundation.dart';

@immutable
class HolidayPreferences {
  const HolidayPreferences({
    this.showInCalendar = true,
    this.remindersEnabled = true,
    this.reminderDaysAhead = 1,
  });

  final bool showInCalendar;
  final bool remindersEnabled;
  final int reminderDaysAhead;

  HolidayPreferences copyWith({
    bool? showInCalendar,
    bool? remindersEnabled,
    int? reminderDaysAhead,
  }) {
    return HolidayPreferences(
      showInCalendar: showInCalendar ?? this.showInCalendar,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderDaysAhead: reminderDaysAhead ?? this.reminderDaysAhead,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HolidayPreferences &&
        other.showInCalendar == showInCalendar &&
        other.remindersEnabled == remindersEnabled &&
        other.reminderDaysAhead == reminderDaysAhead;
  }

  @override
  int get hashCode =>
      Object.hash(showInCalendar, remindersEnabled, reminderDaysAhead);
}
