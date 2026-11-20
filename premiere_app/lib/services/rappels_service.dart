import '../models/jour_habitudes.dart';
import '../models/reglages.dart';

/// Rappels doux aux heures de repas.
///
/// Une application web ne peut pas envoyer de notification quand elle est
/// fermée (il faudrait un serveur) : le rappel s'affiche donc sur l'accueil,
/// à l'ouverture de l'application, pendant les 2 h 30 qui suivent l'heure
/// du repas — seulement si ce repas n'est pas encore noté et que le rappel
/// n'a pas été mis de côté (« Plus tard »).
class RappelsService {
  RappelsService._();

  /// Durée pendant laquelle un rappel reste proposé après l'heure du repas.
  static const fenetreMinutes = 150;

  /// Heure du rappel de chaque repas, en minutes depuis minuit.
  static Map<Repas, int> heures(Reglages r) => {
    Repas.petitDejeuner: r.heurePetitDejeuner,
    Repas.dejeuner: r.heureDejeuner,
    Repas.diner: r.heureDiner,
  };

  /// Repas à rappeler maintenant, ou `null`.
  static Repas? rappelActuel({
    required DateTime maintenant,
    required Reglages reglages,
    required Set<Repas> dejaNotes,
    required Set<Repas> misDeCote,
  }) {
    if (!reglages.rappelsRepas) return null;
    final minutes = maintenant.hour * 60 + maintenant.minute;
    for (final MapEntry(key: repas, value: heure) in heures(reglages).entries) {
      // Écart depuis l'heure du repas (calcul « modulo 24 h » pour minuit).
      final ecart = (minutes - heure) % (24 * 60);
      if (ecart < fenetreMinutes && !dejaNotes.contains(repas) && !misDeCote.contains(repas)) {
        return repas;
      }
    }
    return null;
  }

  /// Message du rappel : une invitation, jamais une obligation.
  static String message(Repas repas) => switch (repas) {
    Repas.petitDejeuner => 'Bonjour ! Tu veux noter ton petit-déjeuner ? 🌸',
    Repas.dejeuner => 'Tu veux noter ton déjeuner ? 🌸',
    Repas.diner => 'Tu veux noter ton dîner ? 🌙',
    Repas.collation => 'Tu veux noter ton en-cas ? 🍊',
  };

  /// « 13:00 » à partir de 780 minutes.
  static String formaterHeure(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
