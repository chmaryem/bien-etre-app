import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/theme.dart';
import '../store/habits_store.dart';
import '../models/habitude.dart';
import '../models/historique.dart';

import '../services/notif_service.dart';
import 'habitude_form_screen.dart';

class HabitudeDetailScreen extends StatefulWidget {
  final int habitudeId;
  const HabitudeDetailScreen({super.key, required this.habitudeId});

  @override
  State<HabitudeDetailScreen> createState() => _HabitudeDetailScreenState();
}

class _HabitudeDetailScreenState extends State<HabitudeDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _selectedDay = _norm(DateTime.now());
    _focusedDay = _selectedDay;
  }

  Future<void> _editHabit(BuildContext context, Habitude hab) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HabitudeFormScreen(initial: hab)),
    );
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _deleteHabit(BuildContext context, Habitude hab) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette habitude ?'),
        content: Text('“${hab.nom}” et tout son historique seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      final store = Provider.of<HabitsStore>(context, listen: false);
      final notif = Provider.of<NotificationService>(context, listen: false);

      await notif.cancelForHabit(hab.id!);
      await store.deleteHabitude(hab.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Habitude supprimée')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<HabitsStore>(context);

    return FutureBuilder<Habitude?>(
      future: store.getHabitudeById(widget.habitudeId),
      builder: (context, snapHabit) {
        if (snapHabit.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hab = snapHabit.data;
        if (hab == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habitude')),
            body: const Center(child: Text('Cette habitude n’existe plus.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(hab.nom),
            actions: [
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit),
                onPressed: () => _editHabit(context, hab),
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteHabit(context, hab),
              ),
            ],
          ),
          body: FutureBuilder<List<HistoriqueHabitude>>(
            future: store.getHistoriqueByHabitude(widget.habitudeId),
            builder: (context, snapHisto) {
              if (!snapHisto.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final histo = snapHisto.data!;
              final completed = histo.where((e) => e.accompli).map((e) => _norm(e.date)).toSet();
              final selectedDone = completed.contains(_selectedDay);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _ChipStat(label: 'Série', value: '${hab.streakActuel}j', icon: Icons.local_fire_department),
                      const SizedBox(width: 8),
                      _ChipStat(label: 'Meilleur', value: '${hab.meilleurStreak}j', icon: Icons.emoji_events_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = _norm(selectedDay);
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final norm = _norm(day);
                            final isDone = completed.contains(norm);
                            return _DayCell(isDone: isDone, day: day);
                          },
                          todayBuilder: (context, day, _) =>
                              _DayCell(isDone: completed.contains(_norm(day)), day: day, isToday: true),
                          selectedBuilder: (context, day, _) =>
                              _DayCell(isDone: completed.contains(_norm(day)), day: day, isSelected: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: AppTheme.successColor),
                      const SizedBox(width: 6),
                      Text('Accompli', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 16),
                      const Icon(Icons.circle, size: 10, color: AppTheme.errorColor),
                      const SizedBox(width: 6),
                      Text('Non accompli', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: ListTile(
                      leading: Icon(selectedDone ? Icons.check_box : Icons.check_box_outline_blank),
                      title: Text('Marquer ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}'),
                      subtitle: Text(selectedDone ? 'Accompli' : 'Non accompli'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          if (isSameDay(_selectedDay, DateTime.now())) {
                            await store.toggleAccompliAujourdHui(widget.habitudeId);
                          } else {
                            await store.marquerHabitudeAccomplie(widget.habitudeId, _selectedDay);
                          }
                          if (!mounted) return;
                          setState(() {});
                        },
                        child: Text(selectedDone ? 'Déjà fait' : 'Marquer fait'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ChipStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label : $value'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _DayCell extends StatelessWidget {
  final bool isDone;
  final bool isToday;
  final bool isSelected;
  final DateTime day;
  const _DayCell({
    required this.isDone,
    required this.day,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = isDone ? AppTheme.successColor : AppTheme.errorColor;
    final bg = isDone ? AppTheme.successColor.withOpacity(0.12) : Colors.transparent;
    final border = isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.circle, size: 8, color: dot),
            ),
          )
        ],
      ),
    );
  }
}
