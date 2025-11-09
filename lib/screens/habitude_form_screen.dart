// lib/screens/habitude_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habitude.dart';
import '../services/notif_service.dart';
import '../store/habits_store.dart';

class HabitudeFormScreen extends StatefulWidget {
  /// Passer `initial` pour éditer, sinon null pour créer
  final Habitude? initial;

  const HabitudeFormScreen({super.key, this.initial});

  @override
  State<HabitudeFormScreen> createState() => _HabitudeFormScreenState();
}

class _HabitudeFormScreenState extends State<HabitudeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _nom;
  String? _description;
  int _categorieId = 0;
  String _couleur = '#2563EB';
  String _icone = '✅';
  FrequenceType _frequence = FrequenceType.quotidien;
  int _frequenceNombre = 1;
  String? _heureNotif; // "HH:mm"
  bool _notifActive = true;

  bool get editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (editing) {
      final h = widget.initial!;
      _nom = h.nom;
      _description = h.description;
      _categorieId = h.categorieId;
      _couleur = h.couleur;
      _icone = h.icone;
      _frequence = h.frequence;
      _frequenceNombre = h.frequenceNombre;
      _heureNotif = h.heureNotification;
      _notifActive = h.notificationActive;
    } else {
      _nom = '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final store = context.read<HabitsStore>();
    final notif = context.read<NotificationService>();

    final h = Habitude(
      id: widget.initial?.id,
      nom: _nom,
      description: _description,
      categorieId: _categorieId,
      couleur: _couleur,
      icone: _icone,
      frequence: _frequence,
      frequenceNombre: _frequenceNombre,
      heureNotification: _heureNotif,
      notificationActive: _notifActive,
      dateCreation: widget.initial?.dateCreation ?? DateTime.now(),
      streakActuel: widget.initial?.streakActuel ?? 0,
      meilleurStreak: widget.initial?.meilleurStreak ?? 0,
    );

    if (editing) {
      // --- Mise à jour ---
      await store.updateHabitude(h);

      // 🔔 Notifications (id non-null en édition)
      await notif.cancelForHabit(h.id!);
      if (h.notificationActive && h.heureNotification != null) {
        await notif.scheduleDailySmart(
          idUnique: h.id!,
          titre: h.nom,
          corps: "N’oublie pas ta routine aujourd’hui !",
          hhmm: h.heureNotification!,
        );
      }
    } else {
      // --- Création ---
      final id = await store.createHabitude(h);

      // 🔔 Notifications
      if (_notifActive && _heureNotif != null) {
        await notif.scheduleDailySmart(
          idUnique: id,
          titre: _nom,
          corps: "N’oublie pas ta routine aujourd’hui !",
          hhmm: _heureNotif!,
        );
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Modifier une habitude' : 'Nouvelle habitude'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _nom,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
                onSaved: (v) => _nom = v!.trim(),
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (v) => _description = v?.trim(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Notification active'),
                value: _notifActive,
                onChanged: (v) => setState(() => _notifActive = v),
              ),
              if (_notifActive)
                TextFormField(
                  initialValue: _heureNotif,
                  decoration: const InputDecoration(
                    labelText: 'Heure notification (HH:mm)',
                    hintText: '08:00',
                  ),
                  onSaved: (v) => _heureNotif = v?.trim(),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(editing ? 'Enregistrer' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
