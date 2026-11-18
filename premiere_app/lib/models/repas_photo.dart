import 'jour_habitudes.dart';
import 'recette.dart';

/// Un repas noté avec (ou sans) photo, et la répartition de son assiette.
class RepasPhoto {
  const RepasPhoto({
    required this.id,
    required this.date,
    required this.repas,
    required this.portions,
    this.photoBase64,
  });

  final String id;
  final DateTime date;
  final Repas repas;
  final Portions portions;

  /// Photo réduite, encodée en texte (base64). `null` si pas de photo
  /// ou si la photo a été retirée pour faire de la place.
  final String? photoBase64;

  RepasPhoto sansPhoto() =>
      RepasPhoto(id: id, date: date, repas: repas, portions: portions);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'repas': repas.name,
        'legumes': portions.legumes,
        'proteines': portions.proteines,
        'feculents': portions.feculents,
        if (photoBase64 != null) 'photo': photoBase64,
      };

  factory RepasPhoto.fromJson(Map<String, dynamic> json) => RepasPhoto(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        repas: Repas.values.firstWhere((r) => r.name == json['repas'],
            orElse: () => Repas.dejeuner),
        portions: Portions(
          legumes: (json['legumes'] as num).toDouble(),
          proteines: (json['proteines'] as num).toDouble(),
          feculents: (json['feculents'] as num).toDouble(),
        ),
        photoBase64: json['photo'] as String?,
      );
}
