/// Plan nutritionnel établi par un·e professionnel·le de santé
/// (diététicien·ne, nutritionniste), importé par l'utilisatrice.
///
/// Il est stocké uniquement sur l'appareil : il ne figure jamais
/// dans le code de l'application.
library;

/// Nature d'une section du plan.
enum TypeSection {
  /// Aliments ou préparations que le plan conseille d'éviter.
  eviter,

  /// Aliments ou préparations conseillés par le plan.
  conseille,

  /// Menu de la semaine.
  menu,

  /// Toute autre liste (conseils, remarques, contact…).
  liste,
}

/// Un groupe d'éléments, par exemple « Fruits : orange, pomme… ».
class GroupePlan {
  const GroupePlan({this.titre, required this.elements});

  /// Titre du groupe (`null` pour une liste simple).
  final String? titre;
  final List<String> elements;
}

/// Un repas du menu de la semaine.
class JourMenu {
  const JourMenu({required this.jour, required this.midi, required this.soir});

  /// « Lundi », « Mardi »…
  final String jour;
  final String midi;
  final String soir;
}

/// Une section du plan : « Conseils », « Aliments à éviter », « Menu »…
class SectionPlan {
  const SectionPlan({
    required this.titre,
    required this.type,
    this.groupes = const [],
    this.menu = const [],
  });

  final String titre;
  final TypeSection type;
  final List<GroupePlan> groupes;
  final List<JourMenu> menu;
}

class PlanNutrition {
  const PlanNutrition({
    required this.titre,
    this.sousTitre,
    required this.sections,
    required this.texteSource,
  });

  final String titre;
  final String? sousTitre;
  final List<SectionPlan> sections;

  /// Texte importé, conservé tel quel (pour pouvoir le relire ou le remplacer).
  final String texteSource;

  Iterable<SectionPlan> sectionsDeType(TypeSection type) => sections.where((s) => s.type == type);

  /// Menu de la semaine (vide si le plan n'en contient pas).
  List<JourMenu> get menu => [for (final s in sectionsDeType(TypeSection.menu)) ...s.menu];

  /// Menu prévu pour une date donnée, ou `null`.
  JourMenu? menuDu(DateTime date) {
    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    final cherche = jours[date.weekday - 1];
    for (final j in menu) {
      if (j.jour.trim().toLowerCase() == cherche) return j;
    }
    return null;
  }

  /// Section « petit-déjeuner », si elle existe.
  SectionPlan? get petitDejeuner {
    for (final s in sections) {
      if (s.titre.toLowerCase().contains('petit')) return s;
    }
    return null;
  }
}
