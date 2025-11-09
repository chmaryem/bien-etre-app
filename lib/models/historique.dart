import 'package:flutter/foundation.dart';

@immutable
class HistoriqueHabitude {
  final int? id;
  final int habitudeId;
  final DateTime date; // normalisée (minuit local)
  final bool accompli;
  final String? note;

  const HistoriqueHabitude({
    this.id,
    required this.habitudeId,
    required this.date,
    this.accompli = false,
    this.note,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'habitudeId': habitudeId,
      'date': date.millisecondsSinceEpoch,
      'accompli': accompli ? 1 : 0,
      'note': note,
    };
  }

  factory HistoriqueHabitude.fromMap(Map<String, Object?> map) {
    return HistoriqueHabitude(
      id: map['id'] as int?,
      habitudeId: map['habitudeId'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      accompli: ((map['accompli'] as int?) ?? 0) == 1,
      note: map['note'] as String?,
    );
  }
}
