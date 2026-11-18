import 'jour_habitudes.dart';
import 'recette.dart';

/// Pays (ou groupe) d'origine d'un plat de la bibliothèque.
enum PaysPlat {
  coteDIvoire('Côte d\'Ivoire', '🇨🇮'),
  senegal('Sénégal', '🇸🇳'),
  cameroun('Cameroun', '🇨🇲'),
  ghana('Ghana', '🇬🇭'),
  nigeria('Nigeria', '🇳🇬'),
  mali('Mali', '🇲🇱'),
  benin('Bénin et Togo', '🇧🇯'),
  basiques('Basiques', '🍽️'),
  mesPlats('Mes plats', '⭐');

  const PaysPlat(this.libelle, this.drapeau);
  final String libelle;
  final String drapeau;
}

/// Catégorie d'un plat.
enum CategoriePlat {
  petitDejeuner('Petit-déj', '🥐'),
  plat('Plats', '🍲'),
  simple('Simples', '🥗'),
  enCas('En-cas', '🍊'),
  dessert('Desserts', '🍮'),
  boisson('Boissons', '🥤');

  const CategoriePlat(this.libelle, this.emoji);
  final String libelle;
  final String emoji;

  static CategoriePlat depuisNom(String? nom) =>
      values.firstWhere((c) => c.name == nom, orElse: () => plat);
}

/// Taille de la portion, estimée à vue d'œil (pas de pesée, pas de calcul).
enum TaillePortion {
  petite('Petite', '🤏'),
  moyenne('Moyenne', '🍽️'),
  grande('Grande', '🙌');

  const TaillePortion(this.libelle, this.emoji);
  final String libelle;
  final String emoji;

  static TaillePortion depuisNom(String? nom) =>
      values.firstWhere((t) => t.name == nom, orElse: () => moyenne);
}

/// Ressentis autour d'un repas, sur une échelle de 1 à 5 (facultatifs).
enum RessentiRepas implements Echelle {
  faim('Faim avant', ['😐', '🙂', '😋', '😩', '🥴'],
      ['Pas faim', 'Un peu faim', 'Faim', 'Très faim', 'Énormément faim']),
  satiete('Satiété après', ['🤏', '🙂', '😌', '😮‍💨', '🫠'],
      ['Encore faim', 'Juste bien', 'Bien calé', 'Très plein', 'Trop plein']),
  plaisir('Plaisir', ['😐', '🙂', '😋', '😍', '🤩'],
      ['Bof', 'Correct', 'Bon', 'Délicieux', 'Un régal']);

  const RessentiRepas(this.libelle, this.emojis, this.descriptions);

  @override
  final String libelle;
  @override
  final List<String> emojis;
  @override
  final List<String> descriptions;
}

/// Un plat de la bibliothèque (ou ajouté par l'utilisatrice).
class Plat {
  const Plat({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.pays,
    required this.categorie,
    required this.portions,
    this.ingredients = const [],
  });

  final String id;
  final String nom;
  final String emoji;
  final PaysPlat pays;
  final CategoriePlat categorie;

  /// Répartition indicative légumes / protéines / féculents (pour l'assiette).
  final Portions portions;

  /// Principaux ingrédients (au singulier, en minuscules).
  final List<String> ingredients;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'emoji': emoji,
        'categorie': categorie.name,
        'legumes': portions.legumes,
        'proteines': portions.proteines,
        'feculents': portions.feculents,
      };

  /// Les plats enregistrés en JSON sont toujours des plats personnels.
  factory Plat.fromJson(Map<String, dynamic> json) => Plat(
        id: json['id'] as String,
        nom: json['nom'] as String,
        emoji: json['emoji'] as String? ?? '🍽️',
        pays: PaysPlat.mesPlats,
        categorie: CategoriePlat.depuisNom(json['categorie'] as String?),
        portions: Portions(
          legumes: (json['legumes'] as num?)?.toDouble() ?? 1 / 3,
          proteines: (json['proteines'] as num?)?.toDouble() ?? 1 / 3,
          feculents: (json['feculents'] as num?)?.toDouble() ?? 1 / 3,
        ),
      );
}
