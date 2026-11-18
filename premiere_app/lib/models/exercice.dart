import 'dart:ui';

/// Niveau d'un exercice ou d'une séance.
enum NiveauExercice {
  facile('Facile', '🌱'),
  moyen('Moyen', '🌿');

  const NiveauExercice(this.libelle, this.emoji);
  final String libelle;
  final String emoji;
}

/// Une pose de la figurine : position des articulations dans une boîte
/// de 100 × 100 (vue de profil, tournée vers la droite, sol à y = 95).
///
/// « A » désigne le membre le plus proche, « B » le plus éloigné.
class Pose {
  const Pose({
    required this.tete,
    required this.cou,
    required this.hanche,
    required this.genouA,
    required this.piedA,
    required this.genouB,
    required this.piedB,
    required this.coudeA,
    required this.mainA,
    required this.coudeB,
    required this.mainB,
  });

  final Offset tete;
  final Offset cou;
  final Offset hanche;
  final Offset genouA;
  final Offset piedA;
  final Offset genouB;
  final Offset piedB;
  final Offset coudeA;
  final Offset mainA;
  final Offset coudeB;
  final Offset mainB;

  /// Pose intermédiaire entre deux poses (t de 0 à 1).
  static Pose lerp(Pose a, Pose b, double t) {
    Offset l(Offset x, Offset y) => Offset.lerp(x, y, t)!;
    return Pose(
      tete: l(a.tete, b.tete),
      cou: l(a.cou, b.cou),
      hanche: l(a.hanche, b.hanche),
      genouA: l(a.genouA, b.genouA),
      piedA: l(a.piedA, b.piedA),
      genouB: l(a.genouB, b.genouB),
      piedB: l(a.piedB, b.piedB),
      coudeA: l(a.coudeA, b.coudeA),
      mainA: l(a.mainA, b.mainA),
      coudeB: l(a.coudeB, b.coudeB),
      mainB: l(a.mainB, b.mainB),
    );
  }
}

/// Un exercice de la bibliothèque.
class Exercice {
  const Exercice({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.niveau,
    required this.zone,
    required this.etapes,
    required this.conseil,
    required this.versionDouce,
    required this.poseDepart,
    required this.poseArrivee,
    this.mur = false,
  });

  final String id;
  final String nom;
  final String emoji;
  final NiveauExercice niveau;

  /// Partie du corps travaillée (« Jambes et fessiers »…).
  final String zone;

  /// Explications simples, pas à pas.
  final List<String> etapes;

  /// Conseil de sécurité ou de respiration.
  final String conseil;

  /// Variante plus facile, pour adapter à son corps du jour.
  final String versionDouce;

  /// Les deux poses entre lesquelles la figurine va et vient.
  final Pose poseDepart;
  final Pose poseArrivee;

  /// Dessiner un mur (pour les pompes contre le mur).
  final bool mur;
}

/// Une étape d'une séance guidée : un exercice pendant un certain temps.
class EtapeSeance {
  const EtapeSeance(this.exercice, this.secondes);
  final Exercice exercice;
  final int secondes;
}

/// Une séance guidée : une suite d'exercices avec des temps de repos.
class Seance {
  const Seance({
    required this.id,
    required this.nom,
    required this.emoji,
    required this.description,
    required this.niveau,
    required this.etapes,
    required this.reposSecondes,
  });

  final String id;
  final String nom;
  final String emoji;
  final String description;
  final NiveauExercice niveau;
  final List<EtapeSeance> etapes;
  final int reposSecondes;

  /// Durée totale (efforts + repos entre les exercices), en secondes.
  int get dureeSecondes =>
      etapes.fold<int>(0, (s, e) => s + e.secondes) + reposSecondes * (etapes.length - 1);

  /// Durée arrondie à la minute, au moins 1.
  int get dureeMinutes => (dureeSecondes / 60).round().clamp(1, 999);
}
