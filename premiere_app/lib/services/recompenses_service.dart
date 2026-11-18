import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/pesee.dart';
import '../models/profil.dart';
import '../models/progres.dart';
import 'habitudes_service.dart';
import 'paliers_service.dart';
import 'plante_service.dart';
import 'stockage_service.dart';

/// Défis doux de la semaine. Chacun a un badge à collectionner.
/// Aucun défi ne récompense une restriction (manger moins, sauter un repas…).
enum Defi {
  petitsDejeuners('3 petits-déjeuners', '🥐', 3, 'Prendre le temps d\'un petit-déjeuner',
      'Matin gourmand'),
  renforcement('1 séance de renforcement', '💪', 1, 'Squats, gainage, pompes contre un mur…',
      'Force tranquille'),
  recetteIvoirienne('Une recette ivoirienne revisitée', '🍲', 1,
      'Cuisiner un plat de chez nous en version équilibrée', 'Toque d\'or',
      manuel: true),
  marches('3 marches de 20 min', '🚶', 3, 'Au marché, au bureau, au bord de l\'eau…',
      'Pas de velours'),
  hydratation('5 jours bien hydratés', '💧', 5, 'Atteindre ton objectif d\'eau 5 jours',
      'Source vive'),
  sommeil('4 nuits de 7 h', '🌙', 4, 'Offrir à ton corps des nuits réparatrices',
      'Marchand de sable'),
  legumes('Des légumes à 5 repas', '🥗', 5, 'Ajouter des légumes, même un peu',
      'Jardin dans l\'assiette',
      manuel: true),
  respirations('3 pauses respiration', '🫁', 3, 'Une minute pour soi, 3 fois',
      'Souffle zen'),
  journal('5 petits mots', '📝', 5, 'Écrire un petit mot dans ton journal 5 jours',
      'Plume douce'),
  danse('Danser 2 fois', '💃', 2, 'Sur ta chanson préférée, dans le salon !',
      'Pieds légers');

  const Defi(this.titre, this.emoji, this.cible, this.description, this.nomBadge,
      {this.manuel = false});

  final String titre;
  final String emoji;

  /// Nombre à atteindre dans la semaine.
  final int cible;
  final String description;
  final String nomBadge;

  /// Vrai si la progression se note à la main (sinon elle est calculée
  /// automatiquement à partir des habitudes et activités).
  final bool manuel;

  String get idBadge => 'defi_$name';

  static Defi? depuisNom(String nom) {
    for (final d in Defi.values) {
      if (d.name == nom) return d;
    }
    return null;
  }
}

/// Informations d'affichage d'un badge.
class InfoBadge {
  const InfoBadge(this.id, this.emoji, this.nom, this.description);
  final String id;
  final String emoji;
  final String nom;

  /// Comment l'obtenir (affiché aussi quand il reste à découvrir).
  final String description;
}

/// Un moment à célébrer (confettis + bannière).
class Evenement {
  const Evenement({
    required this.cle,
    required this.emoji,
    required this.titre,
    required this.message,
    this.idBadge,
  });

  /// Identifiant unique : un événement n'est célébré qu'une fois.
  final String cle;
  final String emoji;
  final String titre;
  final String message;

  /// Badge gagné à cette occasion (s'il ne l'est pas déjà).
  final String? idBadge;
}

/// Règles des badges, des défis et des célébrations.
class RecompensesService {
  RecompensesService._();

  /// Nombre maximum de défis choisis par semaine.
  static const defisMax = 3;

