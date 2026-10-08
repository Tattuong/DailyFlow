import 'dart:convert';

enum StepOutcome { done, skipped, left }

class FlowStep {
  final String id;
  final String title;
  final String guide;
  final int seconds;

  const FlowStep({
    required this.id,
    required this.title,
    required this.guide,
    required this.seconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'guide': guide,
        'seconds': seconds,
      };

  factory FlowStep.fromJson(Map<String, dynamic> json) => FlowStep(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        guide: json['guide'] as String? ?? '',
        seconds: (json['seconds'] as num?)?.toInt() ?? 60,
      );
}

class Routine {
  final String id;
  final String name;
  final int tone;
  final List<int> days;
  final List<FlowStep> steps;

  const Routine({
    required this.id,
    required this.name,
    required this.tone,
    required this.days,
    required this.steps,
  });

  int get totalSeconds => steps.fold(0, (sum, step) => sum + step.seconds);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tone': tone,
        'days': days,
        'steps': steps.map((step) => step.toJson()).toList(),
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        tone: (json['tone'] as num?)?.toInt() ?? 0,
        days: [
          for (final day in json['days'] as List? ?? []) (day as num).toInt(),
        ],
        steps: [
          for (final step in json['steps'] as List? ?? [])
            FlowStep.fromJson(Map<String, dynamic>.from(step as Map)),
        ],
      );
}

class StepMark {
  final String stepId;
  final String title;
  final StepOutcome outcome;

  const StepMark({
    required this.stepId,
    required this.title,
    required this.outcome,
  });

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'title': title,
        'outcome': outcome.name,
      };

  factory StepMark.fromJson(Map<String, dynamic> json) => StepMark(
        stepId: json['stepId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        outcome:
            StepOutcome.values.byName(json['outcome'] as String? ?? 'done'),
      );
}

class SessionLog {
  final String routineId;
  final String routineName;
  final DateTime at;
  final bool finished;
  final int secondsSpent;
  final List<StepMark> marks;

  const SessionLog({
    required this.routineId,
    required this.routineName,
    required this.at,
    required this.finished,
    required this.secondsSpent,
    required this.marks,
  });

  Map<String, dynamic> toJson() => {
        'routineId': routineId,
        'routineName': routineName,
        'at': at.toIso8601String(),
        'finished': finished,
        'secondsSpent': secondsSpent,
        'marks': marks.map((mark) => mark.toJson()).toList(),
      };

  factory SessionLog.fromJson(Map<String, dynamic> json) => SessionLog(
        routineId: json['routineId'] as String? ?? '',
        routineName: json['routineName'] as String? ?? '',
        at: DateTime.parse(json['at'] as String),
        finished: json['finished'] as bool? ?? false,
        secondsSpent: (json['secondsSpent'] as num?)?.toInt() ?? 0,
        marks: [
          for (final mark in json['marks'] as List? ?? [])
            StepMark.fromJson(Map<String, dynamic>.from(mark as Map)),
        ],
      );
}

class LiveRun {
  final String routineId;
  final int index;
  final int remaining;
  final int budget;
  final bool paused;
  final List<String> doneIds;
  final List<String> skippedIds;
  final int spent;

  const LiveRun({
    required this.routineId,
    required this.index,
    required this.remaining,
    required this.budget,
    required this.paused,
    required this.doneIds,
    required this.skippedIds,
    required this.spent,
  });

  LiveRun copyWith({
    int? index,
    int? remaining,
    int? budget,
    bool? paused,
    List<String>? doneIds,
    List<String>? skippedIds,
    int? spent,
  }) =>
      LiveRun(
        routineId: routineId,
        index: index ?? this.index,
        remaining: remaining ?? this.remaining,
        budget: budget ?? this.budget,
        paused: paused ?? this.paused,
        doneIds: doneIds ?? this.doneIds,
        skippedIds: skippedIds ?? this.skippedIds,
        spent: spent ?? this.spent,
      );

  Map<String, dynamic> toJson() => {
        'routineId': routineId,
        'index': index,
        'remaining': remaining,
        'budget': budget,
        'paused': paused,
        'doneIds': doneIds,
        'skippedIds': skippedIds,
        'spent': spent,
      };

  factory LiveRun.fromJson(Map<String, dynamic> json) => LiveRun(
        routineId: json['routineId'] as String,
        index: (json['index'] as num?)?.toInt() ?? 0,
        remaining: (json['remaining'] as num?)?.toInt() ?? 0,
        budget: (json['budget'] as num?)?.toInt() ?? 1,
        paused: json['paused'] as bool? ?? false,
        doneIds: [
          for (final id in json['doneIds'] as List? ?? []) id.toString(),
        ],
        skippedIds: [
          for (final id in json['skippedIds'] as List? ?? []) id.toString(),
        ],
        spent: (json['spent'] as num?)?.toInt() ?? 0,
      );
}

class DayBar {
  final DateTime day;
  final int done;
  final int planned;
  final bool future;

