import '../models/ingredient.dart';
import '../models/recette.dart';
import 'plan_service.dart';

/// Base d'ingrédients pour composer un plat au gramme près.
///
/// Calories pour 100 g d'aliment tel qu'il est mangé (cuit, frit…), d'après
/// des tables de composition courantes. Ce sont des valeurs moyennes :
/// une recette maison peut varier.
class IngredientsService {
  IngredientsService._();

  static Ingredient _i(
    String id,
    String nom,
    String emoji,
    GroupeIngredient groupe,
    int kcal100g,
    int portion,
  ) => Ingredient(
    id: id,
    nom: nom,
    emoji: emoji,
    groupe: groupe,
    kcal100g: kcal100g,
    portionGrammes: portion,
  );

  static const _f = GroupeIngredient.feculent;
  static const _p = GroupeIngredient.proteine;
  static const _l = GroupeIngredient.legume;
  static const _g = GroupeIngredient.matiereGrasse;
  static const _fr = GroupeIngredient.fruit;
  static const _b = GroupeIngredient.boisson;

  static final catalogue = <Ingredient>[
    // ----- Féculents -----
    _i('riz', 'Riz blanc cuit', '🍚', _f, 130, 200),
    _i('riz_gras', 'Riz gras (riz au gras)', '🍛', _f, 180, 250),
    _i('attieke', 'Attiéké', '🍚', _f, 160, 200),
    _i('igname', 'Igname bouillie', '🍠', _f, 115, 200),
    _i('foutou', 'Foutou (igname ou banane)', '🍡', _f, 125, 250),
    _i('placali', 'Placali', '🍡', _f, 130, 250),
    _i('plantain', 'Banane plantain bouillie', '🍌', _f, 120, 150),
    _i('alloco', 'Alloco (plantain frit)', '🍌', _f, 250, 150),
    _i('manioc', 'Manioc bouilli', '🥔', _f, 160, 200),
    _i('gari', 'Gari (sec)', '🥣', _f, 360, 50),
    _i('to', 'Tô (pâte de maïs ou de mil)', '🍡', _f, 110, 250),
    _i('fonio', 'Fonio ou couscous cuit', '🥣', _f, 120, 200),
    _i('pates', 'Spaghetti ou pâtes cuites', '🍝', _f, 155, 200),
    _i('pain', 'Pain', '🥖', _f, 270, 80),
    _i('patate_douce', 'Patate douce bouillie', '🍠', _f, 85, 200),
    _i('pomme_terre', 'Pomme de terre bouillie', '🥔', _f, 85, 200),
    _i('frites', 'Frites', '🍟', _f, 300, 150),
    _i('bouillie', 'Bouillie (mil, maïs)', '🥣', _f, 60, 250),
    _i('biscotte', 'Biscottes', '🍞', _f, 410, 20),
    // ----- Protéines -----
    _i('poisson_braise', 'Poisson braisé ou grillé', '🐟', _p, 150, 150),
    _i('poisson_frit', 'Poisson frit', '🐟', _p, 220, 150),
    _i('thon', 'Thon (garba, en boîte)', '🐟', _p, 200, 100),
    _i('poulet_braise', 'Poulet braisé (avec peau)', '🍗', _p, 220, 150),
    _i('poulet_sans_peau', 'Poulet sans peau', '🍗', _p, 165, 150),
    _i('boeuf', 'Viande de bœuf', '🥩', _p, 250, 100),
    _i('mouton', 'Viande de mouton', '🥩', _p, 260, 100),
    _i('brochette', 'Brochette (soya)', '🍢', _p, 240, 100),
    _i('oeuf', 'Œuf (1 œuf ≈ 50 g)', '🥚', _p, 145, 50),
    _i('crevettes', 'Crevettes', '🦐', _p, 100, 100),
    _i('escargot', 'Escargot', '🐌', _p, 90, 100),
    _i('haricots', 'Haricots ou niébé cuits', '🫘', _p, 120, 150),
    _i('lentilles', 'Lentilles cuites', '🫘', _p, 115, 150),
    _i('yaourt', 'Yaourt nature', '🥛', _p, 60, 125),
    _i('fromage', 'Fromage', '🧀', _p, 350, 30),
    // ----- Légumes -----
    _i('legumes_sauce', 'Légumes de sauce (gombo, aubergine, feuilles)', '🥬', _l, 30, 150),
    _i('tomate', 'Tomate', '🍅', _l, 18, 100),
    _i('oignon', 'Oignon', '🧅', _l, 40, 50),
    _i('carotte', 'Carotte', '🥕', _l, 40, 100),
    _i('salade', 'Salade verte, crudités', '🥗', _l, 15, 100),
    _i('chou', 'Chou', '🥬', _l, 25, 100),
    _i('concombre', 'Concombre', '🥒', _l, 15, 100),
    _i('haricots_verts', 'Haricots verts', '🫛', _l, 30, 150),
    _i('petits_pois', 'Petits pois', '🫛', _l, 80, 100),
    // ----- Sauces et huiles -----
    _i('huile', 'Huile (1 cuillère à soupe ≈ 10 g)', '🫙', _g, 900, 10),
    _i('huile_rouge', 'Huile rouge (palme)', '🫙', _g, 880, 10),
    _i('sauce_graine', 'Sauce graine', '🍲', _g, 180, 150),
    _i('sauce_arachide', 'Sauce arachide', '🥜', _g, 200, 150),
    _i('sauce_claire', 'Sauce claire ou tomate', '🍲', _g, 50, 150),
    _i('pate_arachide', 'Pâte d\'arachide', '🥜', _g, 600, 20),
    _i('arachides', 'Arachides grillées', '🥜', _g, 590, 30),
    _i('mayonnaise', 'Mayonnaise', '🫙', _g, 680, 15),
    _i('avocat', 'Avocat', '🥑', _g, 160, 100),
    // ----- Fruits -----
    _i('banane', 'Banane douce', '🍌', _fr, 90, 120),
    _i('mangue', 'Mangue', '🥭', _fr, 60, 150),
    _i('orange', 'Orange', '🍊', _fr, 45, 150),
    _i('ananas', 'Ananas', '🍍', _fr, 50, 150),
    _i('papaye', 'Papaye', '🍈', _fr, 40, 150),
    _i('pomme', 'Pomme', '🍎', _fr, 52, 150),
    _i('pasteque', 'Pastèque', '🍉', _fr, 30, 200),
    // ----- Boissons et sucres -----
    _i('jus', 'Jus de fruit', '🧃', _b, 45, 250),
    _i('soda', 'Soda', '🥤', _b, 42, 330),
    _i('bissap', 'Bissap ou gnamakoudji sucré', '🌺', _b, 50, 250),
    _i('lait', 'Lait', '🥛', _b, 65, 200),
    _i('lait_concentre', 'Lait concentré sucré', '🥛', _b, 330, 20),
    _i('sucre', 'Sucre (1 morceau ≈ 5 g)', '🍬', _b, 400, 5),
  ];

