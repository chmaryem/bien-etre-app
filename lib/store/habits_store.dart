// lib/store/habits_store.dart
import '../models/habitude.dart';
import '../models/historique.dart';

/// Contrat unique utilisé par l'UI. L’implémentation actuelle = SqfliteHabitsStore.
abstract class HabitsStore {
  // ---------- Cycle de vie ----------
  Future<void> init();
  Future<void> close();

  // ---------- Habitudes ----------
  Future<List<Habitude>> getAllHabitudes();
  Future<Habitude?> getHabitudeById(int id);
  Future<List<Habitude>> getHabitudesByCategorie(int categorieId);

  Future<int> createHabitude(Habitude habitude);
  Future<bool> updateHabitude(Habitude habitude);
  Future<int> deleteHabitude(int id);

  // ---------- Historique ----------
  Future<int> marquerHabitudeAccomplie(int habitudeId, DateTime date);
  Future<bool> toggleAccompliAujourdHui(int habitudeId);

  Future<List<HistoriqueHabitude>> getHistoriqueByHabitude(int habitudeId);
  Future<bool> isHabitudeAccomplie(int habitudeId, DateTime date);

  // ---------- Utilitaires ----------
  Future<int> calculerStreak(int habitudeId);
}
