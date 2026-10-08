import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/flow/daily_book.dart';
import '../providers/daily_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_scaffold.dart';

class EditorScreen extends StatefulWidget {
  final String? routineId;

  const EditorScreen({super.key, this.routineId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _DraftStep {
  final String id;
  final TextEditingController title;
  final TextEditingController guide;
  var minutes = 5;

  _DraftStep(
      {required this.id,
      String title = '',
      String guide = '',
      this.minutes = 5})
      : title = TextEditingController(text: title),
        guide = TextEditingController(text: guide);

  void dispose() {
    title.dispose();
    guide.dispose();
  }
}

class _EditorScreenState extends State<EditorScreen> {
  final _name = TextEditingController();
  final _steps = <_DraftStep>[];
  final _days = <int>{1, 2, 3, 4, 5};
  var _tone = 3;
  var _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final routine = widget.routineId == null
        ? null
        : context.read<DailyProvider>().find(widget.routineId!);
    if (routine == null) {
      _steps.add(_DraftStep(id: 'new-0'));
      return;
    }
    _name.text = routine.name;
    _tone = routine.tone;
    _days
      ..clear()
      ..addAll(routine.days);
    for (final step in routine.steps) {
      _steps.add(_DraftStep(
        id: step.id,
        title: step.title,
        guide: step.guide,
        minutes: (step.seconds / 60).round().clamp(1, 60),
      ));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.routineId != null;
    return FtrScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(editing ? 'Edit routine' : 'Create routine',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 17)),
                ),
                if (editing)
                  IconButton(
                    onPressed: () async {
                      await context
                          .read<DailyProvider>()
                          .deleteRoutine(widget.routineId!);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            const Text('Chain name',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: _field('Easy morning, before bed, quick tidy'),
            ),
            const SizedBox(height: 16),
            const Text('Schedule',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              children: [
                _preset('Weekdays', const {1, 2, 3, 4, 5}),
                const SizedBox(width: 8),
                _preset('Weekends', const {6, 7}),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(DailyEngine.dayLabels[day - 1]),
                    selected: _days.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _days.add(day);
                      } else {
                        _days.remove(day);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Steps', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var i = 0; i < _steps.length; i++) ...[
              _stepCard(i),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _steps.add(_DraftStep(
                  id: 'new-${DateTime.now().microsecondsSinceEpoch}',
                ));
              }),
              icon: const Icon(Icons.add),
              label: const Text('Add step'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save routine',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preset(String label, Set<int> days) {
    final on = _days.length == days.length && _days.containsAll(days);
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() {
          _days
            ..clear()
            ..addAll(days);
        }),
        style: OutlinedButton.styleFrom(
          foregroundColor: on ? Colors.white : AppColors.primary,
          backgroundColor: on ? AppColors.primary : Colors.white,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _stepCard(int index) {
    final step = _steps[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Step ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_steps.length > 1)
                IconButton(
                  onPressed: () => setState(() {
                    _steps.removeAt(index).dispose();
                  }),
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
          TextField(
            controller: step.title,
            decoration: _field('Step name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: step.guide,
            decoration: _field('Short cue'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Duration'),
              const Spacer(),
              IconButton(
                onPressed: step.minutes <= 1
                    ? null
                    : () => setState(() => step.minutes -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(step.minutes == 1 ? '1 min' : '${step.minutes} min',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: step.minutes >= 60
                    ? null
                    : () => setState(() => step.minutes += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E0F0)),
        ),
      );

  Future<void> _save() async {
    final daily = context.read<DailyProvider>();
    final steps = [
      for (final step in _steps)
        if (step.title.text.trim().isNotEmpty)
          FlowStep(
            id: step.id,
            title: step.title.text.trim(),
            guide: step.guide.text.trim(),
            seconds: step.minutes * 60,
          ),
    ];
    if (_name.text.trim().isEmpty || steps.isEmpty || _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Need a name, at least one step, and one day.')));
      return;
    }
    final routine = Routine(
      id: widget.routineId ?? daily.nextId('routine'),
      name: _name.text.trim(),
      tone: widget.routineId == null ? daily.routines.length % 4 : _tone,
      days: _days.toList()..sort(),
      steps: steps,
    );
    if (widget.routineId == null) {
      final shop = context.read<ShopProvider>();
      if (!daily.canAdd(shop.hasPro)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Open DailyFlow Pro to keep more routines.')));
        return;
      }
      await daily.addRoutine(routine, hasPro: shop.hasPro);
    } else {
      await daily.updateRoutine(routine);
    }
    if (mounted) Navigator.pop(context);
  }
}
