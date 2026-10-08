import 'daily_book.dart';

class DemoSeed {
  DemoSeed._();

  static List<Routine> routines() => const [
        Routine(
          id: 'morning',
          name: 'Easy morning',
          tone: 0,
          days: [1, 2, 3, 4, 5],
          steps: [
            FlowStep(
              id: 'water',
              title: 'Drink water',
              guide: 'A warm glass before you start.',
              seconds: 120,
            ),
            FlowStep(
              id: 'stretch',
              title: 'Stretch',
              guide: 'Relax your shoulders, neck, and back.',
              seconds: 300,
            ),
            FlowStep(
              id: 'plan',
              title: 'Plan the day',
              guide: 'Write three things worth doing today.',
              seconds: 300,
            ),
            FlowStep(
              id: 'door',
              title: 'Head out',
              guide: 'Bag, keys, then one breath.',
              seconds: 480,
            ),
          ],
        ),
        Routine(
          id: 'tidy',
          name: 'Quick tidy',
          tone: 1,
          days: [1, 2, 3, 4, 5],
          steps: [
            FlowStep(
                id: 'gather',
                title: 'Gather things',
                guide: 'Put things back where they belong.',
                seconds: 180),
            FlowStep(
                id: 'table',
                title: 'Wipe the table',
                guide: 'One clear surface is enough.',
                seconds: 180),
            FlowStep(
                id: 'sweep',
                title: 'Sweep',
                guide: 'Only the spot where you are standing.',
                seconds: 180),
            FlowStep(
                id: 'dishes',
                title: 'Wash dishes',
                guide: 'The dishes already in the sink.',
                seconds: 240),
            FlowStep(
                id: 'trash',
                title: 'Take out trash',
                guide: 'Tie the bag and set it by the door.',
                seconds: 120),
          ],
        ),
        Routine(
          id: 'night',
          name: 'Before bed',
          tone: 2,
          days: [1, 2, 3, 4, 5, 6, 7],
          steps: [
            FlowStep(
                id: 'screen',
                title: 'Screens off',
                guide: 'Put the phone out of reach.',
                seconds: 120),
            FlowStep(
                id: 'bed',
                title: 'Make the bed',
                guide: 'Pillow, lamp, and a quiet corner.',
                seconds: 300),
            FlowStep(
                id: 'breath',
                title: 'Slow breaths',
                guide: 'Four counts in, six counts out.',
                seconds: 300),
          ],
        ),
      ];

  static LiveRun live() => const LiveRun(
        routineId: 'morning',
        index: 1,
        remaining: 180,
        budget: 300,
        paused: false,
        doneIds: ['water'],
        skippedIds: [],
        spent: 120,
      );

  static List<SessionLog> history(DateTime now) {
    final today = DailyEngine.dateOnly(now);
    final logs = <SessionLog>[];
    for (var ago = 1; ago <= 4; ago++) {
      final day = today.subtract(Duration(days: ago));
      final morningAt = DateTime(day.year, day.month, day.day, 7, 30);
      final nightAt = DateTime(day.year, day.month, day.day, 22);
      if (day.weekday <= DateTime.friday) {
        logs.add(SessionLog(
          routineId: 'morning',
          routineName: 'Easy morning',
          at: morningAt,
          finished: true,
          secondsSpent: 18 * 60,
          marks: const [
            StepMark(
                stepId: 'water',
                title: 'Drink water',
                outcome: StepOutcome.done),
            StepMark(
                stepId: 'stretch', title: 'Stretch', outcome: StepOutcome.done),
            StepMark(
                stepId: 'plan',
                title: 'Plan the day',
                outcome: StepOutcome.done),
            StepMark(
                stepId: 'door', title: 'Head out', outcome: StepOutcome.done),
          ],
        ));
        logs.add(SessionLog(
          routineId: 'tidy',
          routineName: 'Quick tidy',
          at: morningAt.add(const Duration(hours: 2)),
          finished: false,
          secondsSpent: 8 * 60,
          marks: const [
            StepMark(
                stepId: 'gather',
                title: 'Gather things',
                outcome: StepOutcome.done),
            StepMark(
                stepId: 'table',
                title: 'Wipe the table',
                outcome: StepOutcome.done),
            StepMark(
                stepId: 'sweep', title: 'Sweep', outcome: StepOutcome.skipped),
          ],
        ));
      }
      logs.add(SessionLog(
        routineId: 'night',
        routineName: 'Before bed',
        at: nightAt,
        finished: true,
        secondsSpent: 12 * 60,
        marks: const [
          StepMark(
              stepId: 'screen',
              title: 'Screens off',
              outcome: StepOutcome.done),
          StepMark(
              stepId: 'bed', title: 'Make the bed', outcome: StepOutcome.done),
          StepMark(
              stepId: 'breath',
              title: 'Slow breaths',
              outcome: StepOutcome.done),
        ],
      ));
    }
    return logs;
  }
}
