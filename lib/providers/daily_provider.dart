import 'package:flutter/widgets.dart';

import '../core/flow/daily_book.dart';
import '../core/flow/demo_seed.dart';
import '../core/services/storage_service.dart';

class DailyProvider extends ChangeNotifier {
  static const _bookKey = 'df_days';
  static const _seedKey = 'df_demo_seeded';

  List<Routine> routines = [];
  List<SessionLog> logs = [];
  LiveRun? live;
  var _seq = 0;

  Future<void> init() async {
    final raw = await StorageService.instance.getString(_bookKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final book = DailyBook.decode(raw);
        routines = book.routines;
        logs = book.logs;
        live = book.live;
      } catch (_) {
        await StorageService.instance.remove(_bookKey);
      }
    }
    if (!(await StorageService.instance.getBool(_seedKey) ?? false)) {
      if (routines.isEmpty) {
        final now = DateTime.now();
        routines = DemoSeed.routines();
        logs = DemoSeed.history(now);
        live = DemoSeed.live();
        await _save();
      }
      await StorageService.instance.saveBool(_seedKey, true);
    }
    if (_useEnglishDemo()) await _save();
    notifyListeners();
  }

  bool _useEnglishDemo() {
    final fresh = {
      for (final routine in DemoSeed.routines()) routine.id: routine,
    };
    var changed = false;
    final next = <Routine>[];
    for (final routine in routines) {
      final english = fresh[routine.id];
      if (english != null && routine.name != english.name) {
        changed = true;
        next.add(english);
      } else {
        next.add(routine);
      }
    }
    routines = next;
    final nextLogs = <SessionLog>[];
    for (final log in logs) {
      final english = fresh[log.routineId];
      if (english == null) {
        nextLogs.add(log);
        continue;
      }
      final titles = {for (final step in english.steps) step.id: step.title};
      var marksChanged = false;
      final marks = <StepMark>[];
      for (final mark in log.marks) {
        final title = titles[mark.stepId];
        if (title != null && title != mark.title) {
          marksChanged = true;
          marks.add(StepMark(
            stepId: mark.stepId,
            title: title,
            outcome: mark.outcome,
          ));
        } else {
          marks.add(mark);
        }
      }
      if (log.routineName != english.name || marksChanged) {
        changed = true;
        nextLogs.add(SessionLog(
          routineId: log.routineId,
          routineName: english.name,
          at: log.at,
          finished: log.finished,
          secondsSpent: log.secondsSpent,
          marks: marks,
        ));
      } else {
        nextLogs.add(log);
      }
    }
    logs = nextLogs;
    return changed;
  }

  bool canAdd(bool hasPro) =>
      hasPro || routines.length < DailyEngine.freeRoutines;

  Routine? find(String id) {
    for (final routine in routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  Future<void> addRoutine(Routine routine, {required bool hasPro}) async {
    if (!canAdd(hasPro)) return;
    routines = [...routines, routine];
    await _commit();
  }

  Future<void> updateRoutine(Routine routine) async {
    routines = [
      for (final item in routines) item.id == routine.id ? routine : item,
    ];
    await _commit();
  }

  Future<void> deleteRoutine(String id) async {
    routines = [
      for (final item in routines)
        if (item.id != id) item
    ];
    if (live?.routineId == id) live = null;
    await _commit();
  }

  String nextId(String prefix) {
    _seq += 1;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_seq';
  }

  void openRun(String routineId) {
    final routine = find(routineId);
    if (routine == null || routine.steps.isEmpty) return;
    if (live?.routineId == routineId) return;
    final previous = live;
    final previousRoutine = previous == null ? null : find(previous.routineId);
    if (previous != null && previousRoutine != null) {
      logs = [
        ...logs,
        SessionLog(
          routineId: previousRoutine.id,
          routineName: previousRoutine.name,
          at: DateTime.now(),
          finished: false,
          secondsSpent: previous.spent,
          marks: _marks(previousRoutine, previous, StepOutcome.left),
        ),
      ];
    }
    final step = routine.steps.first;
    live = LiveRun(
      routineId: routineId,
      index: 0,
      remaining: step.seconds,
      budget: step.seconds,
      paused: false,
      doneIds: const [],
      skippedIds: const [],
      spent: 0,
    );
    notifyListeners();
    _save();
  }

  void setPaused(bool paused) {
    final run = live;
    if (run == null) return;
    live = run.copyWith(paused: paused);
    notifyListeners();
    _save();
  }

  void tick() {
    final run = live;
    if (run == null || run.paused || run.remaining <= 0) return;
    live = run.copyWith(remaining: run.remaining - 1, spent: run.spent + 1);
    notifyListeners();
    if (run.remaining % 5 == 0) _save();
  }

  void addMinute() {
    final run = live;
    if (run == null) return;
    live = run.copyWith(remaining: run.remaining + 60, budget: run.budget + 60);
    notifyListeners();
    _save();
  }

  Future<bool> completeStep() => _advance(StepOutcome.done);

  Future<bool> skipStep() => _advance(StepOutcome.skipped);

  Future<void> abandon() async {
    final run = live;
    final routine = run == null ? null : find(run.routineId);
    if (run == null || routine == null) return;
    final marks = _marks(routine, run, StepOutcome.left);
    logs = [
      ...logs,
      SessionLog(
        routineId: routine.id,
        routineName: routine.name,
        at: DateTime.now(),
        finished: false,
        secondsSpent: run.spent,
        marks: marks,
      ),
    ];
    live = null;
    await _commit();
  }

  Future<bool> _advance(StepOutcome outcome) async {
    final run = live;
    final routine = run == null ? null : find(run.routineId);
    if (run == null || routine == null || routine.steps.isEmpty) return true;
    final step = routine.steps[run.index.clamp(0, routine.steps.length - 1)];
    final done = [...run.doneIds];
    final skipped = [...run.skippedIds];
    if (outcome == StepOutcome.done) done.add(step.id);
    if (outcome == StepOutcome.skipped) skipped.add(step.id);
    final next = run.index + 1;
    if (next >= routine.steps.length) {
      final finished = skipped.isEmpty && outcome == StepOutcome.done;
      logs = [
        ...logs,
        SessionLog(
          routineId: routine.id,
          routineName: routine.name,
          at: DateTime.now(),
          finished: finished,
          secondsSpent: run.spent,
          marks: _marks(routine,
              run.copyWith(doneIds: done, skippedIds: skipped), outcome),
        ),
      ];
      live = null;
      await _commit();
      return true;
    }
    final upcoming = routine.steps[next];
    live = run.copyWith(
      index: next,
      remaining: upcoming.seconds,
      budget: upcoming.seconds,
      paused: false,
      doneIds: done,
      skippedIds: skipped,
    );
    await _commit();
    return false;
  }

  List<StepMark> _marks(Routine routine, LiveRun run, StepOutcome current) {
    final marks = <StepMark>[];
    for (var i = 0; i < routine.steps.length; i++) {
      final step = routine.steps[i];
      if (run.doneIds.contains(step.id)) {
        marks.add(StepMark(
            stepId: step.id, title: step.title, outcome: StepOutcome.done));
      } else if (run.skippedIds.contains(step.id)) {
        marks.add(StepMark(
            stepId: step.id, title: step.title, outcome: StepOutcome.skipped));
      } else if (i == run.index) {
        marks.add(
            StepMark(stepId: step.id, title: step.title, outcome: current));
      }
    }
    return marks;
  }

  Future<void> _commit() async {
    await _save();
    notifyListeners();
  }

  Future<void> persist() => _save();

  Future<void> _save() async {
    await StorageService.instance.saveString(
      _bookKey,
      DailyBook(routines: routines, logs: logs, live: live).encode(),
    );
  }
}
