/// Catégories de victoires « hors balance ».
enum CategorieVictoire {
  vetements('Vêtements plus confortables', '👖'),
  energie('Plus d\'énergie', '⚡'),
  sommeil('Meilleur sommeil', '😴'),
  humeur('Bonne humeur', '😊'),
  souffle('Plus de force ou de souffle', '💪'),
  repas('Repas apaisé', '🍽️'),
  autre('Autre victoire', '✨');

  const CategorieVictoire(this.libelle, this.emoji);
  final String libelle;
  final String emoji;

  static CategorieVictoire depuisNom(String? nom) => CategorieVictoire.values.firstWhere(
    (c) => c.name == nom,
    orElse: () => CategorieVictoire.autre,
  );
}

/// Une victoire qui n'a rien à voir avec la balance.
class Victoire {
  const Victoire({required this.id, required this.date, required this.categorie, this.texte});

  final String id;
  final DateTime date;
  final CategorieVictoire categorie;
  final String? texte;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'categorie': categorie.name,
    if (texte != null && texte!.isNotEmpty) 'texte': texte,
  };

  factory Victoire.fromJson(Map<String, dynamic> json) => Victoire(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    categorie: CategorieVictoire.depuisNom(json['categorie'] as String?),
    texte: json['texte'] as String?,
  );
}

/// Tout ce qui concerne les récompenses : badges, célébrations déjà vues,
/// défis choisis, victoires hors balance et pauses respiration.
class Progres {
  Progres({
    Map<String, DateTime>? badges,
    Set<String>? celebrations,
    Map<String, Map<String, int>>? defis,
    List<Victoire>? victoires,
    List<DateTime>? respirations,
    List<DateTime>? fringales,
    Map<String, List<String>>? idees,
  }) : badges = badges ?? {},
       celebrations = celebrations ?? {},
       defis = defis ?? {},
       victoires = victoires ?? [],
       respirations = respirations ?? [],
       fringales = fringales ?? [],
       idees = idees ?? {};

  /// Badges obtenus, avec leur date d'obtention.
  final Map<String, DateTime> badges;

  /// Clés des célébrations déjà affichées (pour ne jamais les répéter).
  final Set<String> celebrations;

  /// Défis choisis par semaine : { lundi « aaaa-mm-jj » : { défi : compteur manuel } }.
  final Map<String, Map<String, int>> defis;

  /// Victoires hors balance, de la plus récente à la plus ancienne.
  final List<Victoire> victoires;

  /// Dates des pauses respiration terminées.
  final List<DateTime> respirations;

  /// Moments où le bouton « J'ai une fringale » a été touché (pour le bilan).
  final List<DateTime> fringales;

  /// Idées choisies dans le bilan, par semaine : { lundi « aaaa-mm-jj » : [idées] }.
  final Map<String, List<String>> idees;

  Map<String, dynamic> toJson() => {
    'badges': badges.map((k, v) => MapEntry(k, v.toIso8601String())),
    'celebrations': celebrations.toList(),
    'defis': defis,
    'victoires': [for (final v in victoires) v.toJson()],
    'respirations': [for (final r in respirations) r.toIso8601String()],
    'fringales': [for (final f in fringales) f.toIso8601String()],
    'idees': idees,
  };

  factory Progres.fromJson(Map<String, dynamic> json) {
    final defis = <String, Map<String, int>>{};
    (json['defis'] as Map<String, dynamic>? ?? const {}).forEach((semaine, d) {
      defis[semaine] = (d as Map<String, dynamic>).map((id, n) => MapEntry(id, (n as num).toInt()));
    });
    return Progres(
      badges: (json['badges'] as Map<String, dynamic>? ?? const {}).map(
        (k, v) => MapEntry(k, DateTime.parse(v as String)),
      ),
      celebrations: {...(json['celebrations'] as List? ?? const []).cast<String>()},
      defis: defis,
      victoires: [
        for (final v in (json['victoires'] as List? ?? const []))
          Victoire.fromJson(v as Map<String, dynamic>),
      ],
      respirations: [
        for (final r in (json['respirations'] as List? ?? const [])) DateTime.parse(r as String),
      ],
      fringales: [
        for (final f in (json['fringales'] as List? ?? const [])) DateTime.parse(f as String),
      ],
      idees: (json['idees'] as Map<String, dynamic>? ?? const {}).map(
        (k, v) => MapEntry(k, (v as List).cast<String>()),
      ),
    );
  }
}
