import 'ingredient.dart';
import 'jour_habitudes.dart';
import 'plat.dart';
import 'recette.dart';

/// Un repas noté dans le journal des repas : un plat (de la bibliothèque,
/// du plan ou personnel) et/ou une photo, avec des ressentis facultatifs.
///
/// Les calories sont estimées (voir CaloriesService) et peuvent être
/// corrigées à la main ([kcalManuel]).
class RepasPhoto {
  const RepasPhoto({
    required this.id,
    required this.date,
    required this.repas,
    required this.portions,
    this.photoBase64,
    this.nomPlat,
    this.emojiPlat,
    this.taille = TaillePortion.moyenne,
    this.ressentis = const {},
    this.kcalManuel,
    this.composition = const [],
  });

  final String id;
  final DateTime date;

  /// Moment du repas (petit-déjeuner, déjeuner, dîner, en-cas).
  final Repas repas;

  /// Répartition légumes / protéines / féculents (pour la petite assiette).
  final Portions portions;

  /// Photo réduite, encodée en texte (base64). `null` si pas de photo
  /// ou si la photo a été retirée pour faire de la place.
  final String? photoBase64;

  /// Nom du plat choisi (`null` pour un repas noté seulement en photo).
  final String? nomPlat;
  final String? emojiPlat;
  final TaillePortion taille;

  /// Faim avant, satiété après, plaisir : de 1 à 5, tous facultatifs.
  final Map<RessentiRepas, int> ressentis;

  /// Calories saisies à la main (`null` : estimation automatique).
  final int? kcalManuel;

  /// Ingrédients pesés (plat composé au gramme près). Vide sinon.
  final List<Composant> composition;

  /// Nom à afficher dans le journal.
  String get titre => nomPlat ?? 'Repas en photo';

  RepasPhoto copyWith({
    Repas? repas,
    TaillePortion? taille,
    Map<RessentiRepas, int>? ressentis,
    bool retirerPhoto = false,
    int? kcalManuel,
    bool effacerKcal = false,
    List<Composant>? composition,
    Portions? portions,
    String? nomPlat,
    String? emojiPlat,
  }) => RepasPhoto(
    id: id,
    date: date,
    repas: repas ?? this.repas,
    portions: portions ?? this.portions,
    photoBase64: retirerPhoto ? null : photoBase64,
    nomPlat: nomPlat ?? this.nomPlat,
    emojiPlat: emojiPlat ?? this.emojiPlat,
    composition: composition ?? this.composition,
    taille: taille ?? this.taille,
    ressentis: ressentis ?? this.ressentis,
    kcalManuel: effacerKcal ? null : (kcalManuel ?? this.kcalManuel),
  );

  RepasPhoto sansPhoto() => copyWith(retirerPhoto: true);

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'repas': repas.name,
    'legumes': portions.legumes,
    'proteines': portions.proteines,
    'feculents': portions.feculents,
    if (photoBase64 != null) 'photo': photoBase64,
    if (nomPlat != null) 'plat': nomPlat,
    if (emojiPlat != null) 'emoji': emojiPlat,
    'taille': taille.name,
    if (ressentis.isNotEmpty) 'ressentis': {for (final e in ressentis.entries) e.key.name: e.value},
    if (kcalManuel != null) 'kcal': kcalManuel,
    if (composition.isNotEmpty) 'composition': [for (final c in composition) c.toJson()],
  };

  factory RepasPhoto.fromJson(Map<String, dynamic> json) {
    final ressentis = <RessentiRepas, int>{};
    (json['ressentis'] as Map<String, dynamic>? ?? const {}).forEach((nom, v) {
      for (final r in RessentiRepas.values) {
        if (r.name == nom) ressentis[r] = (v as num).toInt();
      }
    });
    return RepasPhoto(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      repas: Repas.values.firstWhere((r) => r.name == json['repas'], orElse: () => Repas.dejeuner),
      portions: Portions(
        legumes: (json['legumes'] as num).toDouble(),
        proteines: (json['proteines'] as num).toDouble(),
        feculents: (json['feculents'] as num).toDouble(),
      ),
      photoBase64: json['photo'] as String?,
      nomPlat: json['plat'] as String?,
      emojiPlat: json['emoji'] as String?,
      taille: TaillePortion.depuisNom(json['taille'] as String?),
      ressentis: ressentis,
      kcalManuel: (json['kcal'] as num?)?.toInt(),
      composition: [
        for (final c in (json['composition'] as List? ?? const []))
          Composant.fromJson(c as Map<String, dynamic>),
      ],
    );
  }
}
