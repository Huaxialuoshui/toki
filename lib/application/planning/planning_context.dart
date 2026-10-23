import 'package:flutter/foundation.dart';

import '../../core/clock.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/entities/daily_digest.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/planning_preferences.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/countdown_repository.dart';
import '../../domain/repositories/daily_digest_repository.dart';
import '../../domain/repositories/planning_preferences_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/recurrence.dart';

@immutable
class PlanningRequest {
  const PlanningRequest({
    required this.day,
    this.goalText,
    this.mustDoTaskIds = const <String>[],
    this.availableWindows = const <PlanningWindow>[],
    this.blockedWindows = const <PlanningWindow>[],
    this.energy,
    this.notes,
    this.weatherSummary,
  });

  final DateTime day;
  final String? goalText;
  final List<String> mustDoTaskIds;
  final List<PlanningWindow> availableWindows;
  final List<PlanningWindow> blockedWindows;
  final String? energy;
  final String? notes;
  final String? weatherSummary;

  PlanningRequest copyWith({
    DateTime? day,
    String? goalText,
    List<String>? mustDoTaskIds,
    List<PlanningWindow>? availableWindows,
    List<PlanningWindow>? blockedWindows,
    String? energy,
    String? notes,
    String? weatherSummary,
  }) {
    return PlanningRequest(
      day: day ?? this.day,
      goalText: goalText ?? this.goalText,
      mustDoTaskIds: mustDoTaskIds ?? this.mustDoTaskIds,
      availableWindows: availableWindows ?? this.availableWindows,
      blockedWindows: blockedWindows ?? this.blockedWindows,
      energy: energy ?? this.energy,
      notes: notes ?? this.notes,
      weatherSummary: weatherSummary ?? this.weatherSummary,
    );
  }

  PlanningConstraints toConstraints() => PlanningConstraints(
        goalText: goalText,
        mustDoTaskIds: List<String>.unmodifiable(mustDoTaskIds),
        availableWindows: List<PlanningWindow>.unmodifiable(availableWindows),
        blockedWindows: List<PlanningWindow>.unmodifiable(blockedWindows),
        energy: energy,
        notes: notes,
      );
}

