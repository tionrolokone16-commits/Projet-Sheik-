/// Modèle du profil de l'utilisateur.
///
/// Toutes les données restent sur l'appareil (stockage local).
library;

/// Niveau d'activité physique, avec le coefficient utilisé pour estimer
/// la dépense énergétique journalière (DEJ = métabolisme de base × coefficient).
enum NiveauActivite {
  sedentaire('Sédentaire', 'Peu ou pas d\'activité', 1.2),
  leger('Légèrement actif', '1 à 3 séances par semaine', 1.375),
  modere('Modérément actif', '3 à 5 séances par semaine', 1.55),
  actif('Actif', '6 à 7 séances par semaine', 1.725),
  tresActif('Très actif', 'Travail physique ou sport intense', 1.9);

  const NiveauActivite(this.libelle, this.description, this.coefficient);

  final String libelle;
  final String description;
  final double coefficient;

  /// Retrouve un niveau à partir de son nom stocké (valeur par défaut : léger).
  static NiveauActivite depuisNom(String? nom) => NiveauActivite.values
      .firstWhere((n) => n.name == nom, orElse: () => NiveauActivite.leger);
}

/// Sexe utilisé uniquement par la formule de Mifflin-St Jeor.
/// « Non précisé » utilise la moyenne des deux constantes.
enum Sexe {
  femme('Femme', -161),
  homme('Homme', 5),
  nonPrecise('Je préfère ne pas préciser', -78);

  const Sexe(this.libelle, this.constanteMifflin);

  final String libelle;

  /// Constante ajoutée dans la formule de Mifflin-St Jeor.
  final double constanteMifflin;

  static Sexe depuisNom(String? nom) =>
      Sexe.values.firstWhere((s) => s.name == nom, orElse: () => Sexe.nonPrecise);
}

class Profil {
  const Profil({
    required this.prenom,
    required this.age,
    required this.tailleCm,
    required this.poidsDepartKg,
    required this.poidsObjectifKg,
    required this.niveauActivite,
    this.sexe = Sexe.nonPrecise,
    this.photoBase64,
  });

  final String prenom;
  final int age;
  final double tailleCm;
  final double poidsDepartKg;
  final double poidsObjectifKg;
  final NiveauActivite niveauActivite;
  final Sexe sexe;

  /// Photo de profil réduite, encodée en texte (base64). Elle reste sur
  /// l'appareil, comme toutes les autres données. `null` si aucune photo.
  final String? photoBase64;

  Profil copyWith({
    String? prenom,
    int? age,
    double? tailleCm,
    double? poidsDepartKg,
    double? poidsObjectifKg,
    NiveauActivite? niveauActivite,
    Sexe? sexe,
    String? photoBase64,
    bool retirerPhoto = false,
  }) {
    return Profil(
      prenom: prenom ?? this.prenom,
      age: age ?? this.age,
      tailleCm: tailleCm ?? this.tailleCm,
      poidsDepartKg: poidsDepartKg ?? this.poidsDepartKg,
      poidsObjectifKg: poidsObjectifKg ?? this.poidsObjectifKg,
      niveauActivite: niveauActivite ?? this.niveauActivite,
      sexe: sexe ?? this.sexe,
      photoBase64: retirerPhoto ? null : (photoBase64 ?? this.photoBase64),
    );
  }

  Map<String, dynamic> toJson() => {
        'prenom': prenom,
        'age': age,
        'tailleCm': tailleCm,
        'poidsDepartKg': poidsDepartKg,
        'poidsObjectifKg': poidsObjectifKg,
        'niveauActivite': niveauActivite.name,
        'sexe': sexe.name,
        if (photoBase64 != null) 'photo': photoBase64,
      };

  factory Profil.fromJson(Map<String, dynamic> json) {
    return Profil(
      prenom: json['prenom'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 30,
      tailleCm: (json['tailleCm'] as num?)?.toDouble() ?? 165,
      poidsDepartKg: (json['poidsDepartKg'] as num?)?.toDouble() ?? 70,
      poidsObjectifKg: (json['poidsObjectifKg'] as num?)?.toDouble() ?? 65,
      niveauActivite: NiveauActivite.depuisNom(json['niveauActivite'] as String?),
      sexe: Sexe.depuisNom(json['sexe'] as String?),
      photoBase64: json['photo'] as String?,
    );
  }
}
