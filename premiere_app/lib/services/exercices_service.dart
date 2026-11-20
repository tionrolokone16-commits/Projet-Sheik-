import 'dart:ui';

import '../models/exercice.dart';

/// Bibliothèque d'exercices débutant et séances guidées.
///
/// Bouger pour le plaisir, à son rythme : les séances sont proposées selon
/// l'énergie et le stress du jour, jamais selon ce qui a été mangé.
class ExercicesService {
  ExercicesService._();

  // ----------------------------------------------------- Poses de base

  /// Debout, bras le long du corps.
  static const _debout = Pose(
    tete: Offset(50, 12),
    cou: Offset(50, 22),
    hanche: Offset(50, 52),
    genouA: Offset(51, 72),
    piedA: Offset(52, 93),
    genouB: Offset(49, 72),
    piedB: Offset(48, 93),
    coudeA: Offset(52, 37),
    mainA: Offset(53, 51),
    coudeB: Offset(48, 37),
    mainB: Offset(47, 51),
  );

  // ------------------------------------------------------- Exercices

  static const squat = Exercice(
    id: 'squat',
    nom: 'Squat',
    emoji: '🪑',
    niveau: NiveauExercice.facile,
    zone: 'Jambes et fessiers',
    etapes: [
      'Debout, pieds écartés de la largeur du bassin.',
      'Pousse les fesses en arrière comme pour t\'asseoir, bras devant toi.',
      'Remonte en poussant dans les talons.',
    ],
    conseil: 'Garde le dos droit et les genoux dans l\'axe des pieds. Expire en remontant.',
    versionDouce: 'Descends seulement à moitié, ou assieds-toi vraiment sur une chaise.',
    poseDepart: Pose(
      tete: Offset(50, 12),
      cou: Offset(50, 22),
      hanche: Offset(50, 52),
      genouA: Offset(51, 72),
      piedA: Offset(52, 93),
      genouB: Offset(49, 72),
      piedB: Offset(48, 93),
      coudeA: Offset(62, 25),
      mainA: Offset(74, 25),
      coudeB: Offset(60, 27),
      mainB: Offset(72, 27),
    ),
    poseArrivee: Pose(
      tete: Offset(46, 34),
      cou: Offset(47, 44),
      hanche: Offset(36, 68),
      genouA: Offset(58, 70),
      piedA: Offset(53, 93),
      genouB: Offset(56, 72),
      piedB: Offset(50, 93),
      coudeA: Offset(60, 44),
      mainA: Offset(72, 44),
      coudeB: Offset(58, 46),
      mainB: Offset(70, 46),
    ),
  );

  static const pontFessier = Exercice(
    id: 'pont',
    nom: 'Pont fessier',
    emoji: '🌉',
    niveau: NiveauExercice.facile,
    zone: 'Fessiers et bas du dos',
    etapes: [
      'Sur le dos, genoux pliés, pieds à plat au sol.',
      'Soulève doucement le bassin en serrant les fessiers.',
      'Redescends lentement, vertèbre par vertèbre.',
    ],
    conseil: 'Les épaules restent au sol. Expire en montant, inspire en descendant.',
    versionDouce: 'Monte le bassin seulement de quelques centimètres.',
    poseDepart: Pose(
      tete: Offset(12, 86),
      cou: Offset(21, 87),
      hanche: Offset(48, 89),
      genouA: Offset(62, 67),
      piedA: Offset(74, 93),
      genouB: Offset(60, 69),
      piedB: Offset(72, 93),
      coudeA: Offset(30, 91),
      mainA: Offset(41, 92),
      coudeB: Offset(30, 92),
      mainB: Offset(41, 93),
    ),
    poseArrivee: Pose(
      tete: Offset(12, 86),
      cou: Offset(21, 85),
      hanche: Offset(46, 68),
      genouA: Offset(65, 62),
      piedA: Offset(74, 93),
      genouB: Offset(63, 63),
      piedB: Offset(72, 93),
      coudeA: Offset(30, 91),
      mainA: Offset(41, 92),
      coudeB: Offset(30, 92),
      mainB: Offset(41, 93),
    ),
  );

