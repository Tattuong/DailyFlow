import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../core/flow/daily_book.dart';
import '../providers/daily_provider.dart';
import '../widgets/app_scaffold.dart';

class RunScreen extends StatefulWidget {
  final String routineId;

  const RunScreen({super.key, required this.routineId});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  Timer? _timer;
  DailyProvider? _daily;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _daily = context.read<DailyProvider>();
    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    _daily?.persist();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    final run = _daily?.live;
    if (run == null || run.paused || run.routineId != widget.routineId) {
      WakelockPlus.disable();
      return;
    }
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final daily = _daily;
      if (daily == null) return;
      daily.tick();
      if (daily.live?.remaining == 0) _arm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<DailyProvider>();
    final run = daily.live;
    final routine = daily.find(widget.routineId);
    if (run == null || routine == null || run.routineId != widget.routineId) {
      return const FtrScaffold(
          body: Center(child: Text('This routine is gone.')));
    }
    final index = run.index.clamp(0, routine.steps.length - 1);
    final step = routine.steps[index];
    final next =
        index + 1 < routine.steps.length ? routine.steps[index + 1] : null;
    final progress = run.budget <= 0
        ? 1.0
        : (1 - run.remaining / run.budget).clamp(0.0, 1.0);
    return FtrScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                Expanded(
                  child: Text(routine.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value != 'leave') return;
                    await daily.abandon();
                    if (context.mounted) Navigator.pop(context);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'leave', child: Text('Leave routine')),
                  ],
                ),
              ],
            ),
            Text('STEP ${index + 1} / ${routine.steps.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            _StepTrack(
              value: routine.steps.isEmpty
                  ? 0
                  : ((index + 0.45) / routine.steps.length).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 22),
            Text(step.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(step.guide,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.35)),
            const SizedBox(height: 22),
            Center(
              child: SizedBox(
                width: 230,
                height: 230,
                child: CustomPaint(
                  painter: _RingPainter(progress),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DailyEngine.clock(run.remaining),
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      const Text('left',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: daily.addMinute,
                    icon: const Icon(Icons.add),
                    label: const Text('+1 min'),
                    style: _outline(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ended = await daily.skipStep();
                      _arm();
                      if (ended && context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                    style: _outline(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  daily.setPaused(!run.paused);
                  _arm();
                },
                icon: Icon(run.paused ? Icons.play_arrow : Icons.pause),
                label: Text(run.paused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ended = await daily.completeStep();
                  _arm();
                  if (ended && context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Complete step'),
                style: _outline(),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 18),
              const Text('NEXT',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notes,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(next.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(DailyEngine.minutesLabel(next.seconds),
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ButtonStyle _outline() => OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE6E0F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
}

class _StepTrack extends StatelessWidget {
  final double value;

  const _StepTrack({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E0F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value <= 0 ? 0.001 : value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final track = Paint()
      ..color = const Color(0xFFE7E0F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
