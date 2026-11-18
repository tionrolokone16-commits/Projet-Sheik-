/// Choix du thème d'affichage.
enum ThemeChoisi {
  systeme('Comme l\'appareil'),
  clair('Clair'),
  sombre('Sombre');

  const ThemeChoisi(this.libelle);
  final String libelle;

  static ThemeChoisi depuisNom(String? nom) => ThemeChoisi.values
      .firstWhere((t) => t.name == nom, orElse: () => ThemeChoisi.systeme);
}

/// Réglages de l'application.
class Reglages {
  const Reglages({
    this.masquerPoidsAccueil = false,
    this.objectifVerres = 8,
    this.theme = ThemeChoisi.systeme,
  });

  /// Si vrai, le poids n'apparaît pas sur l'écran d'accueil.
  final bool masquerPoidsAccueil;

  /// Nombre de verres d'eau visés chaque jour.
  final int objectifVerres;

  final ThemeChoisi theme;

  Reglages copyWith({
    bool? masquerPoidsAccueil,
    int? objectifVerres,
    ThemeChoisi? theme,
  }) =>
      Reglages(
        masquerPoidsAccueil: masquerPoidsAccueil ?? this.masquerPoidsAccueil,
        objectifVerres: objectifVerres ?? this.objectifVerres,
        theme: theme ?? this.theme,
      );

  Map<String, dynamic> toJson() => {
        'masquerPoidsAccueil': masquerPoidsAccueil,
        'objectifVerres': objectifVerres,
        'theme': theme.name,
      };

  factory Reglages.fromJson(Map<String, dynamic> json) => Reglages(
        masquerPoidsAccueil: json['masquerPoidsAccueil'] as bool? ?? false,
        objectifVerres: (json['objectifVerres'] as num?)?.toInt() ?? 8,
        theme: ThemeChoisi.depuisNom(json['theme'] as String?),
      );
}