  static const pompesMur = Exercice(
    id: 'pompes_mur',
    nom: 'Pompes contre le mur',
    emoji: '🧱',
    niveau: NiveauExercice.facile,
    zone: 'Bras et poitrine',
    etapes: [
      'Face au mur, mains posées à hauteur d\'épaules.',
      'Plie les coudes pour rapprocher la poitrine du mur.',
      'Pousse pour revenir, le corps bien droit.',
    ],
    conseil: 'Le corps reste gainé comme une planche. Expire en poussant.',
    versionDouce: 'Rapproche les pieds du mur : c\'est plus facile.',
    mur: true,
    poseDepart: Pose(
      tete: Offset(63, 19),
      cou: Offset(59, 27),
      hanche: Offset(43, 58),
      genouA: Offset(37, 76),
      piedA: Offset(31, 93),
      genouB: Offset(36, 76),
      piedB: Offset(29, 93),
      coudeA: Offset(72, 29),
      mainA: Offset(84, 30),
      coudeB: Offset(71, 31),
      mainB: Offset(84, 32),
    ),
    poseArrivee: Pose(
      tete: Offset(72, 22),
      cou: Offset(67, 30),
      hanche: Offset(48, 59),
      genouA: Offset(40, 77),
      piedA: Offset(31, 93),
      genouB: Offset(39, 77),
      piedB: Offset(29, 93),
      coudeA: Offset(72, 42),
      mainA: Offset(84, 30),
      coudeB: Offset(70, 43),
      mainB: Offset(84, 32),
    ),
  );

  static const gainage = Exercice(
    id: 'gainage',
    nom: 'Gainage sur les genoux',
    emoji: '🧘🏾‍♀️',
    niveau: NiveauExercice.moyen,
    zone: 'Ventre et dos',
    etapes: [
      'Avant-bras au sol, coudes sous les épaules, genoux posés.',
      'Aligne la tête, le dos et les fesses.',
      'Tiens la position en respirant calmement.',
    ],
    conseil: 'Ne bloque pas ta respiration. Rentre doucement le nombril.',
    versionDouce: 'Tiens 10 secondes, repose-toi, recommence.',
    poseDepart: Pose(
      tete: Offset(80, 63),
      cou: Offset(72, 68),
      hanche: Offset(42, 76),
      genouA: Offset(28, 91),
      piedA: Offset(12, 86),
      genouB: Offset(27, 92),
      piedB: Offset(11, 87),
      coudeA: Offset(70, 91),
      mainA: Offset(82, 92),
      coudeB: Offset(69, 92),
      mainB: Offset(81, 93),
    ),
    poseArrivee: Pose(
      tete: Offset(80, 62),
      cou: Offset(72, 67),
      hanche: Offset(42, 74),
      genouA: Offset(28, 91),
      piedA: Offset(12, 86),
      genouB: Offset(27, 92),
      piedB: Offset(11, 87),
      coudeA: Offset(70, 91),
      mainA: Offset(82, 92),
      coudeB: Offset(69, 92),
      mainB: Offset(81, 93),
    ),
  );

  static const fentes = Exercice(
    id: 'fentes',
    nom: 'Fentes arrière',
    emoji: '🦵',
    niveau: NiveauExercice.moyen,
    zone: 'Cuisses et équilibre',
    etapes: [
      'Debout, mains sur les hanches.',
      'Fais un grand pas en arrière et plie les deux genoux.',
      'Reviens en poussant sur la jambe avant, puis change de côté.',
    ],
    conseil: 'Le genou avant reste au-dessus de la cheville. Tiens-toi à une chaise si besoin.',
    versionDouce: 'Fais un plus petit pas, sans descendre trop bas.',
    poseDepart: Pose(
      tete: Offset(50, 12),
      cou: Offset(50, 22),
      hanche: Offset(50, 52),
      genouA: Offset(51, 72),
      piedA: Offset(52, 93),
      genouB: Offset(49, 72),
      piedB: Offset(48, 93),
      coudeA: Offset(41, 39),
      mainA: Offset(49, 50),
      coudeB: Offset(59, 39),
      mainB: Offset(52, 50),
    ),
    poseArrivee: Pose(
      tete: Offset(49, 24),
      cou: Offset(49, 34),
      hanche: Offset(47, 63),
      genouA: Offset(63, 73),
      piedA: Offset(65, 93),
      genouB: Offset(37, 88),
      piedB: Offset(24, 92),
      coudeA: Offset(40, 50),
      mainA: Offset(47, 61),
      coudeB: Offset(57, 50),
      mainB: Offset(50, 61),
    ),
  );

