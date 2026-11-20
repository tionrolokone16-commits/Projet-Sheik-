import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/pesee.dart';
import '../models/profil.dart';
import 'calculs_service.dart';
import 'depense_service.dart';
import 'stockage_service.dart';

/// Calories d'une journée : consommées, dépensées et objectif.
class JourCalories {
  const JourCalories({
    required this.date,
    required this.consomme,
    required this.depense,
    required this.objectif,
    required this.repasNotes,
  });

  final DateTime date;
  final int consomme;
  final int depense;
  final int objectif;

  /// Vrai si au moins un repas a été noté (sinon « consommé » est inconnu).
  final bool repasNotes;
}

/// Évolution des calories jour par jour (estimations).
class EvolutionService {
  EvolutionService._();

  /// Poids connu à une date : la dernière pesée de ce jour ou d'avant,
  /// sinon le poids de départ du profil.
  static double poidsA(DateTime date, List<Pesee> pesees, Profil profil) {
    final fin = DateTime(date.year, date.month, date.day + 1);
    double? poids;
    for (final p in pesees) {
      if (p.date.isBefore(fin)) poids = p.poidsKg;
    }
    return poids ?? profil.poidsDepartKg;
  }

  /// Les [nombre] derniers jours, du plus ancien au plus récent (aujourd'hui inclus).
  static List<JourCalories> derniersJours({
    required int nombre,
    required DateTime maintenant,
    required Profil profil,
    required List<Pesee> pesees,
    required Map<String, JourHabitudes> journal,
    required List<Activite> activites,
    required int Function(DateTime) kcalConsommees,
    required bool Function(DateTime) aDesRepas,
  }) {
    final peseesTriees = [...pesees]..sort((a, b) => a.date.compareTo(b.date));
    return [
      for (var i = nombre - 1; i >= 0; i--)
        () {
          final d = DateTime(maintenant.year, maintenant.month, maintenant.day - i);
          final poids = poidsA(d, peseesTriees, profil);
          return JourCalories(
            date: d,
            consomme: kcalConsommees(d),
            depense: DepenseService.calculer(
              profil: profil,
              poidsKg: poids,
              jour: journal[cleDuJour(d)] ?? const JourHabitudes(),
              activitesDuJour: [
                for (final a in activites)
                  if (cleDuJour(a.date) == cleDuJour(d)) a,
              ],
            ).total,
            objectif: CalculsService.objectifCalorique(profil, poidsActuelKg: poids).kcalParJour,
            repasNotes: aDesRepas(d),
          );
        }(),
    ];
  }

  /// Moyenne des calories consommées sur les jours où des repas sont notés
  /// (les jours sans repas noté ne comptent pas : ils ne sont pas « à zéro »).
  static int? moyenneConsommee(List<JourCalories> jours) {
    final notes = jours.where((j) => j.repasNotes).toList();
    if (notes.isEmpty) return null;
    return (notes.fold<int>(0, (s, j) => s + j.consomme) / notes.length).round();
  }
}
