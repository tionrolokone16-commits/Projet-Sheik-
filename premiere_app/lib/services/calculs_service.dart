import 'dart:math' as math;

import '../models/profil.dart';

/// Résultat du calcul d'objectif calorique indicatif.
class ObjectifCalorique {
  const ObjectifCalorique({
    required this.metabolismeBase,
    required this.depenseJournaliere,
    required this.kcalParJour,
    required this.perteHebdoKg,
    required this.plancherApplique,
  });

  /// Métabolisme de base (Mifflin-St Jeor), en kcal/jour.
  final double metabolismeBase;

  /// Dépense énergétique journalière estimée (avec l'activité), en kcal/jour.
  final double depenseJournaliere;

  /// Apport indicatif proposé, en kcal/jour (jamais moins de 1200).
  final int kcalParJour;

  /// Perte de poids hebdomadaire correspondante, en kg (entre 0 et 0,5).
  final double perteHebdoKg;

  /// Vrai si le minimum de 1200 kcal a limité le déficit proposé.
  final bool plancherApplique;
}

/// Calculs santé : IMC, métabolisme, objectif calorique.
///
/// Ces calculs donnent des **indications générales**, pas un avis médical.
class CalculsService {
  CalculsService._(); // Classe utilitaire : pas d'instance.

  /// Mention à afficher à côté de tout chiffre calorique.
  static const mentionMedicale = 'Indications générales, pas un avis médical.';

  /// En dessous de cet IMC, on parle de maigreur : l'objectif est refusé.
  static const imcMinimum = 18.5;

  /// Apport minimal jamais dépassé à la baisse.
  static const kcalMinimum = 1200;

  /// Bornes de perte hebdomadaire saine.
  static const perteHebdoMinKg = 0.25;
  static const perteHebdoMaxKg = 0.5;

  /// Énergie approximative contenue dans 1 kg de masse corporelle.
  static const kcalParKg = 7700.0;

  /// Indice de masse corporelle = poids (kg) / taille (m)².
  static double imc(double poidsKg, double tailleCm) {
    final tailleM = tailleCm / 100;
    return poidsKg / (tailleM * tailleM);
  }

  /// Poids le plus bas accepté comme objectif pour une taille donnée
  /// (correspond à un IMC de 18,5), arrondi au dixième supérieur.
  static double poidsObjectifMinimal(double tailleCm) {
    final tailleM = tailleCm / 100;
    return (imcMinimum * tailleM * tailleM * 10).ceil() / 10;
  }

  /// Vrai si le poids objectif donne un IMC d'au moins 18,5.
  static bool objectifAcceptable(double poidsObjectifKg, double tailleCm) =>
      imc(poidsObjectifKg, tailleCm) >= imcMinimum;

  /// Métabolisme de base selon Mifflin-St Jeor :
  /// 10 × poids (kg) + 6,25 × taille (cm) − 5 × âge + constante (sexe).
  static double metabolismeBase({
    required double poidsKg,
    required double tailleCm,
    required int age,
    required Sexe sexe,
  }) => 10 * poidsKg + 6.25 * tailleCm - 5 * age + sexe.constanteMifflin;

  /// Calcule l'objectif calorique indicatif à partir du profil et du poids actuel.
  ///
  /// On vise d'abord une perte de 0,5 kg/semaine. Si cela ferait passer
  /// l'apport sous 1200 kcal, on réduit le déficit (perte plus lente).
  /// Si le poids objectif est déjà atteint, on propose l'entretien.
  static ObjectifCalorique objectifCalorique(Profil profil, {double? poidsActuelKg}) {
    final poids = poidsActuelKg ?? profil.poidsDepartKg;
    final mb = metabolismeBase(
      poidsKg: poids,
      tailleCm: profil.tailleCm,
      age: profil.age,
      sexe: profil.sexe,
    );
    final dej = mb * profil.niveauActivite.coefficient;

    // Objectif atteint : pas de déficit, on maintient.
    final perteVisee = poids <= profil.poidsObjectifKg ? 0.0 : perteHebdoMaxKg;
    final deficitVise = perteVisee * kcalParKg / 7; // kcal par jour

    // On ne descend jamais sous 1200 kcal.
    final apportBrut = dej - deficitVise;
    final apport = math.max(kcalMinimum.toDouble(), apportBrut);
    final plancher = apportBrut < kcalMinimum && perteVisee > 0;

    // Perte réellement obtenue avec cet apport (jamais négative).
    final perteReelle = math.max(0.0, (dej - apport) * 7 / kcalParKg);

    return ObjectifCalorique(
      metabolismeBase: mb,
      depenseJournaliere: dej,
      kcalParJour: apport.round(),
      perteHebdoKg: double.parse(perteReelle.toStringAsFixed(2)),
      plancherApplique: plancher,
    );
  }
}