  static const marcheSurPlace = Exercice(
    id: 'marche',
    nom: 'Marche sur place',
    emoji: '🚶🏾‍♀️',
    niveau: NiveauExercice.facile,
    zone: 'Cœur et souffle',
    etapes: [
      'Debout, marche sur place en levant les genoux.',
      'Balance les bras en rythme.',
      'Trouve un rythme agréable, sans te presser.',
    ],
    conseil: 'Mets ta chanson préférée : ça passe tout seul !',
    versionDouce: 'Lève à peine les pieds, ou marche assise sur une chaise.',
    poseDepart: Pose(
      tete: Offset(50, 12),
      cou: Offset(50, 22),
      hanche: Offset(50, 52),
      genouA: Offset(63, 63),
      piedA: Offset(60, 81),
      genouB: Offset(50, 72),
      piedB: Offset(50, 93),
      coudeA: Offset(45, 37),
      mainA: Offset(40, 50),
      coudeB: Offset(57, 36),
      mainB: Offset(62, 46),
    ),
    poseArrivee: Pose(
      tete: Offset(50, 12),
      cou: Offset(50, 22),
      hanche: Offset(50, 52),
      genouA: Offset(51, 72),
      piedA: Offset(51, 93),
      genouB: Offset(62, 63),
      piedB: Offset(59, 81),
      coudeA: Offset(57, 36),
      mainA: Offset(62, 46),
      coudeB: Offset(45, 37),
      mainB: Offset(40, 50),
    ),
  );

  static const brasCiel = Exercice(
    id: 'bras_ciel',
    nom: 'Bras vers le ciel',
    emoji: '🙆🏾‍♀️',
    niveau: NiveauExercice.facile,
    zone: 'Étirement du dos',
    etapes: [
      'Debout, inspire en levant les bras au-dessus de la tête.',
      'Grandis-toi, monte sur la pointe des pieds si tu veux.',
      'Expire en redescendant les bras doucement.',
    ],
    conseil: 'Un mouvement lent, au rythme de ta respiration.',
    versionDouce: 'Reste à plat sur tes pieds, lève les bras à mi-hauteur.',
    poseDepart: _debout,
    poseArrivee: Pose(
      tete: Offset(50, 10),
      cou: Offset(50, 20),
      hanche: Offset(50, 50),
      genouA: Offset(51, 70),
      piedA: Offset(53, 91),
      genouB: Offset(49, 70),
      piedB: Offset(49, 91),
      coudeA: Offset(60, 11),
      mainA: Offset(62, 1),
      coudeB: Offset(58, 12),
      mainB: Offset(60, 2),
    ),
  );

  static const cerclesBras = Exercice(
    id: 'cercles_bras',
    nom: 'Cercles de bras',
    emoji: '🌀',
    niveau: NiveauExercice.facile,
    zone: 'Épaules',
    etapes: [
      'Debout, bras tendus devant toi.',
      'Monte les bras au-dessus de la tête, puis redescends-les.',
      'Garde un mouvement souple et ample.',
    ],
    conseil: 'Relâche les épaules, elles ne montent pas vers les oreilles.',
    versionDouce: 'Fais de petits mouvements, coudes un peu pliés.',
    poseDepart: Pose(
      tete: Offset(50, 12),
      cou: Offset(50, 22),
      hanche: Offset(50, 52),
      genouA: Offset(51, 72),
      piedA: Offset(52, 93),
      genouB: Offset(49, 72),
      piedB: Offset(48, 93),
      coudeA: Offset(62, 25),
      mainA: Offset(74, 25),
      coudeB: Offset(60, 27),
      mainB: Offset(72, 27),
    ),
    poseArrivee: Pose(
      tete: Offset(50, 12),
      cou: Offset(50, 22),
      hanche: Offset(50, 52),
      genouA: Offset(51, 72),
      piedA: Offset(52, 93),
      genouB: Offset(49, 72),
      piedB: Offset(48, 93),
      coudeA: Offset(60, 12),
      mainA: Offset(63, 1),
      coudeB: Offset(58, 13),
      mainB: Offset(61, 2),
    ),
  );

  static const exercices = [
    squat,
    pontFessier,
    pompesMur,
    gainage,
    fentes,
    marcheSurPlace,
    brasCiel,
    cerclesBras,
  ];

  // --------------------------------------------------------- Séances

  static const detente = Seance(
    id: 'detente',
    nom: 'Détente',
    emoji: '🌿',
    description: 'Des mouvements lents pour se relâcher.',
    niveau: NiveauExercice.facile,
    reposSecondes: 15,
    etapes: [
      EtapeSeance(brasCiel, 40),
      EtapeSeance(cerclesBras, 40),
      EtapeSeance(marcheSurPlace, 40),
      EtapeSeance(brasCiel, 40),
    ],
  );

  static const reveil = Seance(
    id: 'reveil',
    nom: 'Réveil en douceur',
    emoji: '☀️',
    description: 'Pour réveiller le corps tranquillement.',
    niveau: NiveauExercice.facile,
    reposSecondes: 20,
    etapes: [
      EtapeSeance(marcheSurPlace, 40),
      EtapeSeance(squat, 30),
      EtapeSeance(cerclesBras, 30),
      EtapeSeance(pontFessier, 30),
      EtapeSeance(brasCiel, 30),
    ],
  );

