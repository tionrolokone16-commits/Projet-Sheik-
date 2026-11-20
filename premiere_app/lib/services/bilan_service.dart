import 'package:intl/intl.dart';

import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/pesee.dart';
import '../models/plat.dart';
import '../models/progres.dart';
import '../models/repas_photo.dart';
import '../widgets/format.dart';
import 'habitudes_service.dart';
import 'recompenses_service.dart';
import 'stockage_service.dart';

/// Idées simples à essayer la semaine suivante (choisies par l'utilisatrice).
/// Aucune n'est une restriction, aucune n'est une réponse à un repas.
enum IdeeSemaine {
  prepPetitDej('🥐', 'Préparer mon petit-déjeuner la veille'),
  legumes('🥗', 'Ajouter des légumes à un repas par jour'),
  fruit('🍊', 'Prendre un fruit à 10 h ou à 16 h'),
  dinerPlusTot('🌙', 'Dîner un peu plus tôt, quand c\'est possible'),
  respiration('🫁', 'Une pause respiration les jours chargés'),
  eauReveil('💧', 'Un grand verre d\'eau au réveil'),
  sansEcran('🍽️', 'Un repas par jour sans écran, en prenant mon temps'),
  coucherTot('😴', 'Me coucher 30 minutes plus tôt'),
  bougerPlaisir('💃', 'Bouger 10 minutes pour le plaisir (danse, marche…)');

  const IdeeSemaine(this.emoji, this.texte);
  final String emoji;
  final String texte;

  static IdeeSemaine? depuisNom(String nom) {
    for (final i in values) {
      if (i.name == nom) return i;
    }
    return null;
  }
}

/// Une ligne du bilan : un emoji et une phrase.
typedef LigneBilan = ({String emoji, String texte});

/// Bilan d'une semaine (du lundi au dimanche).
class BilanSemaine {
  const BilanSemaine({
    required this.lundi,
    required this.reussites,
    required this.constats,
    required this.ideesProposees,
    required this.ideesSuggerees,
    required this.repas,
    this.habitudesParJour = const [0, 0, 0, 0, 0, 0, 0],
  });

  final DateTime lundi;
  DateTime get dimanche => DateTime(lundi.year, lundi.month, lundi.day + 6);

  /// Ce qui s'est bien passé (uniquement des éléments positifs).
  final List<LigneBilan> reussites;

  /// Tendances observées, présentées comme de simples constats.
  final List<LigneBilan> constats;

  /// Idées à proposer : celles liées aux constats d'abord, puis les autres.
  final List<IdeeSemaine> ideesProposees;

  /// Idées directement liées aux constats de la semaine.
  final Set<IdeeSemaine> ideesSuggerees;

  /// Repas notés pendant la semaine (pour le partage).
  final List<RepasPhoto> repas;

  /// Nombre d'habitudes prises en soin (0 à 4), du lundi au dimanche.
  final List<int> habitudesParJour;

  bool get estVide => reussites.isEmpty;
}

/// Calcul du bilan de la semaine et du texte à partager.
///
/// Interdits : parler de « remboursement », de « compensation », d'échec,
/// ou proposer du sport ou une restriction en réponse à un repas.
class BilanService {
  BilanService._();

  /// Semaine affichée par défaut : la semaine en cours le dimanche,
  /// sinon la dernière semaine complète.
  static DateTime semaineParDefaut(DateTime maintenant) {
    final lundi = RecompensesService.debutSemaine(maintenant);
    return maintenant.weekday == DateTime.sunday
        ? lundi
        : DateTime(lundi.year, lundi.month, lundi.day - 7);
  }