  /// Lundi de la semaine d'une date.
  static DateTime debutSemaine(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  static String cleSemaine(DateTime date) => cleDuJour(debutSemaine(date));

  /// Badges « fixes » (hors défis et paliers).
  static const badgesGeneraux = [
    InfoBadge('premiereGoutte', '💧', 'Première goutte', 'Prendre soin d\'une première habitude'),
    InfoBadge('premiereFleur', '🌸', 'Première fleur', 'Faire fleurir ta plante'),
    InfoBadge('semaineDouce', '🗓️', 'Semaine douce',
        'Prendre soin d\'au moins 2 habitudes chaque jour pendant une semaine'),
    InfoBadge('premiereVictoire', '🏆', 'Victoire hors balance',
        'Noter ta première victoire hors balance'),
    InfoBadge('premierePause', '🫁', 'Première pause', 'Terminer une minute de respiration'),
    InfoBadge('premiereSeance', '💃', 'Première séance', 'Terminer une séance guidée'),
  ];

  static InfoBadge badgePalier(int numero, {bool objectif = false}) => objectif
      ? const InfoBadge('objectif', '🎯', 'Objectif atteint', 'Atteindre ton objectif')
      : InfoBadge('palier_$numero', '⛰️', 'Palier $numero', 'Atteindre le palier $numero');

  static InfoBadge badgeDefi(Defi d) =>
      InfoBadge(d.idBadge, d.emoji, d.nomBadge, 'Réussir le défi « ${d.titre} »');

  /// Tous les badges à collectionner pour ce profil.
  static List<InfoBadge> catalogue(Profil? profil) => [
        ...badgesGeneraux,
        for (final d in Defi.values) badgeDefi(d),
        if (profil != null)
          for (final (i, _) in PaliersService.poidsPaliers(profil).indexed)
            badgePalier(i + 1,
                objectif: i == PaliersService.poidsPaliers(profil).length - 1),
      ];

  static InfoBadge? infoBadge(String id, Profil? profil) {
    for (final b in catalogue(profil)) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Progression d'un défi pendant la semaine qui commence le [lundi].
  static int progresDefi(
    Defi defi, {
    required DateTime lundi,
    required Map<String, JourHabitudes> journal,
    required List<Activite> activites,
    required Progres progres,
    required int objectifVerres,
  }) {
    final jours = [for (var i = 0; i < 7; i++) DateTime(lundi.year, lundi.month, lundi.day + i)];
    final cles = {for (final j in jours) cleDuJour(j)};
    JourHabitudes jour(DateTime d) => journal[cleDuJour(d)] ?? const JourHabitudes();
    final activitesSemaine = activites.where((a) => cles.contains(cleDuJour(a.date)));

    return switch (defi) {
      Defi.petitsDejeuners =>
        jours.where((d) => jour(d).repas.contains(Repas.petitDejeuner)).length,
      Defi.renforcement =>
        activitesSemaine.where((a) => a.type == TypeActivite.renforcement).length,
      Defi.marches => activitesSemaine
          .where((a) => a.type == TypeActivite.marche && a.dureeMinutes >= 20)
          .length,
      Defi.hydratation => jours.where((d) => jour(d).verres >= objectifVerres).length,
      Defi.sommeil => jours
          .where((d) =>
              (jour(d).sommeilHeures ?? 0) >= HabitudesService.sommeilReparateurHeures)
          .length,
      Defi.respirations =>
        progres.respirations.where((r) => cles.contains(cleDuJour(r))).length,
      Defi.journal => jours.where((d) => (jour(d).note ?? '').trim().isNotEmpty).length,
      Defi.danse => activitesSemaine.where((a) => a.type == TypeActivite.danse).length,
      Defi.recetteIvoirienne || Defi.legumes =>
        progres.defis[cleDuJour(lundi)]?[defi.name] ?? 0,
    };
  }

  /// Liste de tout ce qui mérite d'être célébré avec les données actuelles.
  /// Les événements déjà célébrés sont filtrés ensuite par le provider.
  static List<Evenement> evenements({
    required Map<String, JourHabitudes> journal,
    required List<Activite> activites,
    required int objectifVerres,
    required Progres progres,
    required Profil? profil,
    required List<Pesee> pesees,
    DateTime? maintenant,
  }) {
    final n = maintenant ?? DateTime.now();
    final aujourdhui = DateTime(n.year, n.month, n.day);
    final resultat = <Evenement>[];

    // ----- Plante -----
    final gouttes = PlanteService.gouttes(
        journal: journal, activites: activites, objectifVerres: objectifVerres);
    if (gouttes >= 1) {
      resultat.add(const Evenement(
        cle: 'premiereGoutte',
        emoji: '💧',
        titre: 'Première goutte !',
        message: 'Ta plante a reçu sa première goutte. Le voyage commence 🌱',
        idBadge: 'premiereGoutte',
      ));
    }
    if (PlanteService.stade(gouttes).index >= StadePlante.fleur.index) {
      resultat.add(const Evenement(
        cle: 'premiereFleur',
        emoji: '🌸',
        titre: 'Ta plante a fleuri !',
        message: 'Toutes ces petites habitudes ont fait éclore une fleur.',
        idBadge: 'premiereFleur',
      ));
    }

    // ----- Pauses et victoires -----
    if (progres.respirations.isNotEmpty) {
      resultat.add(const Evenement(
        cle: 'premierePause',
        emoji: '🫁',
        titre: 'Première pause respiration',
        message: 'Une minute rien que pour toi. Bravo !',
        idBadge: 'premierePause',
      ));
    }
    if (progres.victoires.isNotEmpty) {
      resultat.add(const Evenement(
        cle: 'premiereVictoire',
        emoji: '🏆',
        titre: 'Première victoire hors balance',
        message: 'Ces victoires-là comptent autant que les autres.',
        idBadge: 'premiereVictoire',
      ));
    }

    // ----- Semaines douces (8 dernières semaines) -----
    // Une semaine n'est célébrée qu'une fois terminée (le dimanche au plus tôt).
    final lundiActuel = debutSemaine(aujourdhui);
    for (var s = 0; s < 8; s++) {
      final lundi = DateTime(lundiActuel.year, lundiActuel.month, lundiActuel.day - 7 * s);
      final dimanche = DateTime(lundi.year, lundi.month, lundi.day + 6);
      if (dimanche.isAfter(aujourdhui)) continue;
      final complete = List.generate(7, (i) {
        final d = DateTime(lundi.year, lundi.month, lundi.day + i);
        return HabitudesService.tenues(
              journal[cleDuJour(d)] ?? const JourHabitudes(),
              activitesDuJour:
                  activites.where((a) => cleDuJour(a.date) == cleDuJour(d)).toList(),
              objectifVerres: objectifVerres,
            ).length >=
            2;
      }).every((ok) => ok);
      if (complete) {
        resultat.add(Evenement(
          cle: 'semaine:${cleDuJour(lundi)}',
          emoji: '🗓️',
          titre: 'Une semaine d\'habitudes tenues !',
          message: '7 jours à prendre soin de toi. Quelle belle régularité ✨',
          idBadge: 'semaineDouce',
        ));
      }
    }

    // ----- Défis réussis (semaine en cours et précédente) -----
    for (final lundi in [
      lundiActuel,
      DateTime(lundiActuel.year, lundiActuel.month, lundiActuel.day - 7),
    ]) {
      for (final id in (progres.defis[cleDuJour(lundi)] ?? const {}).keys) {
        final defi = Defi.depuisNom(id);
        if (defi == null) continue;
        final p = progresDefi(defi,
            lundi: lundi,
            journal: journal,
            activites: activites,
            progres: progres,
            objectifVerres: objectifVerres);
        if (p >= defi.cible) {
          resultat.add(Evenement(
            cle: 'defi:${cleDuJour(lundi)}:${defi.name}',
            emoji: defi.emoji,
            titre: 'Défi réussi : ${defi.titre}',
            message: 'Tu l\'as fait ! Prends un instant pour te féliciter 💗',
            idBadge: defi.idBadge,
          ));
        }
      }
    }

    // ----- Paliers -----
    if (profil != null && pesees.isNotEmpty) {
      final chemin = PaliersService.calculer(profil, pesees, maintenant: n);
      for (final p in chemin.paliers.where((p) => p.atteint)) {
        resultat.add(Evenement(
          cle: 'palier:${p.numero}',
          emoji: p.estObjectif ? '🎯' : '⛰️',
          titre: p.estObjectif ? 'Objectif atteint !' : 'Palier ${p.numero} atteint !',
          message: p.estObjectif
              ? 'Te voilà au bout du chemin… et le plus beau, ce sont toutes '
                  'les habitudes que tu as construites 🌸'
              : 'Place à 2 semaines de stabilisation : garde tes habitudes, '
                  'ton corps s\'installe dans son nouvel équilibre 🌿',
          idBadge: badgePalier(p.numero, objectif: p.estObjectif).id,
        ));
      }
    }
    return resultat;
  }
}