@immutable
class PlanningInterval {
  const PlanningInterval({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get minutes => end.difference(start).inMinutes;
}

@immutable
class PlanningContext {
  const PlanningContext({
    required this.request,
    required this.now,
    required this.dayStart,
    required this.dayEnd,
    required this.dayKey,
    required this.fixedOccurrences,
    required this.allDayOccurrences,
    required this.fixedIntervals,
    required this.candidateTasks,
    required this.tasksById,
    required this.scheduledTaskIds,
    required this.countdowns,
    required this.preferences,
    required this.availableWindows,
    required this.blockedWindows,
    required this.capacityMinutes,
    required this.priorReview,
    required this.weatherSummary,
    required this.prompt,
  });

  final PlanningRequest request;
  final DateTime now;
  final DateTime dayStart;
  final DateTime dayEnd;
  final String dayKey;
  final List<EventOccurrence> fixedOccurrences;
  final List<EventOccurrence> allDayOccurrences;
  final List<PlanningInterval> fixedIntervals;
  final List<TaskItem> candidateTasks;
  final Map<String, TaskItem> tasksById;
  final Set<String> scheduledTaskIds;
  final List<CountdownItem> countdowns;
  final PlanningPreferences preferences;
  final List<PlanningInterval> availableWindows;
  final List<PlanningInterval> blockedWindows;
  final int capacityMinutes;
  final String? priorReview;
  final String? weatherSummary;
  final String prompt;
}

class PlanningContextBuilder {
  PlanningContextBuilder({
    required CalendarRepository events,
    required TaskRepository tasks,
    required CountdownRepository countdowns,
    required DailyDigestRepository digests,
    required PlanningPreferencesRepository preferences,
    required Clock clock,
    this.maxEvents = 30,
    this.maxTasks = 40,
    this.maxCountdowns = 8,
    this.maxChars = 6000,
  })  : _events = events,
        _tasks = tasks,
        _countdowns = countdowns,
        _digests = digests,
        _preferences = preferences,
        _clock = clock;

  final CalendarRepository _events;
  final TaskRepository _tasks;
  final CountdownRepository _countdowns;
  final DailyDigestRepository _digests;
  final PlanningPreferencesRepository _preferences;
  final Clock _clock;
  final int maxEvents;
  final int maxTasks;
  final int maxCountdowns;
  final int maxChars;

  Future<PlanningContext> build(PlanningRequest request) async {
    final now = _clock.now();
    final dayStart =
        DateTime(request.day.year, request.day.month, request.day.day);
    final dayEnd = DateTime(
      request.day.year,
      request.day.month,
      request.day.day + 1,
    );
    final dayKey = _dayKey(dayStart);
    final preferences = await _preferences.load();

    final allEvents = await _events.getAll();
    final occurrences = <EventOccurrence>[];
    for (final event in allEvents) {
      if (event.isCancelled || event.status == EventStatus.completed) continue;
      occurrences.addAll(expandOccurrences(event, dayStart, dayEnd));
    }
    occurrences.sort(
      (EventOccurrence a, EventOccurrence b) => a.start.compareTo(b.start),
    );
    final shownOccurrences =
        occurrences.take(maxEvents).toList(growable: false);
    final fixedOccurrences = shownOccurrences
        .where((EventOccurrence occurrence) => !occurrence.event.allDay)
        .toList(growable: false);
    final allDayOccurrences = shownOccurrences
        .where((EventOccurrence occurrence) => occurrence.event.allDay)
        .toList(growable: false);

    final fixedIntervals = fixedOccurrences
        .map(
          (EventOccurrence occurrence) => _clip(
            PlanningInterval(start: occurrence.start, end: occurrence.end),
            dayStart,
            dayEnd,
          ),
        )
        .whereType<PlanningInterval>()
        .toList(growable: false);

    final scheduledTaskIds = <String>{
      for (final occurrence in occurrences)
        if (occurrence.event.taskId != null && occurrence.end.isAfter(now))
          occurrence.event.taskId!,
    };

    final activeTasks = await _tasks.getActive();
    final mustDo = request.mustDoTaskIds.toSet();
    final orderedTasks = <TaskItem>[
      for (final task in activeTasks)
        if (mustDo.contains(task.id)) task,
      for (final task in activeTasks)
        if (!mustDo.contains(task.id) && !scheduledTaskIds.contains(task.id))
          task,
    ];
    final candidateTasks = orderedTasks.take(maxTasks).toList(growable: false);
    final tasksById = <String, TaskItem>{
      for (final task in candidateTasks) task.id: task,
    };

    final countdownItems = (await _countdowns.getAll())
        .where(
          (CountdownItem item) =>
              item.isPinned ||
              (item.targetTime.isAfter(now) &&
                  item.targetTime.isBefore(
                    dayEnd.add(const Duration(days: 13)),
                  )),
        )
        .toList()
      ..sort((CountdownItem a, CountdownItem b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.targetTime.compareTo(b.targetTime);
      });
    final relevantCountdowns =
        countdownItems.take(maxCountdowns).toList(growable: false);

    final previousDay = dayStart.subtract(const Duration(days: 1));
    final previousDigest = await _digests.find(
      _dayKey(previousDay),
      DailyDigestKind.evening,
    );
    final priorReview = _truncate(previousDigest?.content, 600);

    final requestedAvailable = _merge(
      request.availableWindows
          .map((PlanningWindow window) => PlanningInterval(
                start: window.start,
                end: window.end,
              ))
          .toList(),
    )
        .map((PlanningInterval i) => _clip(i, dayStart, dayEnd))
        .whereType<PlanningInterval>()
        .toList();
    final defaults = requestedAvailable.isNotEmpty
        ? requestedAvailable
        : _defaultWindows(dayStart, preferences);
    final blockers = <PlanningInterval>[
      ...fixedIntervals,
      ...request.blockedWindows.map(
        (PlanningWindow window) => PlanningInterval(
          start: window.start,
          end: window.end,
        ),
      ),
    ];
    final availableWindows = _subtract(
      _merge(defaults),
      _merge(blockers),
    );
    final capacityMinutes =
        availableWindows.fold<int>(0, (int sum, PlanningInterval i) {
      return sum + (i.minutes < 0 ? 0 : i.minutes);
    });

    final prompt = _buildPrompt(
      now: now,
      dayKey: dayKey,
      request: request,
      fixedOccurrences: fixedOccurrences,
      allDayOccurrences: allDayOccurrences,
      availableWindows: availableWindows,
      tasks: candidateTasks,
      scheduledTaskIds: scheduledTaskIds,
      countdowns: relevantCountdowns,
      preferences: preferences,
      priorReview: priorReview,
      capacityMinutes: capacityMinutes,
    );

    return PlanningContext(
      request: request,
      now: now,
      dayStart: dayStart,
      dayEnd: dayEnd,
      dayKey: dayKey,
      fixedOccurrences: fixedOccurrences,
      allDayOccurrences: allDayOccurrences,
      fixedIntervals: fixedIntervals,
      candidateTasks: candidateTasks,
      tasksById: tasksById,
      scheduledTaskIds: scheduledTaskIds,
      countdowns: relevantCountdowns,
      preferences: preferences,
      availableWindows: availableWindows,
      blockedWindows: blockers,
      capacityMinutes: capacityMinutes,
      priorReview: priorReview,
      weatherSummary: request.weatherSummary,
      prompt: prompt.length <= maxChars
          ? prompt
          : '${prompt.substring(0, maxChars)}\n…（上下文过长，已截断）',
    );
  }

  List<PlanningInterval> _defaultWindows(
    DateTime day,
    PlanningPreferences preferences,
  ) {
    final weekday = day.weekday <= DateTime.friday;
    if (preferences.weekdaysOnly && !weekday) {
      return const <PlanningInterval>[];
    }
    DateTime at(int minute) => DateTime(
          day.year,
          day.month,
          day.day,
        ).add(Duration(minutes: minute));
    return <PlanningInterval>[
      PlanningInterval(
        start: at(preferences.workdayStartMinute),
        end: at(preferences.lunchStartMinute),
      ),
      PlanningInterval(
        start: at(preferences.lunchEndMinute),
        end: at(preferences.workdayEndMinute),
      ),
    ];
  }

  String _buildPrompt({
    required DateTime now,
    required String dayKey,
    required PlanningRequest request,
    required List<EventOccurrence> fixedOccurrences,
    required List<EventOccurrence> allDayOccurrences,
    required List<PlanningInterval> availableWindows,
    required List<TaskItem> tasks,
    required Set<String> scheduledTaskIds,
    required List<CountdownItem> countdowns,
    required PlanningPreferences preferences,
    required String? priorReview,
    required int capacityMinutes,
  }) {
    final lines = <String>[
      '当前时间：${_dateTime(now)}（本地时区 ${now.timeZoneName}）',
      '目标日期：$dayKey',
      '默认工作时段：${_minute(preferences.workdayStartMinute)}-'
          '${_minute(preferences.lunchStartMinute)}、'
          '${_minute(preferences.lunchEndMinute)}-'
          '${_minute(preferences.workdayEndMinute)}',
      '专注块 ${preferences.focusMinutes} 分钟，休息 ${preferences.breakMinutes} 分钟',
      '今日可用容量：约 $capacityMinutes 分钟',
      '固定日程：',
    ];
    if (fixedOccurrences.isEmpty) {
      lines.add('  - 无');
    } else {
      for (final occurrence in fixedOccurrences) {
        lines.add(
          '  - ${_time(occurrence.start)}-${_time(occurrence.end)} '
          '${occurrence.event.title}（eventId=${occurrence.event.id}）',
        );
      }
    }
    if (allDayOccurrences.isNotEmpty) {
      lines.add('全天日程（只作上下文，不占满 24 小时）：');
      for (final occurrence in allDayOccurrences) {
        lines.add('  - ${occurrence.event.title}');
      }
    }
    lines.add('可用时间窗口：');
    if (availableWindows.isEmpty) {
      lines.add('  - 无。不得虚构具体时间，只能排序并放入待安排。');
    } else {
      for (final window in availableWindows) {
        lines.add('  - ${_time(window.start)}-${_time(window.end)}');
      }
    }
    lines.add('未完成任务：');
    if (tasks.isEmpty) {
      lines.add('  - 无');
    } else {
      for (final task in tasks) {
        final due = task.dueAt == null ? '无截止' : '截止 ${_dateTime(task.dueAt!)}';
        final estimate = task.estimatedMinutes == null
            ? '未估时'
            : '${task.estimatedMinutes} 分钟';
        final scheduled = scheduledTaskIds.contains(task.id) ? '，已有日程' : '';
        lines.add(
          '  - taskId=${task.id}｜${task.title}｜${task.priority.name}｜'
          '$due｜$estimate$scheduled',
        );
      }
    }
    if (countdowns.isNotEmpty) {
      lines.add('近期倒计时：');
      for (final item in countdowns) {
        lines.add('  - ${item.title}：${_dateTime(item.targetTime)}');
      }
    }
    final goal = request.goalText?.trim();
    if (goal != null && goal.isNotEmpty) {
      lines.add('用户今日目标：$goal');
    }
    if (request.mustDoTaskIds.isNotEmpty) {
      lines.add('必须完成的任务 ID：${request.mustDoTaskIds.join(', ')}');
    }
    if (request.energy != null && request.energy!.trim().isNotEmpty) {
      lines.add('精力状态：${request.energy!.trim()}');
    }
    if (request.notes != null && request.notes!.trim().isNotEmpty) {
      lines.add('补充约束：${request.notes!.trim()}');
    }
    if (request.weatherSummary != null &&
        request.weatherSummary!.trim().isNotEmpty) {
      lines.add('天气：${request.weatherSummary!.trim()}');
    }
    if (priorReview != null && priorReview.trim().isNotEmpty) {
      lines.add('昨日复盘摘要：$priorReview');
    }
    return lines.join('\n');
  }

  List<PlanningInterval> _merge(List<PlanningInterval> input) {
    if (input.isEmpty) return const <PlanningInterval>[];
    final sorted = input
        .where((PlanningInterval i) => i.end.isAfter(i.start))
        .toList()
      ..sort((PlanningInterval a, PlanningInterval b) =>
          a.start.compareTo(b.start));
    if (sorted.isEmpty) return const <PlanningInterval>[];
    final result = <PlanningInterval>[sorted.first];
    for (final interval in sorted.skip(1)) {
      final last = result.last;
      if (!interval.start.isAfter(last.end)) {
        final end = interval.end.isAfter(last.end) ? interval.end : last.end;
        result[result.length - 1] =
            PlanningInterval(start: last.start, end: end);
      } else {
        result.add(interval);
      }
    }
    return result;
  }

  List<PlanningInterval> _subtract(
    List<PlanningInterval> base,
    List<PlanningInterval> blockers,
  ) {
    var result = base;
    for (final blocker in blockers) {
      final next = <PlanningInterval>[];
      for (final interval in result) {
        if (!_overlaps(interval, blocker)) {
          next.add(interval);
          continue;
        }
        if (blocker.start.isAfter(interval.start)) {
          next.add(PlanningInterval(start: interval.start, end: blocker.start));
        }
        if (blocker.end.isBefore(interval.end)) {
          next.add(PlanningInterval(start: blocker.end, end: interval.end));
        }
      }
      result = next
          .where((PlanningInterval i) => i.end.isAfter(i.start))
          .toList(growable: false);
    }
    return result;
  }

  static bool _overlaps(PlanningInterval a, PlanningInterval b) =>
      a.start.isBefore(b.end) && b.start.isBefore(a.end);

  static PlanningInterval? _clip(
    PlanningInterval interval,
    DateTime from,
    DateTime to,
  ) {
    final start = interval.start.isBefore(from) ? from : interval.start;
    final end = interval.end.isAfter(to) ? to : interval.end;
    if (!end.isAfter(start)) return null;
    return PlanningInterval(start: start, end: end);
  }

  static String _truncate(String? value, int max) {
    if (value == null || value.trim().isEmpty) return '';
    final text = value.trim();
    return text.length <= max ? text : '${text.substring(0, max)}…';
  }

  static String _dayKey(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static String _time(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}';
  }

  static String _dateTime(DateTime time) => '${_dayKey(time)} ${_time(time)}';

  static String _minute(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:'
      '${(value % 60).toString().padLeft(2, '0')}';
}
