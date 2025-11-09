import 'dart:math';
import '../models/sleep_model.dart';

class SleepAnalytics {
  
  // ==================== MÉTIER AVANCÉ 1: Régularité Horaire ====================
  // Analyse la régularité des horaires de coucher et réveil
  static Map<String, dynamic> regulariteHoraire(List<Sleep> sleeps) {
    if (sleeps.isEmpty) {
      return {
        'score': 0.0,
        'qualite': 'Aucune donnée',
        'ecartTypeCoucher': 0.0,
        'ecartTypeReveil': 0.0,
        'moyenneCoucher': '--:--',
        'moyenneReveil': '--:--',
      };
    }

    // Convertir les heures en minutes depuis minuit
    List<int> bedTimesMinutes = sleeps.map((s) {
      // Si l'heure est après minuit (ex: 23h), on considère que c'est le soir
      int minutes = s.bedTime.hour * 60 + s.bedTime.minute;
      // Ajustement pour les heures de coucher tardives (après minuit)
      if (s.bedTime.hour < 12) {
        minutes += 24 * 60; // Ajouter 24h si c'est le matin
      }
      return minutes;
    }).toList();

    List<int> wakeTimesMinutes = sleeps.map((s) {
      return s.wakeTime.hour * 60 + s.wakeTime.minute;
    }).toList();

    // Calculer la moyenne
    double moyenneCoucher = bedTimesMinutes.reduce((a, b) => a + b) / bedTimesMinutes.length;
    double moyenneReveil = wakeTimesMinutes.reduce((a, b) => a + b) / wakeTimesMinutes.length;

    // Calculer la variance puis l'écart type
    double varianceCoucher = bedTimesMinutes
        .map((m) => pow(m - moyenneCoucher, 2).toDouble())
        .reduce((a, b) => a + b) / bedTimesMinutes.length;
    
    double varianceReveil = wakeTimesMinutes
        .map((m) => pow(m - moyenneReveil, 2).toDouble())
        .reduce((a, b) => a + b) / wakeTimesMinutes.length;

    double ecartTypeCoucher = sqrt(varianceCoucher);
    double ecartTypeReveil = sqrt(varianceReveil);

    // Calcul du score de régularité (0-100)
    // Écart type de 0-30 min = Excellent (90-100)
    // Écart type de 30-60 min = Bon (70-89)
    // Écart type de 60-90 min = Moyen (50-69)
    // Écart type > 90 min = Faible (0-49)
    double ecartMoyen = (ecartTypeCoucher + ecartTypeReveil) / 2;
    double score = max(0, 100 - (ecartMoyen / 1.5));

    String qualite;
    if (score >= 85) {
      qualite = 'Excellente';
    } else if (score >= 70) {
      qualite = 'Bonne';
    } else if (score >= 50) {
      qualite = 'Moyenne';
    } else {
      qualite = 'Faible';
    }

    return {
      'score': score,
      'qualite': qualite,
      'ecartTypeCoucher': ecartTypeCoucher,
      'ecartTypeReveil': ecartTypeReveil,
      'moyenneCoucher': _minutesToTime(moyenneCoucher.toInt() % (24 * 60)),
      'moyenneReveil': _minutesToTime(moyenneReveil.toInt()),
    };
  }

  // ==================== MÉTIER AVANCÉ 2: Évolution Semaine ====================
  // Analyse l'évolution du sommeil sur la semaine
  static Map<String, dynamic> evolutionSemaine(List<Sleep> sleeps) {
    if (sleeps.isEmpty) {
      return {
        'dureeMoyenne': 0.0,
        'tendance': 'Aucune donnée',
        'joursAnalyses': 0,
        'meilleurJour': null,
        'pireJour': null,
        'progression': 0.0,
        'consistance': 'N/A',
      };
    }

    // Trier par date (du plus ancien au plus récent)
    List<Sleep> sortedSleeps = List.from(sleeps);
    sortedSleeps.sort((a, b) => a.date.compareTo(b.date));

    // Calculer la durée moyenne
    double dureeMoyenne = sortedSleeps
        .map((s) => s.calculerDureeNuit())
        .reduce((a, b) => a + b) / sortedSleeps.length;

    // Trouver le meilleur et le pire jour
    Sleep meilleurJour = sortedSleeps.reduce(
      (a, b) => a.calculerDureeNuit() > b.calculerDureeNuit() ? a : b
    );
    
    Sleep pireJour = sortedSleeps.reduce(
      (a, b) => a.calculerDureeNuit() < b.calculerDureeNuit() ? a : b
    );

    // Analyser la tendance (comparaison début/fin de semaine)
    int milieu = sortedSleeps.length ~/ 2;
    
    List<Sleep> premiereMotie = milieu > 0 
        ? sortedSleeps.sublist(0, milieu) 
        : sortedSleeps;
    
    List<Sleep> deuxiemeMotie = milieu > 0 && sortedSleeps.length > milieu
        ? sortedSleeps.sublist(milieu)
        : sortedSleeps;

    double moyenneDebut = premiereMotie.isEmpty 
        ? 0 
        : premiereMotie.map((s) => s.calculerDureeNuit()).reduce((a, b) => a + b) / premiereMotie.length;
    
    double moyenneFin = deuxiemeMotie.isEmpty 
        ? 0 
        : deuxiemeMotie.map((s) => s.calculerDureeNuit()).reduce((a, b) => a + b) / deuxiemeMotie.length;

    double progression = moyenneFin - moyenneDebut;

    String tendance;
    if (progression.abs() < 0.3) {
      tendance = 'Stable';
    } else if (progression > 0) {
      tendance = 'En amélioration';
    } else {
      tendance = 'En baisse';
    }

    // Calculer la consistance (écart type des durées)
    double variance = sortedSleeps
        .map((s) => pow(s.calculerDureeNuit() - dureeMoyenne, 2).toDouble())
        .reduce((a, b) => a + b) / sortedSleeps.length;
    
    double ecartType = sqrt(variance);
    
    String consistance;
    if (ecartType < 0.5) {
      consistance = 'Très régulier';
    } else if (ecartType < 1.0) {
      consistance = 'Régulier';
    } else if (ecartType < 1.5) {
      consistance = 'Variable';
    } else {
      consistance = 'Très variable';
    }

    return {
      'dureeMoyenne': dureeMoyenne,
      'tendance': tendance,
      'joursAnalyses': sortedSleeps.length,
      'meilleurJour': meilleurJour,
      'pireJour': pireJour,
      'progression': progression,
      'consistance': consistance,
      'ecartType': ecartType,
    };
  }

