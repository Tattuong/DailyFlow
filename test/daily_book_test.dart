import 'package:dailyflow/core/flow/daily_book.dart';
import 'package:dailyflow/core/flow/demo_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekday plan keeps tidy off the weekend', () {
    final routines = DemoSeed.routines();
    final monday = DateTime(2026, 10, 5);
    final sunday = DateTime(2026, 10, 11);
    expect(
      DailyEngine.onDay(routines, monday).map((routine) => routine.id),
      ['morning', 'tidy', 'night'],
    );
    expect(
      DailyEngine.onDay(routines, sunday).map((routine) => routine.id),
      ['night'],
    );
    final morning = routines.first;
    expect(morning.totalSeconds, 20 * 60);
    expect(morning.steps[1].title, 'Stretch');
    expect(DailyEngine.clock(180), '03:00');
    expect(DailyEngine.filled(morning, DemoSeed.live(), false), 1);
  });

  test('skipped sweep is the step most often left unfinished', () {
    final today = DateTime(2026, 10, 7);
    final logs = DemoSeed.history(today);
    final stat = DailyEngine.summarize(
      routines: DemoSeed.routines(),
      logs: logs,
      start: today.subtract(const Duration(days: 6)),
      end: today,
      today: today,
    );
    expect(stat.droppedTitle, 'Sweep');
    expect(stat.streak, 4);
    expect(
        DailyBook.decode(DailyBook(
                    routines: DemoSeed.routines(),
                    logs: logs,
                    live: DemoSeed.live())
                .encode())
            .live
            ?.remaining,
        180);
  });
}
