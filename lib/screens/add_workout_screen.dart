import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../database/database_helper.dart';

class AddWorkoutScreen extends StatefulWidget {
  final Workout? workout;

  const AddWorkoutScreen({super.key, this.workout});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance; // ✅ CORRECTION: Utilisez .instance

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'Course';
  String _selectedIntensity = 'Faible';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _durationController.text = widget.workout!.duration.toString();
      _caloriesController.text = widget.workout!.calories.toString();
      _distanceController.text = widget.workout!.distance?.toString() ?? '';
      _notesController.text = widget.workout!.notes ?? '';
      _selectedType = widget.workout!.type;
      _selectedIntensity = widget.workout!.intensity;
      _selectedDate = widget.workout!.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'Ajouter une activité' : 'Modifier l\'activité'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['Course', 'Musculation', 'Yoga', 'Natation', 'Cyclisme', 'Marche']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
                decoration: const InputDecoration(labelText: 'Type d\'activité'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de l\'activité'),
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories brûlées'),
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),
              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Distance (km) - optionnel'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedIntensity,
                items: ['Faible', 'Moyenne', 'Élevée']
                    .map((intensity) => DropdownMenuItem(value: intensity, child: Text(intensity)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedIntensity = value!),
                decoration: const InputDecoration(labelText: 'Intensité'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Date: '),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                ],
              ),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes - optionnel'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.workout == null ? 'Ajouter l\'activité' : 'Modifier l\'activité',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _saveWorkout() async {
    if (_formKey.currentState!.validate()) {
      final workout = Workout(
        id: widget.workout?.id,
        type: _selectedType,
        name: _nameController.text,
        duration: double.parse(_durationController.text),
        calories: int.parse(_caloriesController.text),
        date: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        distance: _distanceController.text.isEmpty ? null : double.parse(_distanceController.text),
        intensity: _selectedIntensity,
      );

      if (widget.workout == null) {
        await dbHelper.insertWorkout(workout);
      } else {
        await dbHelper.updateWorkout(workout);
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}