  const DayBar({
    required this.day,
    required this.done,
    required this.planned,
    required this.future,
  });
}

class RangeStat {
  final int done;
  final int planned;
  final int minutes;
  final int streak;
  final String? steadyName;
  final int steadyCount;
  final String? droppedTitle;
  final int droppedCount;
  final List<DayBar> days;

  const RangeStat({
    required this.done,
    required this.planned,
    required this.minutes,
    required this.streak,
    required this.steadyName,
    required this.steadyCount,
    required this.droppedTitle,
    required this.droppedCount,
    required this.days,
  });

  int get percent => planned == 0 ? 0 : ((done / planned) * 100).round();
}

class DailyBook {
  final List<Routine> routines;
  final List<SessionLog> logs;
  final LiveRun? live;

  const DailyBook({
    required this.routines,
    required this.logs,
    required this.live,
  });

  String encode() => jsonEncode({
        'routines': routines.map((routine) => routine.toJson()).toList(),
        'logs': logs.map((log) => log.toJson()).toList(),
        'live': live?.toJson(),
      });

  factory DailyBook.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DailyBook(
      routines: [
        for (final routine in json['routines'] as List? ?? [])
          Routine.fromJson(Map<String, dynamic>.from(routine as Map)),
      ],
      logs: [
        for (final log in json['logs'] as List? ?? [])
          SessionLog.fromJson(Map<String, dynamic>.from(log as Map)),
      ],
      live: json['live'] == null
          ? null
          : LiveRun.fromJson(Map<String, dynamic>.from(json['live'] as Map)),
    );
  }
}

class DailyEngine {
  DailyEngine._();

  static const freeRoutines = 8;
  static const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static DateTime dateOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<Routine> onDay(List<Routine> routines, DateTime day) => [
        for (final routine in routines)
          if (routine.days.contains(day.weekday)) routine,
      ];

  static bool finishedOn(
      List<SessionLog> logs, String routineId, DateTime day) {
    for (final log in logs) {
      if (log.finished && log.routineId == routineId && sameDay(log.at, day)) {
        return true;
      }
    }
    return false;
  }

  static int filled(Routine routine, LiveRun? live, bool finished) {
    if (finished) return routine.steps.length;
    if (live != null && live.routineId == routine.id) {
      return live.doneIds.length;
    }
    return 0;
  }

  static String clock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final rest = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  static String minutesLabel(int seconds) {
    final minutes = (seconds / 60).round();
    return minutes == 1 ? '1 min' : '$minutes min';
  }

  static int streak(List<SessionLog> logs, DateTime today) {
    final days = <DateTime>{
      for (final log in logs)
        if (log.finished) dateOnly(log.at),
    };
    var cursor = dateOnly(today);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (days.contains(cursor)) {
      count += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  static DateTime weekStart(DateTime day) {
    final date = dateOnly(day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  static RangeStat summarize({
    required List<Routine> routines,
    required List<SessionLog> logs,
    required DateTime start,
    required DateTime end,
    required DateTime today,
  }) {
    final first = dateOnly(start);
    final last = dateOnly(end);
    final now = dateOnly(today);
    final inRange = [
      for (final log in logs)
        if (!dateOnly(log.at).isBefore(first) &&
            !dateOnly(log.at).isAfter(last))
          log,
    ];
    var planned = 0;
    final bars = <DayBar>[];
    for (var day = first;
        !day.isAfter(last);
        day = day.add(const Duration(days: 1))) {
      final scheduled = onDay(routines, day).length;
      planned += scheduled;
      var done = 0;
      for (final log in inRange) {
        if (log.finished && sameDay(log.at, day)) done += 1;
      }
      bars.add(DayBar(
        day: day,
        done: done,
        planned: scheduled,
        future: day.isAfter(now),
      ));
    }
    var done = 0;
    var seconds = 0;
    final finishes = <String, int>{};
    final names = <String, String>{};
    final drops = <String, int>{};
    for (final log in inRange) {
      seconds += log.secondsSpent;
      if (log.finished) {
        done += 1;
        finishes[log.routineId] = (finishes[log.routineId] ?? 0) + 1;
        names[log.routineId] = log.routineName;
      }
      for (final mark in log.marks) {
        if (mark.outcome == StepOutcome.done) continue;
        drops[mark.title] = (drops[mark.title] ?? 0) + 1;
      }
    }
    String? steadyName;
    var steadyCount = 0;
    finishes.forEach((id, count) {
      if (count > steadyCount) {
        steadyCount = count;
        steadyName = names[id];
      }
    });
    String? droppedTitle;
    var droppedCount = 0;
    drops.forEach((title, count) {
      if (count > droppedCount) {
        droppedCount = count;
        droppedTitle = title;
      }
    });
    return RangeStat(
      done: done,
      planned: planned,
      minutes: seconds ~/ 60,
      streak: streak(logs, today),
      steadyName: steadyName,
      steadyCount: steadyCount,
      droppedTitle: droppedTitle,
      droppedCount: droppedCount,
      days: bars,
    );
  }
}
