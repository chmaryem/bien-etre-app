import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/notif_service.dart';
import '../services/storage_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  // ---- Notifications ----
  bool _checkingNotif = true;
  bool _notifsEnabled = true;

  // ---- Formulaire profil ----
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _objectifCtrl = TextEditingController();

  bool _loadingProfile = true;
  bool _saving = false;

  // ---- Avatar ----
  String? _avatarPath; // chemin local du fichier image (copié dans app docs)
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Future.wait([
      _refreshNotifState(),
      _loadProfile(),
    ]);
  }

  Future<void> _refreshNotifState() async {
    final notif = Provider.of<NotificationService>(context, listen: false);
    await notif.init();
    final ok = await notif.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notifsEnabled = ok;
      _checkingNotif = false;
    });
  }

  Future<void> _loadProfile() async {
    final storage = StorageService();
    final profile = await storage.loadProfile();
    if (!mounted) return;
    _nomCtrl.text = profile.nom;
    _ageCtrl.text = profile.age?.toString() ?? '';
    _tailleCtrl.text = profile.taille?.toString() ?? '';
    _poidsCtrl.text = profile.poids?.toString() ?? '';
    _objectifCtrl.text = profile.objectif;
    _avatarPath = profile.avatarPath;
    setState(() => _loadingProfile = false);
  }

  UserProfile _profileFromForm() {
    int? parseInt(String s) => s.trim().isEmpty ? null : int.tryParse(s.trim());
    double? parseDouble(String s) =>
        s.trim().isEmpty ? null : double.tryParse(s.trim().replaceAll(',', '.'));
    return UserProfile(
      nom: _nomCtrl.text.trim(),
      age: parseInt(_ageCtrl.text),
      taille: parseDouble(_tailleCtrl.text),
      poids: parseDouble(_poidsCtrl.text),
      objectif: _objectifCtrl.text.trim(),
      avatarPath: _avatarPath,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final profile = _profileFromForm();

    try {
      await StorageService().saveProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l’enregistrement')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleManagePressed() async {
    final notif = Provider.of<NotificationService>(context, listen: false);
    await notif.requestNotificationsPermission();
    await Future.delayed(const Duration(milliseconds: 250));
    await _refreshNotifState();

    if (!_notifsEnabled && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Notifications bloquées'),
          content: const Text(
            "Android bloque encore les notifications pour l’app.\n\n"
                "Ouvre : Paramètres > Applications > Habitude App > Notifications, puis active-les.",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _handleTestPressed() async {
    final notif = Provider.of<NotificationService>(context, listen: false);
    final ok = await notif.areNotificationsEnabled();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications bloquées par Android.\nActive-les dans Paramètres > Applications > Habitude App > Notifications.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    await notif.showNowTest();
  }

  Future<File> _copyToAppDir(File src) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(src.path).toLowerCase();
    final safeExt = (ext.isEmpty) ? '.jpg' : ext;
    final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final dst = File(p.join(dir.path, filename));
    return src.copy(dst.path);
  }

  Future<void> _deletePreviousAvatarFile() async {
    if (_avatarPath == null) return;
    try {
      final f = File(_avatarPath!);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {
      // ignorer silencieusement
    }
  }

  Future<void> _chooseAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return; // annulé
    try {
      final copied = await _copyToAppDir(File(picked.path));
      // supprime l'ancien fichier si on en remplace un
      await _deletePreviousAvatarFile();

      setState(() {
        _avatarPath = copied.path;
      });

      // Sauvegarde immédiate du profil avec nouvel avatar
      final profile = _profileFromForm();
      await StorageService().saveProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar mis à jour')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour l’avatar')),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l’avatar ?'),
        content: const Text('Cette action retirera votre photo de profil.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _deletePreviousAvatarFile();
    setState(() => _avatarPath = null);

    // Sauvegarde le profil sans avatar
    final profile = _profileFromForm();
    await StorageService().saveProfile(profile);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar supprimé')),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _ageCtrl.dispose();
    _tailleCtrl.dispose();
    _poidsCtrl.dispose();
    _objectifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText =
    _checkingNotif ? 'Vérification…' : (_notifsEnabled ? 'Activées ✅' : 'Bloquées ❌');

    final statusSub = _checkingNotif
        ? 'Veuillez patienter'
        : (_notifsEnabled
        ? 'Vous recevez les rappels planifiés.'
        : 'Les rappels ne s’afficheront pas tant que c’est désactivé.');

    final avatarFile =
    (_avatarPath != null && _avatarPath!.isNotEmpty && File(_avatarPath!).existsSync())
        ? FileImage(File(_avatarPath!)) as ImageProvider
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          TextButton.icon(
            onPressed: _loadingProfile || _saving ? null : _saveProfile,
            icon: const Icon(Icons.save, size: 18),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête profil + AVATAR
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                        backgroundImage: avatarFile,
                        child: avatarFile == null
                            ? const Icon(Icons.person, size: 36, color: AppTheme.primaryColor)
                            : null,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: PopupMenuButton<String>(
                          tooltip: 'Changer l’avatar',
                          onSelected: (val) async {
                            switch (val) {
                              case 'gallery':
                                await _chooseAvatar(ImageSource.gallery);
                                break;
                              case 'camera':
                                await _chooseAvatar(ImageSource.camera);
                                break;
                              case 'remove':
                                await _removeAvatar();
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'gallery',
                              child: ListTile(
                                leading: Icon(Icons.photo_library_outlined),
                                title: Text('Choisir depuis la galerie'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'camera',
                              child: ListTile(
                                leading: Icon(Icons.photo_camera_outlined),
                                title: Text('Prendre une photo'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Supprimer l’avatar'),
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mon profil', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Personnalisez vos informations, votre photo et vos préférences.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Formulaire infos
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        hintText: 'Ex. Arij',
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Âge (années)',
                        hintText: 'Ex. 26',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 120) return 'Âge invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tailleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Taille (cm)',
                        hintText: 'Ex. 170',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim().replaceAll(',', '.'));
                        if (n == null || n < 50 || n > 260) return 'Taille invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _poidsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Poids (kg)',
                        hintText: 'Ex. 65.5',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim().replaceAll(',', '.'));
                        if (n == null || n < 20 || n > 400) return 'Poids invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _objectifCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Objectif global',
                        hintText: 'Ex. Être en meilleure forme',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Actions profil
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Actions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _resetProfile,
                    icon: const Icon(Icons.restore),
                    label: const Text('Réinitialiser le profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor.withOpacity(0.12),
                      foregroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section Notifications
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Notifications',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('État actuel : $statusText',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    statusSub,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _checkingNotif ? null : _handleManagePressed,
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Gérer les permissions'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _checkingNotif ? null : _handleTestPressed,
                          icon: const Icon(Icons.notifications),
                          label: const Text('Tester'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Placeholder (inchangé)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.color_lens_outlined),
              title: Text('Personnalisation (bientôt)'),
              subtitle: Text('Thème, palette, avatar…'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le profil ?'),
        content: const Text(
          'Cette action efface vos informations (nom, âge, taille, poids, objectif) '
              'et supprime l’avatar si présent.\n\n'
              'Aucune autre donnée de l’application n’est affectée.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _deletePreviousAvatarFile(); // supprime aussi l'image
      _avatarPath = null;

      await StorageService().saveProfile(UserProfile.empty());

      if (!mounted) return;
      _nomCtrl.clear();
      _ageCtrl.clear();
      _tailleCtrl.clear();
      _poidsCtrl.clear();
      _objectifCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil réinitialisé')),
      );
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la réinitialisation')),
      );
    }
  }
}
