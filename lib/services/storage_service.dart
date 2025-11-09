import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Modèle de profil utilisateur (simple JSON local, hors base Drift)
class UserProfile {
  final String nom;
  final int? age;       // en années
  final double? taille; // en cm
  final double? poids;  // en kg
  final String objectif;
  final String? avatarPath; // <- chemin local vers l’image (dans Documents/app)

  const UserProfile({
    required this.nom,
    required this.age,
    required this.taille,
    required this.poids,
    required this.objectif,
    required this.avatarPath,
  });

  factory UserProfile.empty() => const UserProfile(
    nom: '',
    age: null,
    taille: null,
    poids: null,
    objectif: '',
    avatarPath: null,
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    return UserProfile(
      nom: (json['nom'] as String?)?.trim() ?? '',
      age: parseInt(json['age']),
      taille: parseDouble(json['taille']),
      poids: parseDouble(json['poids']),
      objectif: (json['objectif'] as String?)?.trim() ?? '',
      avatarPath: (json['avatarPath'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'age': age,
    'taille': taille,
    'poids': poids,
    'objectif': objectif,
    'avatarPath': avatarPath,
  };

  UserProfile copyWith({
    String? nom,
    int? age,
    double? taille,
    double? poids,
    String? objectif,
    String? avatarPath,
  }) {
    return UserProfile(
      nom: nom ?? this.nom,
      age: age ?? this.age,
      taille: taille ?? this.taille,
      poids: poids ?? this.poids,
      objectif: objectif ?? this.objectif,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

/// Petit service pour lire/écrire un fichier JSON dans Documents
class StorageService {
  static final StorageService _instance = StorageService._internal();
  StorageService._internal();
  factory StorageService() => _instance;

  Future<File> _profileFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/user_profile.json');
  }

  Future<UserProfile> loadProfile() async {
    try {
      final file = await _profileFile();
      if (!await file.exists()) {
        return UserProfile.empty();
      }
      final txt = await file.readAsString();
      if (txt.trim().isEmpty) return UserProfile.empty();
      final jsonMap = json.decode(txt) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (_) {
      return UserProfile.empty();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final file = await _profileFile();
    final jsonTxt = const JsonEncoder.withIndent('  ').convert(profile.toJson());
    await file.writeAsString(jsonTxt, flush: true);
  }
}
