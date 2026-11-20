/// Choix du thème d'affichage.
enum ThemeChoisi {
  systeme('Comme l\'appareil'),
  clair('Clair'),
  sombre('Sombre');

  const ThemeChoisi(this.libelle);
  final String libelle;

  static ThemeChoisi depuisNom(String? nom) =>
      ThemeChoisi.values.firstWhere((t) => t.name == nom, orElse: () => ThemeChoisi.systeme);
}

/// Réglages de l'application.
class Reglages {
  const Reglages({
    this.masquerPoidsAccueil = false,
    this.objectifVerres = 8,
    this.theme = ThemeChoisi.systeme,
    this.rappelsRepas = true,
    this.heurePetitDejeuner = 8 * 60,
    this.heureDejeuner = 13 * 60,
    this.heureDiner = 20 * 60,
    this.suiviCycle = false,
  });

  /// Si vrai, le poids n'apparaît pas sur l'écran d'accueil.
  final bool masquerPoidsAccueil;

  /// Nombre de verres d'eau visés chaque jour.
  final int objectifVerres;

  final ThemeChoisi theme;

  /// Rappels doux aux heures de repas (affichés sur l'accueil).
  final bool rappelsRepas;

  /// Heures des rappels, en minutes depuis minuit (8 h = 480).
  final int heurePetitDejeuner;
  final int heureDejeuner;
  final int heureDiner;

  /// Suivi de cycle (jours de règles) : facultatif, désactivé par défaut.
  final bool suiviCycle;

  Reglages copyWith({
    bool? masquerPoidsAccueil,
    int? objectifVerres,
    ThemeChoisi? theme,
    bool? rappelsRepas,
    int? heurePetitDejeuner,
    int? heureDejeuner,
    int? heureDiner,
    bool? suiviCycle,
  }) => Reglages(
    masquerPoidsAccueil: masquerPoidsAccueil ?? this.masquerPoidsAccueil,
    objectifVerres: objectifVerres ?? this.objectifVerres,
    theme: theme ?? this.theme,
    rappelsRepas: rappelsRepas ?? this.rappelsRepas,
    heurePetitDejeuner: heurePetitDejeuner ?? this.heurePetitDejeuner,
    heureDejeuner: heureDejeuner ?? this.heureDejeuner,
    heureDiner: heureDiner ?? this.heureDiner,
    suiviCycle: suiviCycle ?? this.suiviCycle,
  );

  Map<String, dynamic> toJson() => {
    'masquerPoidsAccueil': masquerPoidsAccueil,
    'objectifVerres': objectifVerres,
    'theme': theme.name,
    'rappelsRepas': rappelsRepas,
    'heurePetitDejeuner': heurePetitDejeuner,
    'heureDejeuner': heureDejeuner,
    'heureDiner': heureDiner,
    'suiviCycle': suiviCycle,
  };

  factory Reglages.fromJson(Map<String, dynamic> json) => Reglages(
    masquerPoidsAccueil: json['masquerPoidsAccueil'] as bool? ?? false,
    objectifVerres: (json['objectifVerres'] as num?)?.toInt() ?? 8,
    theme: ThemeChoisi.depuisNom(json['theme'] as String?),
    rappelsRepas: json['rappelsRepas'] as bool? ?? true,
    heurePetitDejeuner: (json['heurePetitDejeuner'] as num?)?.toInt() ?? 8 * 60,
    heureDejeuner: (json['heureDejeuner'] as num?)?.toInt() ?? 13 * 60,
    heureDiner: (json['heureDiner'] as num?)?.toInt() ?? 20 * 60,
    suiviCycle: json['suiviCycle'] as bool? ?? false,
  );
}
