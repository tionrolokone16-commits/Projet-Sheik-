/// Groupe d'un ingrédient (pour l'assiette légumes / protéines / féculents).
enum GroupeIngredient {
  feculent('Féculents', '🍚'),
  proteine('Protéines', '🐟'),
  legume('Légumes', '🥬'),
  matiereGrasse('Sauces et huiles', '🫙'),
  fruit('Fruits', '🍊'),
  boisson('Boissons et sucres', '🥤');

  const GroupeIngredient(this.libelle, this.emoji);
  final String libelle;
  final String emoji;
}

/// Un ingrédient de base, avec ses calories pour 100 g.
class Ingredient {
  const Ingredient({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.groupe,
    required this.kcal100g,
    required this.portionGrammes,
  });

  final String id;
  final String nom;
  final String emoji;
  final GroupeIngredient groupe;

  /// Calories pour 100 g (aliment tel qu'il est mangé : cuit, frit…).
  final int kcal100g;

  /// Portion habituelle proposée par défaut, en grammes.
  final int portionGrammes;

  /// Calories pour un nombre de grammes.
  int kcal(int grammes) => (kcal100g * grammes / 100).round();
}

/// Un ingrédient d'un plat composé, avec son poids.
class Composant {
  const Composant({required this.idIngredient, required this.grammes});

  final String idIngredient;
  final int grammes;

  Composant avecGrammes(int g) => Composant(idIngredient: idIngredient, grammes: g);

  Map<String, dynamic> toJson() => {'id': idIngredient, 'g': grammes};

  factory Composant.fromJson(Map<String, dynamic> json) =>
      Composant(idIngredient: json['id'] as String, grammes: (json['g'] as num).toInt());
}
