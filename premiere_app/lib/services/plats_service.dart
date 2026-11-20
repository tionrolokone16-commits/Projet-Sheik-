import '../models/plat.dart';
import '../models/recette.dart';
import 'plan_service.dart';

/// Bibliothèque de plats africains pour noter ses repas en une touche.
///
/// Chaque plat est classé (légumes / protéines / féculents) selon les groupes
/// d'aliments de la « Table de composition des aliments, région Centre Côte
/// d'Ivoire » (Étude régionale de Bouaké, 1962-1964) : féculents (igname,
/// manioc, banane plantain, taro), céréales (riz, maïs, mil, fonio),
/// légumineuses, légumes et feuilles, viandes, poissons.
/// Les calories estimées de chaque plat sont dans CaloriesService.
class PlatsService {
  PlatsService._();

  /// Répartition légumes / protéines / féculents, ramenée à 100 %.
  static Portions _p(double l, double p, double f) => Portions.normalisees(l, p, f);

  static Plat _plat(
    String id,
    String nom,
    String emoji,
    PaysPlat pays,
    CategoriePlat cat,
    Portions portions, [
    List<String> ingredients = const [],
  ]) => Plat(
    id: id,
    nom: nom,
    emoji: emoji,
    pays: pays,
    categorie: cat,
    portions: portions,
    ingredients: ingredients,
  );

