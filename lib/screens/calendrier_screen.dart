import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/habitude.dart';
import '../store/habits_store.dart';

class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ratios[day] -> (done, total)
  final Map<DateTime, (int done, int total)> _ratios = {};
  List<Habitude> _doneThatDay = [];

  bool _loading = true;

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _selectedDay = _norm(DateTime.now());
    _focusedDay = _selectedDay;
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime anyDayInMonth) async {
    setState(() => _loading = true);

    final store = Provider.of<HabitsStore>(context, listen: false);

    final firstOfMonth = DateTime(anyDayInMonth.year, anyDayInMonth.month, 1);
    final monthStart = firstOfMonth.subtract(const Duration(days: 7));
    final monthEnd = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 7);

    final habits = await store.getAllHabitudes();

    final totalPerDay = <DateTime, int>{};
    final donePerDay = <DateTime, int>{};

    for (var d = monthStart;
    d.isBefore(monthEnd);
    d = d.add(const Duration(days: 1))) {
      final nd = _norm(d);
      totalPerDay[nd] = habits.length;
      donePerDay[nd] = 0;
    }

    for (final h in habits) {
      final histo = await store.getHistoriqueByHabitude(h.id!);
      for (final e in histo) {
        final d = _norm(e.date);
        if (!d.isBefore(monthStart) && d.isBefore(monthEnd) && e.accompli) {
          donePerDay[d] = (donePerDay[d] ?? 0) + 1;
        }
      }
    }

    _ratios
      ..clear()
      ..addAll({
        for (final entry in totalPerDay.entries)
          entry.key: (donePerDay[entry.key] ?? 0, entry.value)
      });

    await _loadDetailsFor(_selectedDay);
    setState(() => _loading = false);
  }

  Future<void> _loadDetailsFor(DateTime day) async {
    final store = Provider.of<HabitsStore>(context, listen: false);
    final habits = await store.getAllHabitudes();
    final dayNorm = _norm(day);

    final res = <Habitude>[];
    for (final h in habits) {
      if (await store.isHabitudeAccomplie(h.id!, dayNorm)) {
        res.add(h);
      }
    }
    _doneThatDay = res;
  }

  Color _statusColor(DateTime d) {
    final ratio = _ratios[_norm(d)];
    if (ratio == null) return const Color(0xFFE3E7ED);
    final (done, total) = ratio;
    if (total == 0) return const Color(0xFFE3E7ED);
    if (done == 0) return const Color(0xFF607D8B); // aucun (bleu-gris)
    if (done == total) return const Color(0xFF2ECC71); // vert
    return const Color(0xFFFFB300); // ambre
  }

  Color _statusBackground(DateTime d) {
    final c = _statusColor(d);
    if (c.value == const Color(0xFF607D8B).value) return const Color(0xFFF1F5F8);
    if (c.value == const Color(0xFF2ECC71).value) return const Color(0xFFE9F8F1);
    if (c.value == const Color(0xFFFFB300).value) return const Color(0xFFFFF3D9);
    return const Color(0xFFF3F6F8);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TableCalendar(
              // ↑↑ donne plus d’espace à chaque case, supprime les débordements sporadiques
              rowHeight: 50,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() {
                  _selectedDay = _norm(selectedDay);
                  _focusedDay = focusedDay;
                });
                await _loadDetailsFor(_selectedDay);
                setState(() {});
              },
              onPageChanged: (focused) => _loadMonth(focused),
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                weekendStyle: Theme.of(context).textTheme.bodySmall!,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.6,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.transparent,
                ),
                selectedDecoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.transparent,
                ),
                outsideDaysVisible: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) => _DayCell(
                  day: day,
                  color: _statusColor(day),
                  bg: _statusBackground(day),
                  ratio: _ratios[_norm(day)],
                  isSelected: isSameDay(day, _selectedDay),
                  isToday: isSameDay(day, DateTime.now()),
                ),
                todayBuilder: (context, day, _) => _DayCell(
                  day: day,
                  color: _statusColor(day),
                  bg: _statusBackground(day),
                  ratio: _ratios[_norm(day)],
                  isSelected: false,
                  isToday: true,
                ),
                selectedBuilder: (context, day, _) => _DayCell(
                  day: day,
                  color: _statusColor(day),
                  bg: _statusBackground(day),
                  ratio: _ratios[_norm(day)],
                  isSelected: true,
                  isToday: isSameDay(day, DateTime.now()),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            _Legend(dot: Color(0xFF2ECC71), label: 'Tout accompli'),
            SizedBox(width: 16),
            _Legend(dot: Color(0xFFFFB300), label: 'Partiel'),
            SizedBox(width: 16),
            _Legend(dot: Color(0xFF607D8B), label: 'Aucun'),
          ],
        ),
        const SizedBox(height: 14),
        _DayDetails(date: _selectedDay, habits: _doneThatDay),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color dot;
  final String label;
  const _Legend({required this.dot, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: dot),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color color; // état
  final Color bg; // fond
  final (int done, int total)? ratio;
  final bool isSelected;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.color,
    required this.bg,
    required this.ratio,
    this.isSelected = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
        : Border.all(color: Colors.transparent, width: 1);

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          // Se réduit automatiquement si l’espace est trop juste
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _RatioPill(ratio: ratio, color: color),
          ),
        ],
      ),
    );
  }
}

class _RatioPill extends StatelessWidget {
  final (int done, int total)? ratio;
  final Color color;
  const _RatioPill({required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = ratio == null ? '0/0' : '${ratio!.$1}/${ratio!.$2}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _DayDetails extends StatelessWidget {
  final DateTime date;
  final List<Habitude> habits;
  const _DayDetails({required this.date, required this.habits});

  @override
  Widget build(BuildContext context) {
    final title = 'Détails du ${date.day}/${date.month}/${date.year}';

    final titleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);
    final subtitleStyle =
    Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(title, style: titleStyle),
        trailing: const Icon(Icons.keyboard_arrow_down_rounded),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Aucune habitude accomplie pour ce jour.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87),
              ),
            )
          else
            ...habits.map(
                  (h) => Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7BA05B),
                      child: Text(
                        (h.nom.isNotEmpty ? h.nom[0] : 'H').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title:
                    Text(h.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Habitude', style: subtitleStyle),
                  ),
                  const Divider(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
