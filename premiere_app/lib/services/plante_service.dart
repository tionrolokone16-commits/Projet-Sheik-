import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import 'habitudes_service.dart';
import 'stockage_service.dart';

/// Étapes de croissance de la plante, avec le nombre de « gouttes »
/// (habitudes prises en soin) nécessaires pour les atteindre.
enum StadePlante {
  graine('Graine', 0, 'Une petite graine pleine de promesses 🌰'),
  pousse('Pousse', 3, 'Une pousse sort de terre, bravo 🌱'),
  jeunePlante('Jeune plante', 10, 'Tes feuilles se déploient 🌿'),
  bouton('Bouton', 20, 'Un bouton se forme… ça arrive 🌷'),
  fleur('Première fleur', 35, 'Ta première fleur est éclose 🌸'),
  floraison('En pleine floraison', 55, 'Ta plante est en pleine floraison 💐'),
  jardin('Jardin fleuri', 80, 'Un vrai jardin fleuri, quelle constance ✨');

  const StadePlante(this.libelle, this.seuil, this.message);
  final String libelle;

  /// Nombre de gouttes à partir duquel ce stade est atteint.
  final int seuil;
  final String message;

  StadePlante? get suivant =>
      index + 1 < StadePlante.values.length ? StadePlante.values[index + 1] : null;
}

/// Calcul de la croissance de la plante.
///
/// Règles bien-être :
/// - la plante ne grandit QUE grâce aux habitudes (eau, sommeil, mouvement,
///   repas), jamais en fonction du poids ;
/// - le total ne fait qu'augmenter : elle ne fane jamais, au pire elle attend.
class PlanteService {
  PlanteService._();

  /// Total des habitudes prises en soin, tous jours confondus.
  static int gouttes({
    required Map<String, JourHabitudes> journal,
    required List<Activite> activites,
    required int objectifVerres,
  }) {
    // Toutes les journées où quelque chose a été noté.
    final jours = {...journal.keys, for (final a in activites) cleDuJour(a.date)};
    var total = 0;
    for (final cle in jours) {
      total += HabitudesService.tenues(
        journal[cle] ?? const JourHabitudes(),
        activitesDuJour: activites.where((a) => cleDuJour(a.date) == cle).toList(),
        objectifVerres: objectifVerres,
      ).length;
    }
    return total;
  }

  static StadePlante stade(int gouttes) =>
      StadePlante.values.lastWhere((s) => gouttes >= s.seuil);

  /// Croissance continue entre 0 (graine) et 6 (jardin) : la partie entière
  /// est le stade, la partie décimale l'avancée vers le stade suivant.
  static double niveau(int gouttes) {
    final s = stade(gouttes);
    final suivant = s.suivant;
    if (suivant == null) return s.index.toDouble();
    return s.index + (gouttes - s.seuil) / (suivant.seuil - s.seuil);
  }

  /// Fleurs supplémentaires au-delà de la floraison (une de plus
  /// toutes les 15 gouttes, jusqu'à 6).
  static int fleursBonus(int gouttes) {
    if (gouttes < StadePlante.floraison.seuil) return 0;
    final bonus = 1 + (gouttes - StadePlante.floraison.seuil) ~/ 15;
    return bonus > 6 ? 6 : bonus;
  }

  /// Message de la plante, selon les habitudes du jour.
  static String message(int gouttes, {required int habitudesAujourdhui}) {
    if (habitudesAujourdhui == 0) {
      return gouttes == 0
          ? 'Prends soin d\'une habitude et ta graine commencera à pousser 🌱'
          : 'Ta plante attend patiemment ton prochain petit geste 🌱';
    }
    final suivant = stade(gouttes).suivant;
    if (suivant == null) return 'Ton jardin continue de fleurir grâce à toi ✨';
    final reste = suivant.seuil - gouttes;
    return 'Encore $reste ${reste > 1 ? 'gouttes' : 'goutte'} avant : ${suivant.libelle.toLowerCase()} 💧';
  }
}