  static final _parId = {for (final i in catalogue) i.id: i};

  static Ingredient? parId(String id) => _parId[id];

  /// Calories totales d'une composition.
  static int kcal(List<Composant> composition) =>
      composition.fold<int>(0, (s, c) => s + (parId(c.idIngredient)?.kcal(c.grammes) ?? 0));

  /// Assiette (légumes / protéines / féculents) d'après le poids de chaque groupe.
  static Portions portions(List<Composant> composition) {
    double grammes(GroupeIngredient g) => composition
        .where((c) => parId(c.idIngredient)?.groupe == g)
        .fold<double>(0, (s, c) => s + c.grammes);
    final p = Portions.normalisees(
      grammes(GroupeIngredient.legume),
      grammes(GroupeIngredient.proteine),
      grammes(GroupeIngredient.feculent),
    );
    return p.total > 0 ? p : Portions.equilibre;
  }

  /// Nom proposé pour un plat composé : les ingrédients principaux.
  static String nomPropose(List<Composant> composition) {
    final tries = [...composition]..sort((a, b) => b.grammes.compareTo(a.grammes));
    final noms = [
      for (final c in tries.take(3))
        if (parId(c.idIngredient) case final i?) i.nom.split(' (').first,
    ];
    return noms.isEmpty ? 'Mon plat' : noms.join(', ');
  }

  /// Ingrédients habituels proposés pour un plat, d'après son nom et ses
  /// ingrédients principaux (« attiéké poisson » → attiéké, poisson…), plus l'huile.
  /// Aucun poids n'est proposé : c'est à l'utilisatrice de les indiquer.
  static List<Ingredient> suggestionsPour(String nomPlat, [List<String> ingredients = const []]) {
    final mots = {
      for (final texte in [nomPlat, ...ingredients])
        for (final mot in PlanService.normaliser(texte).split(RegExp(r'[^a-z]+')))
          if (mot.length >= 3 && !_motsVides.contains(mot)) mot,
    };
    final trouves = <Ingredient>[];
    for (final mot in mots) {
      for (final i in catalogue) {
        if (!trouves.contains(i) && PlanService.normaliser(i.nom).contains(mot)) {
          trouves.add(i);
          break;
        }
      }
    }
    final huile = parId('huile')!;
    if (!trouves.contains(huile)) trouves.add(huile);
    return trouves.take(8).toList();
  }

  static const _motsVides = {'sauce', 'avec', 'les', 'des', 'une', 'aux', 'light', 'soup'};

  /// Recherche sans accents ni majuscules (même règle que les plats).
  static List<Ingredient> chercher(String recherche) {
    final r = PlanService.normaliser(recherche.trim());
    if (r.isEmpty) return catalogue;
    return catalogue.where((i) => PlanService.normaliser(i.nom).contains(r)).toList();
  }
}