  static BilanSemaine calculer({
    required DateTime lundi,
    required Map<String, JourHabitudes> journal,
    required List<Activite> activites,
    required List<RepasPhoto> repasPhotos,
    required Progres progres,
    required int objectifVerres,
  }) {
    final jours = [for (var i = 0; i < 7; i++) DateTime(lundi.year, lundi.month, lundi.day + i)];
    final cles = {for (final j in jours) cleDuJour(j)};
    bool dansSemaine(DateTime d) => cles.contains(cleDuJour(d));
    JourHabitudes jour(DateTime d) => journal[cleDuJour(d)] ?? const JourHabitudes();

    final repas = repasPhotos.where((r) => dansSemaine(r.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final activitesSemaine = activites.where((a) => dansSemaine(a.date)).toList();
    final fringales = progres.fringales.where(dansSemaine).toList();

    final petitsDej = jours.where((d) => jour(d).repas.contains(Repas.petitDejeuner)).length;
    final joursEau = jours.where((d) => jour(d).verres >= objectifVerres).length;
    final verres = jours.fold<int>(0, (s, d) => s + jour(d).verres);
    final minutes = activitesSemaine.fold<int>(0, (s, a) => s + a.dureeMinutes);
    final nuits = jours.where((d) => jour(d).sommeilHeures != null).toList();
    final nuitsReparatrices = nuits
        .where((d) => jour(d).sommeilHeures! >= HabitudesService.sommeilReparateurHeures)
        .length;
    final plaisirs = repas.where((r) => (r.ressentis[RessentiRepas.plaisir] ?? 0) >= 4).length;
    final respirations = progres.respirations.where(dansSemaine).length;
    final victoires = progres.victoires.where((v) => dansSemaine(v.date)).length;
    final joursNotes = jours
        .where(
          (d) =>
              !jour(d).estVide ||
              activitesSemaine.any((a) => cleDuJour(a.date) == cleDuJour(d)) ||
              repas.any((r) => cleDuJour(r.date) == cleDuJour(d)),
        )
        .length;

    String pluriel(int n, String un, String plusieurs) => n > 1 ? plusieurs : un;

    // ----- Ce qui s'est bien passé -----
    final reussites = <LigneBilan>[
      if (repas.isNotEmpty)
        (
          emoji: '🍽️',
          texte: '${repas.length} ${pluriel(repas.length, 'repas noté', 'repas notés')}',
        ),
      if (petitsDej > 0)
        (
          emoji: '🥐',
          texte: 'Petit-déjeuner pris $petitsDej ${pluriel(petitsDej, 'jour', 'jours')} sur 7',
        ),
      if (joursEau > 0)
        (
          emoji: '💧',
          texte:
              'Objectif d\'eau atteint $joursEau ${pluriel(joursEau, 'jour', 'jours')} '
              '($verres verres en tout)',
        ),
      if (activitesSemaine.isNotEmpty)
        (
          emoji: '🚶',
          texte:
              '${activitesSemaine.length} ${pluriel(activitesSemaine.length, 'moment', 'moments')} '
              'de mouvement, ${HabitudesService.formaterMinutes(minutes)} au total',
        ),
      if (nuitsReparatrices > 0)
        (
          emoji: '🌙',
          texte:
              '$nuitsReparatrices ${pluriel(nuitsReparatrices, 'nuit', 'nuits')} '
              'de 7 h ou plus',
        ),
      if (plaisirs > 0)
        (
          emoji: '😋',
          texte: '$plaisirs ${pluriel(plaisirs, 'repas savouré', 'repas savourés')} avec plaisir',
        ),
      if (respirations > 0)
        (
          emoji: '🫁',
          texte: '$respirations ${pluriel(respirations, 'pause', 'pauses')} respiration',
        ),
      if (victoires > 0)
        (
          emoji: '🏆',
          texte: '$victoires ${pluriel(victoires, 'victoire', 'victoires')} hors balance',
        ),
    ];

    // ----- Constats (seulement avec assez de données) -----
    final constats = <LigneBilan>[];
    final suggerees = <IdeeSemaine>[];

    final dinersTardifs = repas.where((r) => r.repas == Repas.diner && r.date.hour >= 21).length;
    if (dinersTardifs >= 3) {
      constats.add((emoji: '🌙', texte: 'Tu as souvent dîné après 21 h ($dinersTardifs soirs).'));
      suggerees.add(IdeeSemaine.dinerPlusTot);
    }

    if (joursNotes >= 4 && petitsDej <= 2) {
      constats.add((
        emoji: '🥐',
        texte:
            'Le petit-déjeuner a été pris $petitsDej ${pluriel(petitsDej, 'jour', 'jours')} sur 7.',
      ));
      suggerees.add(IdeeSemaine.prepPetitDej);
    }

    // Fringales selon le petit-déjeuner (seulement parmi les jours notés).
    final joursAvecPetitDej = [
      for (final d in jours)
        if (jour(d).repas.contains(Repas.petitDejeuner)) cleDuJour(d),
    ];
    final joursSansPetitDej = [
      for (final d in jours)
        if (!jour(d).estVide && !jour(d).repas.contains(Repas.petitDejeuner)) cleDuJour(d),
    ];
    double parJour(List<String> cles) =>
        fringales.where((f) => cles.contains(cleDuJour(f))).length / cles.length;
    final fringalesSansPetitDej =
        fringales.length >= 2 &&
        joursAvecPetitDej.length >= 2 &&
        joursSansPetitDej.length >= 2 &&
        parJour(joursSansPetitDej) - parJour(joursAvecPetitDej) >= 0.5;
    if (fringalesSansPetitDej) {
      constats.add((
        emoji: '🥐',
        texte: 'Les fringales sont arrivées plus souvent les jours sans petit-déjeuner.',
      ));
      suggerees.add(IdeeSemaine.prepPetitDej);
    } else if (fringales.length >= 2) {
      final avecStress = [for (final f in fringales) ?jour(f).ressentis[Ressenti.stress]];
      final stresses = avecStress.where((s) => s >= 4).length;
      final tardives = fringales.where((f) => f.hour >= 15).length;
      if (avecStress.length >= 2 && stresses / avecStress.length >= 0.6) {
        constats.add((
          emoji: '💭',
          texte: 'Les fringales sont surtout arrivées les jours de stress.',
        ));
        suggerees.add(IdeeSemaine.respiration);
      } else if (tardives / fringales.length >= 0.6) {
        constats.add((
          emoji: '🕓',
          texte: 'Les fringales sont surtout arrivées en fin de journée.',
        ));
        suggerees.add(IdeeSemaine.fruit);
      }
    }

    final tresFaim = repas.where((r) => (r.ressentis[RessentiRepas.faim] ?? 0) >= 4).length;
    if (tresFaim >= 3) {
      constats.add((
        emoji: '😋',
        texte: 'Tu arrivais souvent aux repas avec très faim ($tresFaim fois).',
      ));
      suggerees.add(IdeeSemaine.fruit);
    }

    // Énergie selon la nuit : seulement si les deux cas existent.
    double? moyenneEnergie(bool reparatrice) {
      final valeurs = [
        for (final d in nuits)
          if ((jour(d).sommeilHeures! >= HabitudesService.sommeilReparateurHeures) == reparatrice)
            ?jour(d).ressentis[Ressenti.energie],
      ];
      return valeurs.isEmpty ? null : valeurs.reduce((a, b) => a + b) / valeurs.length;
    }

    final energieBonnesNuits = moyenneEnergie(true);
    final energieCourtesNuits = moyenneEnergie(false);
    if (energieBonnesNuits != null &&
        energieCourtesNuits != null &&
        energieBonnesNuits - energieCourtesNuits >= 1) {
      constats.add((
        emoji: '⚡',
        texte: 'Ton énergie était plus haute après les nuits de 7 h ou plus.',
      ));
      suggerees.add(IdeeSemaine.coucherTot);
    }

    final assiettes = repas.where((r) => r.portions.total > 0).toList();
    if (assiettes.length >= 4) {
      final legumes =
          assiettes.fold<double>(0, (s, r) => s + r.portions.legumes) / assiettes.length;
      if (legumes < 0.25) {
        constats.add((emoji: '🥗', texte: 'Les légumes ont été discrets dans tes assiettes.'));
        suggerees.add(IdeeSemaine.legumes);
      }
    }

    final proposees = <IdeeSemaine>{...suggerees, ...IdeeSemaine.values}.toList();

    return BilanSemaine(
      lundi: lundi,
      reussites: reussites,
      constats: constats,
      ideesProposees: proposees,
      ideesSuggerees: suggerees.toSet(),
      repas: repas,
      habitudesParJour: [
        for (final d in jours)
          HabitudesService.tenues(
            jour(d),
            activitesDuJour: [
              for (final a in activitesSemaine)
                if (cleDuJour(a.date) == cleDuJour(d)) a,
            ],
            objectifVerres: objectifVerres,
          ).length,
      ],
    );
  }

  // ------------------------------------------------- Texte à partager

  /// Résumé à partager avec la ou le nutritionniste (texte simple).
  static String texteAPartager({
    required BilanSemaine bilan,
    required String prenom,
    required List<IdeeSemaine> ideesChoisies,
    List<Pesee> pesees = const [],
  }) {
    final jourMois = DateFormat('d MMMM', 'fr_FR');
    final b = StringBuffer()
      ..writeln(
        'Bilan Kira\'s FAT — semaine du ${jourMois.format(bilan.lundi)} '
        'au ${jourMois.format(bilan.dimanche)} ${bilan.dimanche.year}',
      )
      ..writeln(prenom.isEmpty ? '' : 'Prénom : $prenom')
      ..writeln()
      ..writeln('CE QUI S\'EST BIEN PASSÉ');
    if (bilan.reussites.isEmpty) b.writeln('- Semaine peu notée');
    for (final l in bilan.reussites) {
      b.writeln('- ${l.texte}');
    }
    // Habitudes jour par jour : « lun. 3 · mar. 2 · … ».
    final jourSemaine = DateFormat('EEE', 'fr_FR');
    final parJour = [
      for (var i = 0; i < 7; i++)
        '${jourSemaine.format(bilan.lundi.add(Duration(days: i, hours: 12)))} '
            '${bilan.habitudesParJour[i]}',
    ];
    b.writeln('- Habitudes prises en soin (sur 4) : ${parJour.join(' · ')}');
    if (bilan.constats.isNotEmpty) {
      b
        ..writeln()
        ..writeln('CONSTATS');
      for (final l in bilan.constats) {
        b.writeln('- ${l.texte}');
      }
    }

    b
      ..writeln()
      ..writeln('JOURNAL DES REPAS');
    if (bilan.repas.isEmpty) b.writeln('- Aucun repas noté');
    final jourCourt = DateFormat('EEE d', 'fr_FR');
    final heure = DateFormat('HH:mm', 'fr_FR');
    String? jourPrecedent;
    for (final r in bilan.repas) {
      final j = jourCourt.format(r.date);
      if (j != jourPrecedent) {
        b.writeln(j);
        jourPrecedent = j;
      }
      final details = [
        'portion ${r.taille.libelle.toLowerCase()}',
        for (final e in r.ressentis.entries)
          '${e.key.libelle.toLowerCase()} : ${e.key.descriptions[e.value - 1].toLowerCase()}',
      ].join(', ');
      b.writeln('  ${heure.format(r.date)} ${r.repas.libelle} — ${r.titre} ($details)');
    }

    final peseesSemaine = pesees
        .where(
          (p) =>
              !p.date.isBefore(bilan.lundi) &&
              p.date.isBefore(bilan.dimanche.add(const Duration(days: 1))),
        )
        .toList();
    if (peseesSemaine.isNotEmpty) {
      b
        ..writeln()
        ..writeln('PESÉES');
      for (final p in peseesSemaine) {
        b.writeln(
          '- ${DateFormat('d/MM', 'fr_FR').format(p.date)} : ${formaterDecimal(p.poidsKg)} kg',
        );
      }
    }

    if (ideesChoisies.isNotEmpty) {
      b
        ..writeln()
        ..writeln('IDÉES CHOISIES POUR LA SEMAINE SUIVANTE');
      for (final i in ideesChoisies) {
        b.writeln('- ${i.texte}');
      }
    }

    b
      ..writeln()
      ..writeln(
        'Résumé préparé avec l\'application Kira\'s FAT, à partir de mes notes personnelles.',
      );
    return b.toString().replaceAll('\n\n\n', '\n\n');
  }
}
