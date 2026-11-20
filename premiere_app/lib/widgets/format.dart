import 'package:intl/intl.dart';

/// Petits outils de mise en forme et de lecture des nombres « à la française ».

/// Affiche un nombre avec au plus une décimale et une virgule : 72,5.
String formaterDecimal(double valeur) => NumberFormat('#,##0.#', 'fr_FR').format(valeur);

/// Affiche un entier avec séparateur de milliers : 1 850.
String formaterEntier(num valeur) => NumberFormat('#,##0', 'fr_FR').format(valeur);

/// Lit un nombre saisi par l'utilisateur, en acceptant la virgule ou le point.
/// Renvoie `null` si la saisie n'est pas un nombre.
double? lireDecimal(String? texte) {
  if (texte == null) return null;
  final propre = texte.trim().replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(propre);
}
