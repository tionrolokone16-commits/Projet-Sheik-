/// Répartition d'une assiette entre légumes, protéines et féculents.
/// Les trois parts sont des fractions dont la somme vaut 1.
class Portions {
  const Portions({
    required this.legumes,
    required this.proteines,
    required this.feculents,
  });

  final double legumes;
  final double proteines;
  final double feculents;

  /// Repère de « l'assiette équilibrée » : ½ légumes, ¼ protéines, ¼ féculents.
  static const equilibre = Portions(legumes: 0.5, proteines: 0.25, feculents: 0.25);

  /// Crée des portions à partir de valeurs quelconques, ramenées à un total de 1.
  factory Portions.normalisees(double legumes, double proteines, double feculents) {
    final total = legumes + proteines + feculents;
    if (total <= 0) return const Portions(legumes: 0, proteines: 0, feculents: 0);
    return Portions(
      legumes: legumes / total,
      proteines: proteines / total,
      feculents: feculents / total,
    );
  }

  double get total => legumes + proteines + feculents;
}

/// Une recette ivoirienne : le plat d'origine et sa version plus équilibrée.
///
/// Le plat d'origine n'est jamais « interdit » : il a toute sa place,
/// la version revisitée est simplement une autre façon de le savourer.
class Recette {
  const Recette({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.description,
    required this.astuces,
    required this.portions,
    this.ingredients = const [],
  });

  final String id;
  final String nom;
  final String emoji;

  /// Présentation du plat d'origine (recto de la carte).
  final String description;

  /// Petites adaptations pour une version plus équilibrée (verso).
  final List<String> astuces;

  /// Répartition indicative de l'assiette revisitée.
  final Portions portions;

  /// Principaux ingrédients et modes de cuisson (au singulier, en minuscules).
  /// Servent à signaler ce qu'un plan nutritionnel conseille d'éviter.
  final List<String> ingredients;
}
