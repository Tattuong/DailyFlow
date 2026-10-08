import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/flow/daily_book.dart';
import '../providers/daily_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/coin_balance_chip.dart';
import 'editor_screen.dart';
import 'home/settings_screen.dart';
import 'run_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;
  late DateTime _day = DailyEngine.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return FtrScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (_tab) {
                1 => const _Library(),
                2 => const _Progress(),
                _ => _Today(
                    day: _day,
                    onDay: (day) => setState(() => _day = day),
                    onProgress: () => setState(() => _tab = 2),
                  ),
              },
            ),
            const AdBannerSlot(),
            _Bar(
                index: _tab, onSelect: (index) => setState(() => _tab = index)),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _Bar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          _item(0, Icons.home_outlined, Icons.home_rounded, 'Today'),
          _item(1, Icons.list_alt_outlined, Icons.list_alt, 'Routine'),
          _item(
              2, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Progress'),
        ],
      ),
    );
  }

  Widget _item(int i, IconData icon, IconData selected, String label) {
    final on = index == i;
    final color = on ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(on ? selected : icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Today extends StatelessWidget {
  final DateTime day;
  final ValueChanged<DateTime> onDay;
  final VoidCallback onProgress;

  const _Today({
    required this.day,
    required this.onDay,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyProvider>();
    final scheduled = DailyEngine.onDay(daily.routines, day);
    final done = scheduled
        .where((routine) => DailyEngine.finishedOn(daily.logs, routine.id, day))
        .length;
    final start = DailyEngine.weekStart(day);
    final today = DailyEngine.dateOnly(DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const _Mark(),
            const SizedBox(width: 8),
            const Text('DailyFlow',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            const CoinBalanceChip(variant: CoinChipVariant.header),
            IconButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: day,
                  firstDate: DateTime(today.year - 1),
                  lastDate: DateTime(today.year + 1),
                );
                if (picked != null) onDay(DailyEngine.dateOnly(picked));
              },
              icon: const Icon(Icons.calendar_today_outlined),
            ),
          ],
        ),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text('A good day,\nfrom a small step.',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: AppColors.ink)),
            ),
            _Sun(),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _DayChip(
                  label: DailyEngine.dayLabels[i],
                  selected: start.add(Duration(days: i)) == day,
                  onTap: () => onDay(start.add(Duration(days: i))),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _PlanChip(
          done: done,
          total: scheduled.length,
          onTap: onProgress,
        ),
        const SizedBox(height: 14),
        if (scheduled.isEmpty)
          const Text(
              'Nothing is planned for this day. Create a chain for weekdays or weekends.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.35)),
        for (var i = 0; i < scheduled.length; i++) ...[
          _RoutineCard(
            routine: scheduled[i],
            day: day,
            featured: i == 0 &&
                !DailyEngine.finishedOn(daily.logs, scheduled[i].id, day),
            live: daily.live,
            finished: DailyEngine.finishedOn(daily.logs, scheduled[i].id, day),
            canStart: DailyEngine.sameDay(day, today),
          ),
          const SizedBox(height: 12),
        ],
        _OutlineButton(
          icon: Icons.add,
          label: 'Create routine',
          onTap: () => openRoutineEditor(context),
        ),
      ],
    );
  }
}

