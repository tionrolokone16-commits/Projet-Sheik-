import '../models/jour_habitudes.dart';
import '../models/recette.dart';

/// Conseils doux autour de l'assiette.
///
/// On ne juge jamais un repas : on souligne ce qui est bien,
/// et on propose au plus une petite idée pour la prochaine fois.
class AssietteService {
  AssietteService._();

  /// Libellés des curseurs de quantité (0 à 4).
  static const quantites = ['Aucun', 'Un peu', 'Moyen', 'Beaucoup', 'Énormément'];

  /// Repas proposé par défaut selon l'heure.
  static Repas repasSelonHeure(DateTime moment) {
    final h = moment.hour;
    if (h < 10) return Repas.petitDejeuner;
    if (h < 15) return Repas.dejeuner;
    if (h < 18) return Repas.collation;
    return Repas.diner;
  }

  /// Seuil à partir duquel le repas compte pour le défi « légumes ».
  static const seuilLegumesDefi = 0.25;

  /// Message principal, toujours positif.
  static String message(Portions p) {
    if (p.total <= 0) return 'Indique ce qu\'il y a dans ton assiette 🍽️';
    if (p.legumes >= 0.45) return 'Superbe place pour les légumes 🥦✨';
    if (p.legumes >= seuilLegumesDefi) return 'Joli équilibre, les légumes sont bien là 🌿';
    return 'Bon appétit ! Savoure ce repas en prenant ton temps 💗';
  }

  /// Une petite idée facultative pour la prochaine fois (ou `null`).
  static String? idee(Portions p) {
    if (p.total <= 0) return null;
    if (p.legumes < seuilLegumesDefi) {
      return 'Idée pour une prochaine fois : quelques crudités ou légumes '
          'en plus (carotte, haricots verts, gombo…), si tu en as envie.';
    }
    if (p.proteines < 0.1) {
      return 'Idée : une petite source de protéines (poisson, poulet, viande maigre…) '
          'aide à tenir jusqu\'au prochain repas.';
    }
    return null;
  }
}
