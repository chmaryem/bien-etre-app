import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _tailleController;
  late TextEditingController _poidsController;
  late TextEditingController _objectifController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController(text: widget.user.nom);
    _emailController = TextEditingController(text: widget.user.email);
    _ageController = TextEditingController(
        text: widget.user.age != null ? widget.user.age.toString() : '');
    _tailleController = TextEditingController(
        text: widget.user.taille != null ? widget.user.taille.toString() : '');
    _poidsController = TextEditingController(
        text: widget.user.poids != null ? widget.user.poids.toString() : '');
    _objectifController =
        TextEditingController(text: widget.user.objectif ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _objectifController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      User updatedUser = widget.user.copyWith(
        nom: _nomController.text.trim(),
        email: _emailController.text.trim(),
        age: int.tryParse(_ageController.text),
        taille: double.tryParse(_tailleController.text),
        poids: double.tryParse(_poidsController.text),
        objectif: _objectifController.text.trim(),
      );

      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateUser(updatedUser);

      final refreshedUser = await dbHelper.getUserById(widget.user.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès ✅'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, refreshedUser ?? updatedUser);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ✅ Dialogue pour changer le mot de passe
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ancien mot de passe
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Ancien mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureOld = !obscureOld;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Champ requis" : null,
                ),
                const SizedBox(height: 16),

                // Nouveau mot de passe
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Champ requis";
                    if (val.length < 6) {
                      return "Au moins 6 caractères requis";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmer le mot de passe
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val != newPasswordController.text) {
                      return "Les mots de passe ne correspondent pas";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final dbHelper = DatabaseHelper.instance;

                // Vérifier l'ancien mot de passe
                final isValid = await dbHelper.verifyPassword(
                  widget.user.email,
                  oldPasswordController.text,
                );

                if (!isValid) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ancien mot de passe incorrect'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Changer le mot de passe
                await dbHelper.changePassword(
                  widget.user.id!,
                  newPasswordController.text,
                );

                if (!context.mounted) return;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe modifié avec succès ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Dialogue de confirmation pour supprimer le compte
  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Supprimer le compte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ Cette action est irréversible. Toutes vos données seront supprimées.',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer avec votre mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer votre mot de passe'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final dbHelper = DatabaseHelper.instance;

                // Vérifier le mot de passe
                final isValid = await dbHelper.verifyPassword(
                  widget.user.email,
                  passwordController.text,
                );

                if (!isValid) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe incorrect'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Supprimer le compte
                await dbHelper.deleteUser(widget.user.id!);

                if (!context.mounted) return;

                Navigator.pop(context); // Fermer le dialogue
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login', // Ou '/register' selon votre navigation
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compte supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF667eea).withOpacity(0.2),
                  child: Text(
                    widget.user.nom.isNotEmpty
                        ? widget.user.nom[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Champs de profil
              _buildTextField(_nomController, "Nom complet", Icons.person,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? "Champ requis"
                      : null),

              _buildTextField(
                _emailController,
                "Adresse e-mail",
                Icons.email,
                validator: (val) => val == null || !val.contains("@")
                    ? "Email invalide"
                    : null,
              ),

              _buildTextField(_ageController, "Âge", Icons.cake,
                  keyboardType: TextInputType.number),

              _buildTextField(_tailleController, "Taille (cm)", Icons.height,
                  keyboardType: TextInputType.number),

              _buildTextField(
                  _poidsController, "Poids (kg)", Icons.monitor_weight,
                  keyboardType: TextInputType.number),

              _buildTextField(
                  _objectifController, "Objectif", Icons.flag_outlined),

              const SizedBox(height: 30),

              // Bouton Sauvegarder
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        "Sauvegarder les modifications",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 20),

              // ✅ Bouton Changer le mot de passe
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF667eea)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock, color: Color(0xFF667eea)),
                label: const Text(
                  "Changer le mot de passe",
                  style: TextStyle(fontSize: 16, color: Color(0xFF667eea)),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 10),

              // ✅ Bouton Supprimer le compte
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _showDeleteAccountDialog,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  "Supprimer mon compte",
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF667eea),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}