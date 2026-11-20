import '../models/repas_photo.dart';
import 'ingredients_service.dart';

/// Calories des repas.
///
/// Il n'y a AUCUNE valeur toute faite par plat : les calories d'un repas
/// viennent uniquement des ingrédients et des grammes saisis (voir
/// IngredientsService), ou d'un total saisi à la main (étiquette…).
/// Un repas sans ingrédients a des calories « à compléter ».
class CaloriesService {
  CaloriesService._();

  /// Calories d'un repas, ou `null` si elles restent à compléter.
  static int? kcalRepas(RepasPhoto r) {
    if (r.kcalManuel != null) return r.kcalManuel;
    if (r.composition.isNotEmpty) return IngredientsService.kcal(r.composition);
    return null;
  }

  /// Affiche une valeur : « ≈ 650 kcal ».
  static String formater(int kcal) {
    final texte = kcal.abs().toString();
    final morceaux = <String>[];
    for (var fin = texte.length; fin > 0; fin -= 3) {
      morceaux.insert(0, texte.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
    }
    return '≈\u00a0${kcal < 0 ? '-' : ''}${morceaux.join('\u00a0')}\u00a0kcal';
  }
}
