import '../models/plan_nutrition.dart';

/// Erreur de lecture d'un plan collé, avec un message compréhensible.
class ErreurPlan implements Exception {
  const ErreurPlan(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Lecture du plan nutritionnel collé par l'utilisatrice, et recherche
/// des aliments que ce plan conseille d'éviter.
///
/// Format attendu (lisible tel quel) :
///
///     [[Kira's FAT · plan]]
///     # titre: Plan de ma diététicienne
///     # sous-titre: …                      (facultatif)
///     == Conseils
///     - Manger lentement
///     == Aliments à éviter
///     ## Fruits
///     - Coco, avocat, olive
///     == Menu
///     Lundi | Riz cuit (180 g) + poisson | Salade verte + poulet braisé
class PlanService {
  PlanService._();

  /// Première ligne obligatoire : évite d'importer un texte collé par erreur.
  static const marqueur = "[[Kira's FAT · plan]]";

  static PlanNutrition lire(String texte) {
    final lignes = texte
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lignes.isEmpty || !_memeMarqueur(lignes.first)) {
      throw const ErreurPlan(
        'Ce texte ne ressemble pas à un plan Kira\'s FAT : la première ligne '
        'doit être « [[Kira\'s FAT · plan]] ». Vérifie que tout a bien été copié.',
      );
    }

    String titre = 'Mon plan nutritionnel';
    String? sousTitre;
    final sections = <SectionPlan>[];

    // Section et groupe en cours de lecture.
    String? titreSection;
    final groupes = <GroupePlan>[];
    final menu = <JourMenu>[];
    String? titreGroupe;
    var elements = <String>[];

    void fermerGroupe() {
      if (elements.isNotEmpty) groupes.add(GroupePlan(titre: titreGroupe, elements: elements));
      titreGroupe = null;
      elements = <String>[];
    }

    void fermerSection() {
      fermerGroupe();
      if (titreSection != null && (groupes.isNotEmpty || menu.isNotEmpty)) {
        sections.add(
          SectionPlan(
            titre: titreSection,
            type: menu.isNotEmpty ? TypeSection.menu : _typeDe(titreSection),
            groupes: List.of(groupes),
            menu: List.of(menu),
          ),
        );
      }
      groupes.clear();
      menu.clear();
    }

    for (final ligne in lignes.skip(1)) {
      if (ligne.startsWith('# ')) {
        final (cle, valeur) = _cleValeur(ligne.substring(2));
        if (cle == 'titre' && valeur.isNotEmpty) titre = valeur;
        if (cle == 'sous-titre' && valeur.isNotEmpty) sousTitre = valeur;
      } else if (ligne.startsWith('== ')) {
        fermerSection();
        titreSection = ligne.substring(3).trim();
      } else if (ligne.startsWith('## ')) {
        fermerGroupe();
        titreGroupe = ligne.substring(3).trim();
      } else if (ligne.contains('|')) {
        final parties = ligne.split('|').map((p) => p.trim()).toList();
        if (parties.length >= 3) {
          menu.add(JourMenu(jour: parties[0], midi: parties[1], soir: parties[2]));
        }
      } else {
        // « - élément » ou ligne simple.
        final element = ligne.startsWith('- ') ? ligne.substring(2).trim() : ligne;
        if (element.isNotEmpty) elements.add(element);
      }
    }
    fermerSection();

    if (sections.isEmpty) {
      throw const ErreurPlan('Le plan ne contient aucune section (lignes commençant par « == »).');
    }
    return PlanNutrition(
      titre: titre,
      sousTitre: sousTitre,
      sections: sections,
      texteSource: texte.trim(),
    );
  }

  // ------------------------------------------------- Aliments à éviter

  /// Termes que le plan conseille d'éviter, sous forme normalisée.
  /// « Poissons gras : machoiron, maquereau » donne « machoiron », « maquereau » :
  /// seuls les exemples précis sont retenus, pas la catégorie générale.
  static Set<String> termesAEviter(PlanNutrition plan) {
    final termes = <String>{};
    for (final section in plan.sectionsDeType(TypeSection.eviter)) {
      for (final groupe in section.groupes) {
        for (final element in groupe.elements) {
          termes.addAll(_termes(element));
        }
      }
    }
    return termes;
  }

  /// Ingrédients d'une liste que le plan conseille d'éviter
  /// (renvoyés sous leur forme d'origine, sans doublon).
  static List<String> ingredientsAEviter(PlanNutrition plan, List<String> ingredients) {
    final termes = termesAEviter(plan);
    return [
      for (final i in ingredients)
        if (termes.contains(normaliser(i))) i,
    ];
  }

  /// Minuscules, sans accents ni pluriel simple, espaces réduits :
  /// « Fritures » → « friture », « Œuf dur » → « oeuf dur ».
  static String normaliser(String texte) {
    const accents = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'œ': 'oe',
      'æ': 'ae',
      '’': "'",
    };
    var t = texte.toLowerCase();
    accents.forEach((a, b) => t = t.replaceAll(a, b));
    return t
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty)
        .map(
          (m) => m.length > 3 && (m.endsWith('s') || m.endsWith('x'))
              ? m.substring(0, m.length - 1)
              : m,
        )
        .join(' ');
  }

  static Iterable<String> _termes(String element) {
    // Si l'élément a la forme « Catégorie : exemples », on garde les exemples.
    final apres = element.contains(':') ? element.split(':').skip(1).join(':') : element;
    return apres
        .split(RegExp(r'[,;/()+]|\bou\b|\bet\b'))
        .map((t) => normaliser(t.trim()))
        .where((t) => t.length >= 3);
  }

  static TypeSection _typeDe(String titre) {
    final t = normaliser(titre);
    if (t.contains('eviter') || t.contains('limiter')) return TypeSection.eviter;
    if (t.contains('autorise') || t.contains('conseille') || t.contains('privilegier')) {
      return TypeSection.conseille;
    }
    return TypeSection.liste;
  }

  static (String, String) _cleValeur(String texte) {
    final i = texte.indexOf(':');
    if (i < 0) return (texte.trim().toLowerCase(), '');
    return (texte.substring(0, i).trim().toLowerCase(), texte.substring(i + 1).trim());
  }

  static bool _memeMarqueur(String ligne) =>
      normaliser(ligne).replaceAll(' ', '') == normaliser(marqueur).replaceAll(' ', '');
}