Future<void> openRoutineEditor(BuildContext context) async {
  final daily = context.read<DailyProvider>();
  final shop = context.read<ShopProvider>();
  if (!daily.canAdd(shop.hasPro)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Open DailyFlow Pro to keep more routines.')));
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const EditorScreen()),
  );
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final DateTime day;
  final bool featured;
  final LiveRun? live;
  final bool finished;
  final bool canStart;

  const _RoutineCard({
    required this.routine,
    required this.day,
    required this.featured,
    required this.live,
    required this.finished,
    required this.canStart,
  });

  @override
  Widget build(BuildContext context) {
    final tint = _toneTint(routine.tone);
    final accent = _toneAccent(routine.tone);
    final filled = DailyEngine.filled(routine, live, finished);
    return Material(
      color: tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: routine.tone % 4 == 2
              ? const Color(0xFFE4DCF8)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: finished || !canStart ? null : () => _start(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ToneIcon(tone: routine.tone, accent: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routine.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(
                          '${_count(routine.steps.length, 'step', 'steps')} · ${DailyEngine.minutesLabel(routine.totalSeconds)}',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!featured)
                    Icon(finished ? Icons.check_circle : Icons.chevron_right,
                        color: finished ? accent : AppColors.textSecondary),
                ],
              ),
              if (featured) ...[
                const SizedBox(height: 12),
                _Segments(count: routine.steps.length, filled: filled),
                if (canStart) ...[
                  const SizedBox(height: 12),
                  _FilledButton(
                    label: 'Start',
                    onTap: () => _start(context),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context) {
    context.read<DailyProvider>().openRun(routine.id);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RunScreen(routineId: routine.id)),
    );
  }
}

class _Library extends StatelessWidget {
  const _Library();

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Routine',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const Text('Each chain is a set of timed steps with a short cue.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35)),
        const SizedBox(height: 16),
        for (final routine in daily.routines) ...[
          Material(
            color: _toneTint(routine.tone),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditorScreen(routineId: routine.id),
              )),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _ToneIcon(
                        tone: routine.tone, accent: _toneAccent(routine.tone)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routine.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            '${_count(routine.steps.length, 'step', 'steps')} · ${DailyEngine.minutesLabel(routine.totalSeconds)} · ${_dayPhrase(routine.days)}',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _OutlineButton(
          icon: Icons.add,
          label: 'Create routine',
          onTap: () => openRoutineEditor(context),
        ),
      ],
    );
  }
}

class _Progress extends StatefulWidget {
  const _Progress();

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  var _month = false;

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyProvider>();
    final today = DateTime.now();
    final start = _month
        ? DateTime(today.year, today.month)
        : DailyEngine.weekStart(today);
    final end = _month
        ? DateTime(today.year, today.month + 1, 0)
        : start.add(const Duration(days: 6));
    final stat = DailyEngine.summarize(
      routines: daily.routines,
      logs: daily.logs,
      start: start,
      end: end,
      today: today,
    );
    final bars = _month ? _weeks(stat.days) : stat.days;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const _Wordmark(),
        const Text('Your rhythm',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 12),
        Row(
          children: [
            _Filter(
                label: 'Week',
                selected: !_month,
                onTap: () => setState(() => _month = false)),
            const SizedBox(width: 8),
            _Filter(
                label: 'Month',
                selected: _month,
                onTap: () => setState(() => _month = true)),
          ],
        ),
        const SizedBox(height: 14),
        _ChartCard(stat: stat, bars: bars, month: _month),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                tint: const Color(0xFFFFF1E6),
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFE07A3D),
                value: _count(stat.streak, 'day', 'days'),
                label: 'In a row',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                tint: const Color(0xFFF3EEFF),
                icon: Icons.hourglass_bottom,
                iconColor: AppColors.primary,
                value: _count(stat.minutes, 'min', 'min'),
                label: 'For yourself',
              ),
            ),
          ],
        ),
        if (stat.steadyName != null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.wb_sunny_outlined,
            title: '${stat.steadyName} is the steadiest',
            subtitle:
                'Finished ${stat.steadyCount} times this ${_month ? 'month' : 'week'}',
          ),
        ],
        if (stat.droppedTitle != null) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.flag_outlined,
            title: 'The step you leave most',
            subtitle: '${stat.droppedTitle} · left ${stat.droppedCount} times',
          ),
        ],
        const SizedBox(height: 18),
        const Center(
          child: Text('Steady beats perfect.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  List<DayBar> _weeks(List<DayBar> days) {
    final groups = <DayBar>[];
    for (var i = 0; i < days.length; i += 7) {
      final slice = days.skip(i).take(7);
      var done = 0;
      var planned = 0;
      var future = true;
      DateTime? day;
      for (final bar in slice) {
        done += bar.done;
        planned += bar.planned;
        future = future && bar.future;
        day ??= bar.day;
      }
      groups.add(DayBar(
        day: day ?? DateTime.now(),
        done: done,
        planned: planned,
        future: future,
      ));
    }
    return groups;
  }
}

class _ChartCard extends StatelessWidget {
  final RangeStat stat;
  final List<DayBar> bars;
  final bool month;