  static const renfoDoux = Seance(
    id: 'renfo',
    nom: 'Renfo doux',
    emoji: '💪🏾',
    description: 'Renforcer tout le corps, en douceur.',
    niveau: NiveauExercice.facile,
    reposSecondes: 20,
    etapes: [
      EtapeSeance(squat, 40),
      EtapeSeance(pompesMur, 40),
      EtapeSeance(pontFessier, 40),
      EtapeSeance(gainage, 30),
      EtapeSeance(squat, 40),
      EtapeSeance(pompesMur, 40),
      EtapeSeance(pontFessier, 40),
    ],
  );

  static const seanceEnergie = Seance(
    id: 'energie',
    nom: 'Énergie',
    emoji: '⚡',
    description: 'Une séance plus tonique pour les jours en forme.',
    niveau: NiveauExercice.moyen,
    reposSecondes: 15,
    etapes: [
      EtapeSeance(marcheSurPlace, 45),
      EtapeSeance(squat, 45),
      EtapeSeance(fentes, 45),
      EtapeSeance(pompesMur, 45),
      EtapeSeance(gainage, 40),
      EtapeSeance(pontFessier, 45),
      EtapeSeance(marcheSurPlace, 45),
      EtapeSeance(squat, 45),
      EtapeSeance(fentes, 45),
      EtapeSeance(pompesMur, 45),
    ],
  );

  static const seances = [detente, reveil, renfoDoux, seanceEnergie];

  /// Séance courte avec un seul exercice (« Essayer 30 secondes »).
  static Seance essai(Exercice e) => Seance(
    id: 'essai_${e.id}',
    nom: e.nom,
    emoji: e.emoji,
    description: 'Un essai de 30 secondes.',
    niveau: e.niveau,
    reposSecondes: 0,
    etapes: [EtapeSeance(e, 30)],
  );

  /// Séance proposée pour une journée, selon le planning de la semaine,
  /// l'énergie, le stress et l'humeur. Jamais selon les repas.
  ///
  /// `seance` est `null` quand il manque l'énergie du jour (on la demande).
  /// Toujours une invitation, jamais une obligation.
  static ({Seance? seance, String raison}) proposerDuJour({
    required DateTime date,
    required Set<int> joursSeance,
    int? energie,
    int? stress,
    double? humeur,
    bool dejaBouge = false,
  }) {
    if (dejaBouge) {
      return (
        seance: detente,
        raison: 'Tu as déjà bougé aujourd\'hui, bravo 🌸 Si l\'envie est là, un moment de détente.',
      );
    }
    final avecPlanning = joursSeance.isNotEmpty;
    final prevu = joursSeance.contains(date.weekday);
    if (avecPlanning && !prevu) {
      return (
        seance: detente,
        raison: 'Pas de séance prévue aujourd\'hui : repos ou petite détente, comme tu le sens 🌿',
      );
    }
    final entree = prevu ? 'C\'est un de tes jours de séance 📅 ' : '';
    if (energie == null) {
      return (
        seance: null,
        raison: '${entree}Comment est ton énergie ? Je te propose une séance adaptée.',
      );
    }
    final base = proposer(energie: energie, stress: stress)!;
    if (humeur != null && humeur < 2.5 && base.seance != detente) {
      return (
        seance: detente,
        raison: '${entree}Le moral est un peu bas : un moment doux pour prendre soin de toi 🌿',
      );
    }
    return (seance: base.seance, raison: '$entree${base.raison}');
  }

  /// Séance proposée selon l'énergie et le stress du jour (de 1 à 5).
  /// Jamais selon les repas. Renvoie `null` si l'énergie n'est pas notée.
  static ({Seance seance, String raison})? proposer({int? energie, int? stress}) {
    if (energie == null) return null;
    if (energie <= 2 || (stress ?? 0) >= 4) {
      return (seance: detente, raison: 'Journée chargée ou énergie basse : place à la douceur 🌿');
    }
    if (energie == 3) {
      return (
        seance: reveil,
        raison: 'Une énergie tranquille : on réveille le corps en douceur ☀️',
      );
    }
    if (energie == 4) {
      return (
        seance: renfoDoux,
        raison: 'Belle énergie aujourd\'hui : un peu de renfo, si ça te dit 💪🏾',
      );
    }
    return (seance: seanceEnergie, raison: 'Énergie au top : profite-en pour une séance tonique ⚡');
  }
}
