import '../models/profil.dart';
import '../widgets/format.dart';

/// Messages bienveillants affichés dans l'application.
///
/// Règle d'or : jamais de culpabilisation ni de mot comme « échec ».
/// Une hausse du poids est présentée comme une variation normale.
class MessagesService {
  MessagesService._();

  /// Message sur l'écart entre les deux dernières pesées.
  /// [ecartKg] = poids actuel − poids précédent (`null` s'il n'y a qu'une pesée).
  static String variation(double? ecartKg) {
    if (ecartKg == null) {
      return 'Première pesée enregistrée 🌱 Chaque nouvelle mesure '
          'dessinera ta tendance.';
    }
    final ecart = formaterDecimal(ecartKg.abs());
    if (ecartKg <= -0.05) {
      return '−$ecart kg depuis la dernière pesée. Bravo pour ta régularité 🌿';
    }
    if (ecartKg >= 0.05) {
      return '+$ecart kg depuis la dernière pesée. C\'est tout à fait normal : '
          'l\'eau, les repas ou le sommeil font varier le poids d\'un jour '
          'à l\'autre. C\'est la tendance sur plusieurs semaines qui compte 💚';
    }
    return 'Poids stable depuis la dernière pesée. Ta constance est une force ✨';
  }

  /// Message sur le chemin parcouru depuis le poids de départ.
  static String progression(Profil profil, double poidsActuelKg) {
    if (poidsActuelKg <= profil.poidsObjectifKg) {
      return 'Objectif atteint 🎉 Prends le temps de savourer ce chemin.';
    }
    final perdu = profil.poidsDepartKg - poidsActuelKg;
    if (perdu >= 0.1) {
      return 'Déjà ${formaterDecimal(perdu)} kg de chemin parcouru depuis '
          'le départ 🌱';
    }
    return 'Chaque jour où tu prends soin de toi compte. La tendance se '
        'construit doucement, sur plusieurs semaines 💚';
  }

  /// Part du chemin parcouru vers l'objectif, entre 0 et 1.
  static double fractionParcourue(Profil profil, double poidsActuelKg) {
    final total = profil.poidsDepartKg - profil.poidsObjectifKg;
    if (total <= 0) return 1;
    return ((profil.poidsDepartKg - poidsActuelKg) / total).clamp(0.0, 1.0);
  }
}