  const _ChartCard({
    required this.stat,
    required this.bars,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final maxDone =
        bars.fold<int>(1, (max, bar) => bar.done > max ? bar.done : max);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2458),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stat.done}/${stat.planned}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${stat.percent}% this ${month ? 'month' : 'week'}',
                    style: const TextStyle(
                        color: Color(0xFFD9D0FF), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Text('routines done',
              style: TextStyle(color: Color(0xFFD9D0FF))),
          const SizedBox(height: 16),
          SizedBox(
            height: 136,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _bar(bars[i], maxDone, i)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _Legend(color: Color(0xFFC4B6FF), label: 'Done'),
              SizedBox(width: 14),
              _Legend(color: Color(0xFF6E6794), label: 'Planned', dashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(DayBar bar, int maxDone, int index) {
    final label =
        month ? 'W${index + 1}' : DailyEngine.dayLabels[bar.day.weekday - 1];
    final dashed = bar.future || bar.done == 0;
    final factor = dashed ? 0.34 : 0.34 + 0.66 * (bar.done / maxDone);
    return Column(
      children: [
        Text('${bar.done}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: factor,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dashed ? Colors.transparent : const Color(0xFFC4B6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: dashed
                      ? Border.all(color: const Color(0xFF8E86B8), width: 1.4)
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color(0xFFD9D0FF), fontSize: 11, height: 1)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _Legend(
      {required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: dashed ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: Color(0xFFD9D0FF), fontSize: 12)),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _Mark(),
          SizedBox(width: 8),
          Text('DailyFlow',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 18),
      painter: _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final top = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
          size.width * 0.25, 0, size.width * 0.5, size.height * 0.45)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.9, size.width, size.height * 0.4);
    final low = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.35,
          size.width * 0.62, size.height * 0.75)
      ..quadraticBezierTo(
          size.width * 0.82, size.height, size.width, size.height * 0.7);
    canvas.drawPath(top, paint);
    canvas.drawPath(low, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Sun extends StatelessWidget {
  const _Sun();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFE08A),
      ),
      child: const Icon(Icons.wb_sunny_rounded,
          color: Color(0xFFF5A524), size: 28),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final int done;
  final int total;
  final VoidCallback onTap;

  const _PlanChip({
    required this.done,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 3,
                  backgroundColor: const Color(0xFFE7E0F8),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text('$done/$total routines done',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  final int count;
  final int filled;

  const _Segments({required this.count, required this.filled});

  @override
  Widget build(BuildContext context) {
    final n = count <= 0 ? 1 : count;
    final portion = (filled / n).clamp(0.0, 1.0);
    return SizedBox(
      height: 18,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE4DCF8),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          FractionallySizedBox(
            widthFactor: portion == 0 ? 0.001 : portion,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (filled > 0)
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilledButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE4DCF8)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              )),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color tint;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.tint,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE07A3D)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _ToneIcon extends StatelessWidget {
  final int tone;
  final Color accent;

  const _ToneIcon({required this.tone, required this.accent});

  @override
  Widget build(BuildContext context) {
    final icon = switch (tone % 4) {
      0 => Icons.wb_sunny_outlined,
      1 => Icons.home_outlined,
      2 => Icons.nightlight_outlined,
      _ => Icons.bolt_outlined,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: accent, size: 20),
    );
  }
}

Color _toneTint(int tone) => switch (tone % 4) {
      0 => const Color(0xFFF3EEFF),
      1 => const Color(0xFFFFF1E6),
      2 => Colors.white,
      _ => const Color(0xFFEEF6FF),
    };

Color _toneAccent(int tone) => switch (tone % 4) {
      0 => AppColors.primary,
      1 => const Color(0xFFE07A3D),
      2 => const Color(0xFF6D5BD0),
      _ => const Color(0xFF3D7EA6),
    };

String _count(int count, String one, String many) =>
    count == 1 ? '1 $one' : '$count $many';

String _dayPhrase(List<int> days) {
  final set = days.toSet();
  const week = {1, 2, 3, 4, 5};
  const weekend = {6, 7};
  if (set.containsAll(week) && set.containsAll(weekend)) return 'Every day';
  if (set.containsAll(week) && set.length == 5) return 'Weekdays';
  if (set.containsAll(weekend) && set.length == 2) return 'Weekends';
  if (set.isEmpty) return 'No days selected';
  final labels = [
    for (final day in days.toList()..sort()) DailyEngine.dayLabels[day - 1]
  ];
  return labels.join(' ');
}