  static final catalogue = <Plat>[
    // ------------------------------------------------- Côte d'Ivoire
    _plat(
      'ci_attieke_poisson',
      'Attiéké poisson braisé',
      '🐟',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1, 1, 1.2),
      ['attiéké', 'poisson'],
    ),
    _plat('ci_garba', 'Garba', '🥘', PaysPlat.coteDIvoire, CategoriePlat.plat, _p(0.5, 1, 1.5), [
      'attiéké',
      'thon',
    ]),
    _plat('ci_alloco', 'Alloco', '🍌', PaysPlat.coteDIvoire, CategoriePlat.plat, _p(0.3, 0.5, 2), [
      'banane plantain',
    ]),
    _plat(
      'ci_foutou_graine',
      'Foutou banane sauce graine',
      '🍲',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(0.8, 1, 1.5),
      ['banane plantain', 'graine'],
    ),
    _plat(
      'ci_foutou_claire',
      'Foutou igname sauce claire',
      '🍲',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1, 1, 1.5),
      ['igname'],
    ),
    _plat(
      'ci_kedjenou',
      'Kédjénou de poulet',
      '🍗',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1.2, 1.3, 0.6),
      ['poulet'],
    ),
    _plat(
      'ci_riz_arachide',
      'Riz sauce arachide',
      '🥜',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(0.8, 1, 1.4),
      ['riz', 'arachide'],
    ),
    _plat(
      'ci_riz_aubergine',
      'Riz sauce aubergine poisson',
      '🍆',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1.2, 1, 1.2),
      ['riz', 'aubergine', 'poisson'],
    ),
    _plat(
      'ci_placali_gombo',
      'Placali sauce gombo',
      '🌿',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1.2, 1, 1.2),
      ['placali', 'gombo'],
    ),
    _plat(
      'ci_cabato_feuille',
      'Cabato sauce feuille',
      '🥬',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1.3, 1, 1.2),
      ['cabato', 'feuille'],
    ),
    _plat(
      'ci_riz_gras',
      'Riz gras',
      '🍚',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(0.8, 0.8, 1.6),
      ['riz'],
    ),
    _plat(
      'ci_igname_legume',
      'Igname bouillie et pâte de légume',
      '🍠',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(1.2, 1, 1.2),
      ['igname'],
    ),
    _plat(
      'ci_banane_braisee',
      'Banane braisée et poisson',
      '🍌',
      PaysPlat.coteDIvoire,
      CategoriePlat.plat,
      _p(0.5, 1, 1.5),
      ['banane plantain', 'poisson'],
    ),
    _plat('ci_claclo', 'Claclo', '🍪', PaysPlat.coteDIvoire, CategoriePlat.enCas, _p(0, 0.2, 1)),
    _plat('ci_degue', 'Dêguê', '🥣', PaysPlat.coteDIvoire, CategoriePlat.dessert, _p(0, 1, 1.2)),
    _plat(
      'ci_gnamakoudji',
      'Gnamakoudji',
      '🫚',
      PaysPlat.coteDIvoire,
      CategoriePlat.boisson,
      _p(0, 0, 0),
    ),
    _plat('ci_bissap', 'Bissap', '🌺', PaysPlat.coteDIvoire, CategoriePlat.boisson, _p(0, 0, 0)),
    _plat(
      'ci_bouillie_mil',
      'Bouillie de mil',
      '🥣',
      PaysPlat.coteDIvoire,
      CategoriePlat.petitDejeuner,
      _p(0, 0.3, 1),
    ),

    // ------------------------------------------------------- Sénégal
    _plat('sn_thieb', 'Thiéboudienne', '🐟', PaysPlat.senegal, CategoriePlat.plat, _p(1, 1, 1.4), [
      'riz',
      'poisson',
    ]),
    _plat(
      'sn_yassa',
      'Yassa poulet',
      '🍋',
      PaysPlat.senegal,
      CategoriePlat.plat,
      _p(0.8, 1.2, 1.3),
      ['riz', 'poulet'],
    ),
    _plat('sn_mafe', 'Mafé', '🥜', PaysPlat.senegal, CategoriePlat.plat, _p(0.8, 1, 1.4), [
      'riz',
      'arachide',
    ]),
    _plat(
      'sn_soupou_kandja',
      'Soupou kandja',
      '🌿',
      PaysPlat.senegal,
      CategoriePlat.plat,
      _p(1.2, 1, 1.2),
      ['riz', 'gombo'],
    ),
    _plat('sn_thiakry', 'Thiakry', '🥣', PaysPlat.senegal, CategoriePlat.dessert, _p(0, 1, 1.3)),
    _plat('sn_pastels', 'Pastels', '🥟', PaysPlat.senegal, CategoriePlat.enCas, _p(0.2, 0.8, 1)),

    // ------------------------------------------------------ Cameroun
    _plat('cm_ndole', 'Ndolè', '🥬', PaysPlat.cameroun, CategoriePlat.plat, _p(1.3, 1, 1), [
      'feuille',
      'arachide',
    ]),
    _plat('cm_eru', 'Eru', '🌿', PaysPlat.cameroun, CategoriePlat.plat, _p(1.4, 1, 1), ['feuille']),
    _plat(
      'cm_poulet_dg',
      'Poulet DG',
      '🍗',
      PaysPlat.cameroun,
      CategoriePlat.plat,
      _p(0.8, 1.2, 1.3),
      ['poulet', 'banane plantain'],
    ),
    _plat('cm_koki', 'Koki', '🫘', PaysPlat.cameroun, CategoriePlat.plat, _p(0.5, 1.4, 0.8)),
    _plat(
      'cm_mbongo',
      'Mbongo tchobi',
      '🐟',
      PaysPlat.cameroun,
      CategoriePlat.plat,
      _p(0.8, 1.2, 1.2),
      ['poisson'],
    ),
    _plat(
      'cm_beignets_haricots',
      'Beignets-haricots',
      '🫘',
      PaysPlat.cameroun,
      CategoriePlat.petitDejeuner,
      _p(0, 1, 1.4),
    ),

    // ---------------------------------------------------------- Ghana
    _plat('gh_jollof', 'Jollof rice', '🍛', PaysPlat.ghana, CategoriePlat.plat, _p(0.6, 1, 1.6), [
      'riz',
    ]),
    _plat('gh_waakye', 'Waakye', '🍛', PaysPlat.ghana, CategoriePlat.plat, _p(0.5, 1.2, 1.5), [
      'riz',
      'haricot',
    ]),
    _plat(
      'gh_banku',
      'Banku et tilapia',
      '🐟',
      PaysPlat.ghana,
      CategoriePlat.plat,
      _p(0.7, 1.2, 1.3),
      ['poisson'],
    ),
    _plat(
      'gh_fufu_light',
      'Fufu light soup',
      '🍲',
      PaysPlat.ghana,
      CategoriePlat.plat,
      _p(0.8, 1, 1.5),
    ),
    _plat('gh_red_red', 'Red red', '🫘', PaysPlat.ghana, CategoriePlat.plat, _p(0.5, 1.2, 1.3), [
      'haricot',
      'banane plantain',
    ]),
    _plat('gh_kelewele', 'Kelewele', '🍌', PaysPlat.ghana, CategoriePlat.enCas, _p(0, 0, 1), [
      'banane plantain',
    ]),

    // -------------------------------------------------------- Nigeria
    _plat(
      'ng_egusi',
      'Egusi soup et pounded yam',
      '🍲',
      PaysPlat.nigeria,
      CategoriePlat.plat,
      _p(1, 1, 1.5),
      ['igname'],
    ),
    _plat('ng_efo_riro', 'Efo riro', '🥬', PaysPlat.nigeria, CategoriePlat.plat, _p(1.5, 1, 0.8), [
      'feuille',
    ]),
    _plat('ng_moi_moi', 'Moi moi', '🫘', PaysPlat.nigeria, CategoriePlat.plat, _p(0.3, 1.5, 0.8), [
      'haricot',
    ]),
    _plat(
      'ng_pepper_soup',
      'Pepper soup',
      '🍲',
      PaysPlat.nigeria,
      CategoriePlat.plat,
      _p(0.8, 1.5, 0.3),
    ),
    _plat('ng_suya', 'Suya', '🍢', PaysPlat.nigeria, CategoriePlat.enCas, _p(0.3, 1, 0), [
      'viande',
    ]),
    _plat(
      'ng_akara',
      'Akara',
      '🧆',
      PaysPlat.nigeria,
      CategoriePlat.petitDejeuner,
      _p(0, 1.2, 0.8),
      ['haricot'],
    ),

    // ----------------------------------------------------------- Mali
    _plat(
      'ml_to_gombo',
      'Tô sauce gombo',
      '🌿',
      PaysPlat.mali,
      CategoriePlat.plat,
      _p(1, 0.8, 1.5),
      ['mil', 'gombo'],
    ),
    _plat(
      'ml_fonio',
      'Fonio au poisson',
      '🐟',
      PaysPlat.mali,
      CategoriePlat.plat,
      _p(0.8, 1, 1.3),
      ['fonio', 'poisson'],
    ),
    _plat('ml_tiga', 'Tigadèguèna', '🥜', PaysPlat.mali, CategoriePlat.plat, _p(0.8, 1, 1.4), [
      'riz',
      'arachide',
    ]),

    // -------------------------------------------------- Bénin et Togo
    _plat(
      'bj_amiwo',
      'Amiwo et poulet',
      '🍗',
      PaysPlat.benin,
      CategoriePlat.plat,
      _p(0.6, 1, 1.5),
      ['maïs', 'poulet'],
    ),
    _plat(
      'bj_gboman',
      'Pâte et sauce gboman',
      '🥬',
      PaysPlat.benin,
      CategoriePlat.plat,
      _p(1.3, 1, 1.3),
      ['maïs', 'feuille'],
    ),
    _plat('bj_ablo', 'Ablo et poisson', '🐟', PaysPlat.benin, CategoriePlat.plat, _p(0.6, 1, 1.4), [
      'maïs',
      'poisson',
    ]),

    // ------------------------------------------------------- Basiques
    _plat(
      'b_biscottes_yaourt',
      'Biscottes et yaourt 0 %',
      '🥛',
      PaysPlat.basiques,
      CategoriePlat.petitDejeuner,
      _p(0, 1, 1.2),
    ),
    _plat('b_fruit', 'Un fruit', '🍊', PaysPlat.basiques, CategoriePlat.enCas, _p(1, 0, 0)),
    _plat('b_yaourt', 'Yaourt nature', '🥛', PaysPlat.basiques, CategoriePlat.enCas, _p(0, 1, 0)),
    _plat('b_pain', 'Pain', '🥖', PaysPlat.basiques, CategoriePlat.petitDejeuner, _p(0, 0, 1)),
    _plat('b_the', 'Thé ou café', '☕', PaysPlat.basiques, CategoriePlat.petitDejeuner, _p(0, 0, 0)),
    _plat('b_crudites', 'Crudités', '🥕', PaysPlat.basiques, CategoriePlat.simple, _p(1, 0, 0)),
    _plat(
      'b_salade_poulet',
      'Salade verte et poulet braisé',
      '🥗',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(1.2, 1, 0),
      ['poulet'],
    ),
    _plat(
      'b_poisson_braise',
      'Poisson braisé',
      '🐟',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(0.3, 1, 0),
      ['poisson'],
    ),
    _plat(
      'b_poulet_braise',
      'Poulet braisé',
      '🍗',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(0.3, 1, 0),
      ['poulet'],
    ),
    _plat(
      'b_brochette',
      'Brochette de viande',
      '🍢',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(0.3, 1, 0),
      ['viande'],
    ),
    _plat(
      'b_haricot_vert',
      'Haricots verts et viande',
      '🫛',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(1.2, 1, 0),
      ['haricot vert', 'viande'],
    ),
    _plat(
      'b_petit_pois',
      'Petits pois et poulet',
      '🫛',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(1.2, 1, 0.3),
      ['petit pois', 'poulet'],
    ),
    _plat(
      'b_carotte',
      'Carotte râpée et brochette',
      '🥕',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(1.2, 1, 0),
      ['carotte', 'viande'],
    ),
    _plat(
      'b_soupe',
      'Soupe de légumes',
      '🍲',
      PaysPlat.basiques,
      CategoriePlat.simple,
      _p(1, 0, 0.2),
    ),
    _plat(
      'b_spaghetti',
      'Spaghetti et viande',
      '🍝',
      PaysPlat.basiques,
      CategoriePlat.plat,
      _p(0.3, 1, 1.5),
      ['spaghetti', 'viande'],
    ),
    _plat(
      'b_riz_blanc',
      'Riz blanc et poisson',
      '🍚',
      PaysPlat.basiques,
      CategoriePlat.plat,
      _p(0.3, 1, 1.5),
      ['riz', 'poisson'],
    ),
    _plat('b_eau', 'Un verre d\'eau', '💧', PaysPlat.basiques, CategoriePlat.boisson, _p(0, 0, 0)),
    _plat('b_jus', 'Jus de fruit', '🧃', PaysPlat.basiques, CategoriePlat.boisson, _p(0, 0, 0)),
    _plat('b_soda', 'Soda', '🥤', PaysPlat.basiques, CategoriePlat.boisson, _p(0, 0, 0)),
    _plat(
      'b_gateau',
      'Gâteau ou pâtisserie',
      '🍰',
      PaysPlat.basiques,
      CategoriePlat.dessert,
      _p(0, 0.2, 1),
    ),
  ];

  // ------------------------------------------- Estimation de l'assiette

  /// Mots qui signalent chaque groupe d'aliments (d'après les groupes du
  /// tableau de Bouaké), pour estimer l'assiette d'un plat décrit en texte.
  static const _feculents = [
    'riz',
    'attieke',
    'igname',
    'manioc',
    'placali',
    'cabato',
    'foutou',
    'banane',
    'plantain',
    'spaghetti',
    'semoule',
    'pain',
    'biscotte',
    'mai',
    'mil',
    'fonio',
    'taro',
    'patate',
    'pomme de terre',
    'garba',
    'alloco',
    'couscou',
    'to',
  ];
  static const _proteines = [
    'poisson',
    'poulet',
    'viande',
    'brochette',
    'boeuf',
    'veau',
    'pintade',
    'thon',
    'oeuf',
    'haricot sec',
    'niebe',
    'lentille',
    'yaourt',
    'lait',
    'mouton',
    'chevre',
    'escargot',
    'crevette',
    'crabe',
    'sardine',
    'agouti',
  ];
  static const _legumes = [
    'salade',
    'legume',
    'haricot vert',
    'carotte',
    'petit poi',
    'aubergine',
    'gombo',
    'feuille',
    'tomate',
    'crudite',
    'chou',
    'epinard',
    'concombre',
    'gnangnan',
    'courgette',
    'sauce claire',
    'soupe',
  ];

  /// Estime la répartition d'une assiette à partir d'une description
  /// (ex. « Riz cuit (180 g) + sauce aubergine + poisson »).
  static Portions estimerPortions(String description) {
    // Ponctuation et chiffres retirés : « (180 g) » ou « poisson, » ne gênent pas.
    final propre = description.replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ');
    final texte = ' ${PlanService.normaliser(propre)} ';
    // Comparaison par mots entiers : « to » ne doit pas reconnaître « tomate ».
    bool contient(List<String> mots) => mots.any((m) => texte.contains(' $m '));
    final f = contient(_feculents);
    final p = contient(_proteines);
    final l = contient(_legumes);
    if (!f && !p && !l) return const Portions(legumes: 1 / 3, proteines: 1 / 3, feculents: 1 / 3);
    // Repère : quand les légumes sont là, ils prennent volontiers plus de place.
    return Portions.normalisees(l ? 1.2 : 0, p ? 1 : 0, f ? 1 : 0);
  }

  /// Recherche simple, sans accents ni majuscules.
  static bool correspond(Plat plat, String recherche) {
    final r = PlanService.normaliser(recherche.trim());
    if (r.isEmpty) return true;
    return PlanService.normaliser(plat.nom).contains(r) ||
        PlanService.normaliser(plat.pays.libelle).contains(r);
  }
}
