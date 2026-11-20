/// Repas de la journée (pour l'habitude « repas pris »).
enum Repas {
  petitDejeuner('Petit-déjeuner', '🥐'),
  dejeuner('Déjeuner', '🍲'),
  diner('Dîner', '🍽️'),
  collation('En-cas', '🍎');

  const Repas(this.libelle, this.emoji);
  final String libelle;
  final String emoji;

  /// Les trois repas principaux (la collation est un bonus facultatif).
  static const principaux = {petitDejeuner, dejeuner, diner};
}

/// Une échelle de 1 à 5 représentée par des emojis (ressentis, faim, plaisir…).
abstract interface class Echelle {
  String get libelle;

  /// Emoji pour chaque niveau, de 1 à 5.
  List<String> get emojis;

  /// Description de chaque niveau (lue par les lecteurs d'écran).
  List<String> get descriptions;
}

/// Ressentis notés en un geste, sur une échelle de 1 à 5.
enum Ressenti implements Echelle {
  energie(
    'Énergie',
    ['😴', '😕', '😐', '🙂', '🤩'],
    [
      'Très peu d\'énergie',
      'Peu d\'énergie',
      'Énergie correcte',
      'Bonne énergie',
      'Pleine d\'énergie',
    ],
  ),
  stress(
    'Stress',
    ['😌', '🙂', '😐', '😟', '😣'],
    ['Très calme', 'Calme', 'Stress moyen', 'Un peu de stress', 'Beaucoup de stress'],
  ),
  sommeil(
    'Sommeil',
    ['😫', '😕', '😐', '🙂', '😴'],
    ['Très mauvais', 'Moyen', 'Correct', 'Bon', 'Excellent'],
  );

  const Ressenti(this.libelle, this.emojis, this.descriptions);
  @override
  final String libelle;

  @override
  final List<String> emojis;

  @override
  final List<String> descriptions;

  /// Vrai si une valeur haute correspond à un ressenti agréable.
  /// (Pour le stress, c'est l'inverse.)
  bool get hautEstAgreable => this != stress;
}

/// Confort digestif, noté à part : il ne compte pas dans l'humeur du jour.
enum Digestion implements Echelle {
  digestion(
    'Digestion',
    ['😣', '😕', '😐', '🙂', '😌'],
    ['Très inconfortable', 'Un peu inconfortable', 'Correcte', 'Bonne', 'Toute légère'],
  );

  const Digestion(this.libelle, this.emojis, this.descriptions);
  @override
  final String libelle;

  @override
  final List<String> emojis;

  @override
  final List<String> descriptions;
}

/// Tout ce qui est noté pour une journée : eau, sommeil, repas, ressentis.
class JourHabitudes {
  const JourHabitudes({
    this.verres = 0,
    this.sommeilHeures,
    this.repas = const {},
    this.ressentis = const {},
    this.note,
    this.regles = false,
    this.pas,
    this.digestion,
    this.seanceFaite = false,
  });

  /// Nombre de verres d'eau bus.
  final int verres;

  /// Durée de la nuit précédente, en heures (`null` si non notée).
  final double? sommeilHeures;

  /// Repas pris dans la journée.
  final Set<Repas> repas;

  /// Ressentis notés (énergie, stress, sommeil), valeurs de 1 à 5.
  final Map<Ressenti, int> ressentis;

  /// Petit mot libre du journal.
  final String? note;

  /// Jour de règles (suivi de cycle, facultatif et désactivé par défaut).
  final bool regles;

  /// Nombre de pas, recopié depuis le téléphone (`null` si non noté).
  final int? pas;

  /// Confort digestif de 1 à 5 (`null` si non noté).
  final int? digestion;

  /// Séance de sport faite ce jour-là (cochée en un geste).
  final bool seanceFaite;

  /// Vrai si rien n'a encore été noté ce jour-là.
  bool get estVide =>
      verres == 0 &&
      sommeilHeures == null &&
      repas.isEmpty &&
      ressentis.isEmpty &&
      (note == null || note!.isEmpty) &&
      !regles &&
      pas == null &&
      digestion == null &&
      !seanceFaite;

  JourHabitudes copyWith({
    int? verres,
    double? sommeilHeures,
    bool effacerSommeil = false,
    Set<Repas>? repas,
    Map<Ressenti, int>? ressentis,
    String? note,
    bool? regles,
    int? pas,
    bool effacerPas = false,
    int? digestion,
    bool effacerDigestion = false,
    bool? seanceFaite,
  }) {
    return JourHabitudes(
      verres: verres ?? this.verres,
      sommeilHeures: effacerSommeil ? null : (sommeilHeures ?? this.sommeilHeures),
      repas: repas ?? this.repas,
      ressentis: ressentis ?? this.ressentis,
      note: note ?? this.note,
      regles: regles ?? this.regles,
      pas: effacerPas ? null : (pas ?? this.pas),
      digestion: effacerDigestion ? null : (digestion ?? this.digestion),
      seanceFaite: seanceFaite ?? this.seanceFaite,
    );
  }

  Map<String, dynamic> toJson() => {
    'verres': verres,
    if (sommeilHeures != null) 'sommeilHeures': sommeilHeures,
    'repas': [for (final r in repas) r.name],
    'ressentis': {for (final e in ressentis.entries) e.key.name: e.value},
    if (note != null && note!.isNotEmpty) 'note': note,
    if (regles) 'regles': true,
    if (pas != null) 'pas': pas,
    if (digestion != null) 'digestion': digestion,
    if (seanceFaite) 'seanceFaite': true,
  };

  factory JourHabitudes.fromJson(Map<String, dynamic> json) {
    final repas = <Repas>{};
    for (final nom in (json['repas'] as List? ?? const [])) {
      for (final r in Repas.values) {
        if (r.name == nom) repas.add(r);
      }
    }
    final ressentis = <Ressenti, int>{};
    (json['ressentis'] as Map<String, dynamic>? ?? const {}).forEach((nom, valeur) {
      for (final r in Ressenti.values) {
        if (r.name == nom) ressentis[r] = (valeur as num).toInt();
      }
    });
    return JourHabitudes(
      verres: (json['verres'] as num?)?.toInt() ?? 0,
      sommeilHeures: (json['sommeilHeures'] as num?)?.toDouble(),
      repas: repas,
      ressentis: ressentis,
      note: json['note'] as String?,
      regles: json['regles'] as bool? ?? false,
      pas: (json['pas'] as num?)?.toInt(),
      digestion: (json['digestion'] as num?)?.toInt(),
      seanceFaite: json['seanceFaite'] as bool? ?? false,
    );
  }
}
