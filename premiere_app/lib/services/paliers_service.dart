import 'dart:math' as math;

import '../models/pesee.dart';
import '../models/profil.dart';

/// Un palier sur le chemin vers l'objectif.
class Palier {
  const Palier({
    required this.numero,
    required this.poidsKg,
    required this.estObjectif,
    this.atteintLe,
  });

  /// Numéro du palier, à partir de 1.
  final int numero;
  final double poidsKg;

  /// Vrai pour le dernier palier (le poids objectif).
  final bool estObjectif;

  /// Date à laquelle la tendance a atteint ce palier (`null` sinon).
  final DateTime? atteintLe;

  bool get atteint => atteintLe != null;
}

/// État du chemin : paliers, position actuelle et stabilisation.
class EtatChemin {
  const EtatChemin({
    required this.paliers,
    required this.dernierAtteint,
    required this.finStabilisation,
    required this.avancement,
  });

  final List<Palier> paliers;

  /// Index du dernier palier atteint (-1 si aucun).
  final int dernierAtteint;

  /// Fin de la phase de stabilisation en cours, ou `null` s'il n'y en a pas.
  final DateTime? finStabilisation;

  /// Avancée (0 à 1) entre le dernier palier atteint et le suivant.
  final double avancement;

  bool get enStabilisation => finStabilisation != null;
  bool get objectifAtteint => paliers.isNotEmpty && paliers.last.atteint;

  /// Jours restants de stabilisation (au moins 1 pendant la phase).
  int joursStabilisationRestants(DateTime maintenant) => finStabilisation == null
      ? 0
      : math.max(1, (finStabilisation!.difference(maintenant).inHours / 24).ceil());
}

/// Calcul du chemin des paliers.
///
/// - Un palier tous les 5 % du poids de départ, jusqu'à l'objectif.
/// - Après chaque palier : 2 semaines de stabilisation conseillées, pour
///   laisser le corps s'habituer à son nouvel équilibre.
/// - Un palier est atteint quand la TENDANCE (moyenne sur 7 jours) y arrive :
///   une pesée isolée ne suffit pas, et une petite remontée ne retire
///   jamais un palier déjà atteint.
class PaliersService {
  PaliersService._();

  static const pourcentagePalier = 0.05;
  static const dureeStabilisation = Duration(days: 14);

  /// Poids de chaque palier, du premier jusqu'à l'objectif inclus.
  static List<double> poidsPaliers(Profil profil) {
    final pas = profil.poidsDepartKg * pourcentagePalier;
    final poids = <double>[];
    var w = profil.poidsDepartKg - pas;
    // On évite un tout petit dernier palier juste avant l'objectif.
    while (w > profil.poidsObjectifKg + pas * 0.3) {
      poids.add(double.parse(w.toStringAsFixed(1)));
      w -= pas;
    }
    poids.add(profil.poidsObjectifKg);
    return poids;
  }

  /// Moyenne des pesées sur les 7 jours se terminant à [date].
  static double tendance(List<Pesee> pesees, DateTime date) {
    final debut = date.subtract(const Duration(days: 6));
    final fenetre = pesees
        .where((p) => !p.date.isBefore(debut) && !p.date.isAfter(date))
        .map((p) => p.poidsKg)
        .toList();
    return fenetre.reduce((a, b) => a + b) / fenetre.length;
  }

  static EtatChemin calculer(Profil profil, List<Pesee> pesees, {DateTime? maintenant}) {
    final n = maintenant ?? DateTime.now();
    final poids = poidsPaliers(profil);

    // Date à laquelle la tendance a atteint chaque palier (dans l'ordre).
    final atteints = <DateTime>[];
    for (final cible in poids) {
      DateTime? date;
      for (final p in pesees) {
        if (atteints.isNotEmpty && p.date.isBefore(atteints.last)) continue;
        if (tendance(pesees, p.date) <= cible + 0.05) {
          date = p.date;
          break;
        }
      }
      if (date == null) break; // Les paliers suivants ne sont pas atteints.
      atteints.add(date);
    }

    final paliers = [
      for (var i = 0; i < poids.length; i++)
        Palier(
          numero: i + 1,
          poidsKg: poids[i],
          estObjectif: i == poids.length - 1,
          atteintLe: i < atteints.length ? atteints[i] : null,
        ),
    ];
    final dernier = atteints.length - 1;

    // Stabilisation : dans les 14 jours qui suivent un palier (sauf l'objectif).
    DateTime? fin;
    if (dernier >= 0 && dernier < paliers.length - 1) {
      final f = atteints[dernier].add(dureeStabilisation);
      if (n.isBefore(f)) fin = f;
    }

    // Avancée vers le palier suivant, d'après la tendance actuelle.
    var avancement = 0.0;
    if (dernier < paliers.length - 1 && pesees.isNotEmpty) {
      final depuis = dernier >= 0 ? paliers[dernier].poidsKg : profil.poidsDepartKg;
      final vers = paliers[dernier + 1].poidsKg;
      final actuel = tendance(pesees, pesees.last.date);
      avancement = ((depuis - actuel) / (depuis - vers)).clamp(0.0, 1.0);
    }

    return EtatChemin(
      paliers: paliers,
      dernierAtteint: dernier,
      finStabilisation: fin,
      avancement: avancement,
    );
  }
}
