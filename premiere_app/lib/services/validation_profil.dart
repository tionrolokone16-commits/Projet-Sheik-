import '../widgets/format.dart';
import 'calculs_service.dart';

/// Règles de validation des champs du profil, partagées entre
/// l'onboarding et l'écran de modification du profil.
///
/// Chaque fonction renvoie `null` si la saisie est correcte,
/// sinon un message court et bienveillant.
class ValidationProfil {
  ValidationProfil._();

  static String? prenom(String? texte) =>
      (texte == null || texte.trim().isEmpty)
          ? 'Comment veux-tu qu\'on t\'appelle ?'
          : null;

  static String? age(String? texte) {
    final age = lireDecimal(texte);
    if (age == null) return 'Merci d\'indiquer ton âge';
    if (age < 18) return 'Forme Douce est pensée pour les adultes (18 ans et plus)';
    if (age > 110) return 'Merci de vérifier ton âge';
    return null;
  }

  static String? taille(String? texte) => _nombre(texte, 120, 230, 'cm');

  static String? poids(String? texte) => _nombre(texte, 35, 300, 'kg');

  /// Le poids objectif doit être un poids valide, inférieur ou égal au départ.
  /// (Le contrôle de l'IMC se fait à part, avec un message doux : voir
  /// [objectifTropBas].)
  static String? objectif(String? texte, String? texteDepart) {
    final erreur = poids(texte);
    if (erreur != null) return erreur;
    final depart = lireDecimal(texteDepart);
    if (depart != null && lireDecimal(texte)! > depart) {
      return 'L\'objectif doit être inférieur ou égal au poids de départ';
    }
    return null;
  }

  /// Vrai si l'objectif saisi correspond à un IMC inférieur à 18,5.
  static bool objectifTropBas(String texteTaille, String texteObjectif) {
    final taille = lireDecimal(texteTaille);
    final objectif = lireDecimal(texteObjectif);
    return taille != null &&
        objectif != null &&
        taille > 0 &&
        !CalculsService.objectifAcceptable(objectif, taille);
  }

  static String? _nombre(String? texte, double min, double max, String unite) {
    final valeur = lireDecimal(texte);
    if (valeur == null) return 'Merci d\'indiquer un nombre';
    if (valeur < min || valeur > max) {
      return 'Entre ${formaterDecimal(min)} et ${formaterDecimal(max)} $unite';
    }
    return null;
  }
}