  // ==================== Statistiques Générales ====================
  static Map<String, dynamic> statistiquesGenerales(List<Sleep> sleeps) {
    if (sleeps.isEmpty) {
      return {
        'total': 0,
        'dureeMoyenne': 0.0,
        'dureeMin': 0.0,
        'dureeMax': 0.0,
        'totalHeures': 0.0,
        'objectif7h': 0.0, // Pourcentage de nuits >= 7h
        'objectif8h': 0.0, // Pourcentage de nuits >= 8h
      };
    }

    List<double> durees = sleeps.map((s) => s.calculerDureeNuit()).toList();
    
    double dureeMoyenne = durees.reduce((a, b) => a + b) / durees.length;
    double dureeMin = durees.reduce((a, b) => a < b ? a : b);
    double dureeMax = durees.reduce((a, b) => a > b ? a : b);
    double totalHeures = durees.reduce((a, b) => a + b);
    
    // Pourcentage de nuits atteignant les objectifs
    int nuitsPlus7h = durees.where((d) => d >= 7).length;
    int nuitsPlus8h = durees.where((d) => d >= 8).length;
    
    double objectif7h = (nuitsPlus7h / sleeps.length) * 100;
    double objectif8h = (nuitsPlus8h / sleeps.length) * 100;

    return {
      'total': sleeps.length,
      'dureeMoyenne': dureeMoyenne,
      'dureeMin': dureeMin,
      'dureeMax': dureeMax,
      'totalHeures': totalHeures,
      'objectif7h': objectif7h,
      'objectif8h': objectif8h,
    };
  }

  // ==================== Fonctions utilitaires ====================
  
  // Convertir des minutes en format HH:MM
  static String _minutesToTime(int minutes) {
    int hours = (minutes ~/ 60) % 24;
    int mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  // Obtenir les données pour un graphique hebdomadaire
  static List<Map<String, dynamic>> getDonneesGraphique(List<Sleep> sleeps) {
    if (sleeps.isEmpty) return [];
    
    return sleeps.map((sleep) => {
      'date': sleep.date,
      'duree': sleep.calculerDureeNuit(),
      'qualite': sleep.qualifierSommeilParDuree(),
    }).toList();
  }

  // Recommandations basées sur les données
  static List<String> getRecommandations(List<Sleep> sleeps) {
    if (sleeps.isEmpty) {
      return ['Commencez à enregistrer vos nuits de sommeil pour obtenir des recommandations personnalisées.'];
    }

    List<String> recommandations = [];
    
    var stats = statistiquesGenerales(sleeps);
    var regularite = regulariteHoraire(sleeps);
    
    // Recommandation sur la durée
    if (stats['dureeMoyenne'] < 7) {
      recommandations.add('⏰ Essayez d\'augmenter votre temps de sommeil. Visez au moins 7-8 heures par nuit.');
    } else if (stats['dureeMoyenne'] > 9) {
      recommandations.add('⚠️ Vous dormez peut-être trop. Consultez un professionnel si vous ressentez de la fatigue.');
    }
    
    // Recommandation sur la régularité
    if (regularite['score'] < 70) {
      recommandations.add('📅 Essayez de vous coucher et de vous réveiller à heures fixes, même le weekend.');
    }
    
    // Recommandation sur l'objectif
    if (stats['objectif7h'] < 70) {
      recommandations.add('🎯 Objectif: Atteignez 7h de sommeil au moins 5 nuits sur 7.');
    }

    if (recommandations.isEmpty) {
      recommandations.add('✅ Excellent travail! Continuez à maintenir ces bonnes habitudes de sommeil.');
    }
    
    return recommandations;
  }
}