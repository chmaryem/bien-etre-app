import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class AddGoalScreen extends StatefulWidget {
  final Goal? goalToEdit; // ✅ paramètre optionnel pour la modification

  const AddGoalScreen({Key? key, this.goalToEdit}) : super(key: key);

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _targetValueController;
  late TextEditingController _currentValueController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  String? _selectedType;
  final List<String> _goalTypes = ['Sommeil', 'Sport', 'Poids', 'Masse musculaire'];

  @override
  void initState() {
    super.initState();

    // ✅ Initialisation des champs selon le mode (ajout ou édition)
    _titleController = TextEditingController(text: widget.goalToEdit?.title ?? '');

    // ✅ S'assurer que le type sélectionné existe dans la liste
    if (widget.goalToEdit?.type != null && _goalTypes.contains(widget.goalToEdit!.type)) {
      _selectedType = widget.goalToEdit!.type;
    } else {
      _selectedType = null;
    }

    _targetValueController =
        TextEditingController(text: widget.goalToEdit?.targetValue.toString() ?? '');
    _currentValueController =
        TextEditingController(text: widget.goalToEdit?.currentValue.toString() ?? '');
    _startDateController = TextEditingController(text: widget.goalToEdit?.startDate ?? '');
    _endDateController = TextEditingController(text: widget.goalToEdit?.endDate ?? '');
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type d\'objectif'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    int? goalId;

    if (widget.goalToEdit == null) {
      // ✅ Ajout - créer un objectif temporaire pour l'insertion
      final tempGoal = Goal(
        id: null,
        title: _titleController.text,
        type: _selectedType!,
        targetValue: double.tryParse(_targetValueController.text) ?? 0.0,
        currentValue: double.tryParse(_currentValueController.text) ?? 0.0,
        startDate: _startDateController.text,
        endDate: _endDateController.text,
      );
      goalId = await DatabaseHelper.instance.insertGoal(tempGoal);
    } else {
      // ✅ Mise à jour
      goalId = widget.goalToEdit!.id;
      final updatedGoal = Goal(
        id: goalId,
        title: _titleController.text,
        type: _selectedType!,
        targetValue: double.tryParse(_targetValueController.text) ?? 0.0,
        currentValue: double.tryParse(_currentValueController.text) ?? 0.0,
        startDate: _startDateController.text,
        endDate: _endDateController.text,
      );
      await DatabaseHelper.instance.updateGoal(updatedGoal);
    }

    // 🔔 Créer l'objectif final avec l'ID correct
    final finalGoal = Goal(
      id: goalId,
      title: _titleController.text,
      type: _selectedType!,
      targetValue: double.tryParse(_targetValueController.text) ?? 0.0,
      currentValue: double.tryParse(_currentValueController.text) ?? 0.0,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
    );

    // 🔔 Planifier les notifications pour cet objectif
    await NotificationService.instance.scheduleGoalNotifications(finalGoal);

    // 🔔 Vérifier la progression et envoyer notification si jalon atteint
    await NotificationService.instance.checkProgressAndNotify(finalGoal);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A5AE0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = picked.toString().split(' ')[0];
    }
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A5AE0).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A5AE0)),
          prefixIcon: Icon(icon, color: const Color(0xFF6A5AE0)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6A5AE0)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isDateField = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A5AE0).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: isDateField,
        onTap: isDateField ? () => _selectDate(context, controller) : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF6A5AE0)),
          prefixIcon: Icon(icon, color: const Color(0xFF6A5AE0)),
          suffixIcon: isDateField
              ? const Icon(Icons.calendar_today, color: Color(0xFF6A5AE0), size: 20)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goalToEdit != null;

    final gradient = const LinearGradient(
      colors: [Color(0xFF6A5AE0), Color(0xFF8C7BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? 'Modifier un objectif' : 'Nouvel objectif',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête avec icône
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEditing ? 'Modifiez votre objectif' : 'Créez un nouvel objectif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Suivez vos progrès et atteignez vos buts',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Formulaire
                _buildTextField(
                  controller: _titleController,
                  label: 'Titre de l\'objectif',
                  icon: Icons.title,
                  validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                ),

                _buildDropdownField(
                  label: 'Type d\'objectif',
                  icon: Icons.category,
                  value: _selectedType,
                  items: _goalTypes,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                ),

                _buildTextField(
                  controller: _targetValueController,
                  label: 'Valeur cible',
                  icon: Icons.trending_up,
                  keyboardType: TextInputType.number,
                ),

                _buildTextField(
                  controller: _currentValueController,
                  label: 'Valeur actuelle',
                  icon: Icons.timeline,
                  keyboardType: TextInputType.number,
                ),

                _buildTextField(
                  controller: _startDateController,
                  label: 'Date de début',
                  icon: Icons.calendar_today,
                  isDateField: true,
                ),

                _buildTextField(
                  controller: _endDateController,
                  label: 'Date de fin',
                  icon: Icons.event,
                  isDateField: true,
                ),

                const SizedBox(height: 8),

                // Bouton d'enregistrement
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A5AE0).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saveGoal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditing ? Icons.save : Icons.add_circle,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Enregistrer les modifications' : 'Ajouter l\'objectif',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}