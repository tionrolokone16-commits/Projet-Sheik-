import 'dart:math' as math;

import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/profil.dart';
import 'calculs_service.dart';

/// Calories dépensées dans une journée (estimations).
class DepenseJour {
  const DepenseJour({
    required this.base,
    required this.quotidien,
    required this.activites,
    required this.pas,
    required this.sommeil,
  });

  /// Ton corps au repos sur 24 h (métabolisme de base, nuit comprise).
  final int base;

  /// Vie quotidienne (se lever, marcher un peu, cuisiner…).
  final int quotidien;

  /// Activités et séance, en plus du repos.
  final int activites;

  /// Pas notés (hors marches déjà notées comme activité).
  final int pas;

  /// Part de la base utilisée pendant la nuit (déjà comprise dans [base]).
  final int sommeil;

  int get mouvement => activites + pas;
  int get total => base + quotidien + mouvement;
}

/// Règles de calcul des calories dépensées.
///
/// - Repos : métabolisme de base (Mifflin-St Jeor) ;
/// - vie quotidienne : +20 % du métabolisme de base ;
/// - activité : (MET − 1) × poids (kg) × durée (h), c'est-à-dire en plus du repos ;
/// - pas : ≈ 0,0005 kcal par pas et par kg ;
/// - nuit : métabolisme de base / 24 × heures × 0,95.
class DepenseService {
  DepenseService._();

  /// Part de la vie quotidienne (activité légère), en plus du repos.
  static const partQuotidienne = 0.2;

  /// Calories par pas et par kg.
  static const kcalParPasParKg = 0.0005;

  /// Pas estimés par minute de marche (pour ne pas compter deux fois).
  static const pasParMinuteDeMarche = 100;

  /// Durée retenue pour une séance cochée « faite » sans activité notée.
  static const minutesSeanceCochee = 20;

  /// Intensité (MET) de chaque type d'activité.
  static double met(TypeActivite t) => switch (t) {
    TypeActivite.marche => 3.5,
    TypeActivite.course => 8,
    TypeActivite.velo => 6,
    TypeActivite.natation => 6,
    TypeActivite.yoga => 2.5,
    TypeActivite.renforcement => 4,
    TypeActivite.danse => 5,
    TypeActivite.autre => 3.5,
  };

  /// Métabolisme de base du profil, au poids donné.
  static double metabolismeBase(Profil profil, double poidsKg) => CalculsService.metabolismeBase(
    poidsKg: poidsKg,
    tailleCm: profil.tailleCm,
    age: profil.age,
    sexe: profil.sexe,
  );

  /// Calories d'une activité, en plus du repos.
  static int kcalActivite(TypeActivite type, int minutes, double poidsKg) =>
      ((met(type) - 1) * poidsKg * minutes / 60).round();

  /// Calories des pas.
  static int kcalPas(int pas, double poidsKg) => (pas * poidsKg * kcalParPasParKg).round();

  /// Calories utilisées pendant la nuit.
  static int kcalSommeil(double heures, double metabolismeBase) =>
      (metabolismeBase / 24 * heures * 0.95).round();

  /// Dépense estimée d'une journée.
  static DepenseJour calculer({
    required Profil profil,
    required double poidsKg,
    required JourHabitudes jour,
    required List<Activite> activitesDuJour,
  }) {
    final mb = metabolismeBase(profil, poidsKg);
    var activites = activitesDuJour.fold<int>(
      0,
      (s, a) => s + kcalActivite(a.type, a.dureeMinutes, poidsKg),
    );
    // Séance cochée sans activité notée : une séance de renforcement de 20 min.
    if (jour.seanceFaite && activitesDuJour.isEmpty) {
      activites += kcalActivite(TypeActivite.renforcement, minutesSeanceCochee, poidsKg);
    }
    // Les pas des marches déjà notées ne comptent pas deux fois.
    final minutesMarche = activitesDuJour
        .where((a) => a.type == TypeActivite.marche)
        .fold<int>(0, (s, a) => s + a.dureeMinutes);
    final pasRestants = math.max(0, (jour.pas ?? 0) - minutesMarche * pasParMinuteDeMarche);

    return DepenseJour(
      base: mb.round(),
      quotidien: (mb * partQuotidienne).round(),
      activites: activites,
      pas: kcalPas(pasRestants, poidsKg),
      sommeil: jour.sommeilHeures == null ? 0 : kcalSommeil(jour.sommeilHeures!, mb),
    );
  }
}
