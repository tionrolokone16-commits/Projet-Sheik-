/// Types d'activité proposés, avec un emoji pour un affichage chaleureux.
enum TypeActivite {
  marche('Marche', '🚶'),
  course('Course', '🏃'),
  velo('Vélo', '🚴'),
  natation('Natation', '🏊'),
  yoga('Yoga / étirements', '🧘'),
  renforcement('Renforcement', '💪'),
  danse('Danse', '💃'),
  autre('Autre', '✨');

  const TypeActivite(this.libelle, this.emoji);

  final String libelle;
  final String emoji;

  static TypeActivite depuisNom(String? nom) => TypeActivite.values
      .firstWhere((t) => t.name == nom, orElse: () => TypeActivite.autre);
}

/// Une activité physique enregistrée (marche, séance de sport…).
class Activite {
  const Activite({
    required this.id,
    required this.date,
    required this.type,
    required this.dureeMinutes,
    this.note,
  });

  final String id;
  final DateTime date;
  final TypeActivite type;
  final int dureeMinutes;

  /// Petite note libre facultative (« balade au parc », etc.).
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type.name,
        'dureeMinutes': dureeMinutes,
        if (note != null) 'note': note,
      };

  factory Activite.fromJson(Map<String, dynamic> json) => Activite(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        type: TypeActivite.depuisNom(json['type'] as String?),
        dureeMinutes: (json['dureeMinutes'] as num).toInt(),
        note: json['note'] as String?,
      );
}
