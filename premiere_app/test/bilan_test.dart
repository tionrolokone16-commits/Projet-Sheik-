import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/pesee.dart';
import 'package:premiere_app/models/plat.dart';
import 'package:premiere_app/models/progres.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/recompenses_provider.dart';
import 'package:premiere_app/screens/bilan_screen.dart';
import 'package:premiere_app/services/bilan_service.dart';
import 'package:premiere_app/services/recompenses_service.dart';

import 'outils.dart';

/// Tests du bilan de la semaine.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR')); // dates en français
  final lundi = DateTime(2026, 11, 16);
  DateTime jour(int i, [int h = 12]) => DateTime(2026, 11, 16 + i, h);

  RepasPhoto repas(int i, Repas moment, {int h = 13, Map<RessentiRepas, int> r = const {},
          Portions portions = Portions.equilibre, String nom = 'Attiéké poisson braisé'}) =>
      RepasPhoto(
        id: '$i-$h-${moment.name}',
        date: jour(i, h),
        repas: moment,
        portions: portions,
        nomPlat: nom,
        ressentis: r,
      );

  test('semaine par défaut : celle en cours le dimanche, sinon la précédente', () {
    expect(BilanService.semaineParDefaut(DateTime(2026, 11, 22)), lundi); // dimanche
    expect(BilanService.semaineParDefaut(DateTime(2026, 11, 25)), lundi); // mercredi suivant
  });

  test('ce qui s\'est bien passé', () {
    final journal = {
      for (var i = 0; i < 5; i++)
        '2026-11-${16 + i}': JourHabitudes(
          verres: 8,
          sommeilHeures: 7.5,
          repas: {Repas.petitDejeuner},
        ),
    };
    final bilan = BilanService.calculer(
      lundi: lundi,
      journal: journal,
      activites: [
        Activite(id: '1', date: jour(1), type: TypeActivite.marche, dureeMinutes: 30),
        Activite(id: '2', date: jour(3), type: TypeActivite.danse, dureeMinutes: 20),
      ],
      repasPhotos: [
        repas(0, Repas.dejeuner, r: {RessentiRepas.plaisir: 5}),
        repas(1, Repas.diner, h: 20),
        repas(9, Repas.diner), // hors de la semaine
      ],
      progres: Progres(),
      objectifVerres: 8,
    );
    final textes = bilan.reussites.map((l) => l.texte).toList();
    expect(textes, contains('2 repas notés'));
    expect(textes, contains('Petit-déjeuner pris 5 jours sur 7'));
    expect(textes, contains('Objectif d\'eau atteint 5 jours (40 verres en tout)'));
    expect(textes, contains('2 moments de mouvement, 50 min au total'));
    expect(textes, contains('5 nuits de 7 h ou plus'));
    expect(textes, contains('1 repas savouré avec plaisir'));
    expect(bilan.repas.length, 2);
  });

  test('constats : dîners tardifs, fringales et stress, petit-déjeuner rare', () {
    final journal = {
      for (var i = 0; i < 5; i++)
        '2026-11-${16 + i}': JourHabitudes(verres: 3, ressentis: {Ressenti.stress: 5}),
    };
    final progres = Progres(fringales: [jour(0, 16), jour(2, 17)]);
    final bilan = BilanService.calculer(
      lundi: lundi,
      journal: journal,
      activites: const [],
      repasPhotos: [for (var i = 0; i < 4; i++) repas(i, Repas.diner, h: 22)],
      progres: progres,
      objectifVerres: 8,
    );
    final constats = bilan.constats.map((l) => l.texte).toList();
    expect(constats, contains('Tu as souvent dîné après 21 h (4 soirs).'));
    expect(constats, contains('Les fringales sont surtout arrivées les jours de stress.'));
    expect(constats, contains('Le petit-déjeuner a été pris 0 jour sur 7.'));
    // Les idées liées aux constats sont proposées en premier.
    expect(bilan.ideesSuggerees,
        {IdeeSemaine.dinerPlusTot, IdeeSemaine.respiration, IdeeSemaine.prepPetitDej});
    expect(bilan.ideesProposees.take(3).toSet(), bilan.ideesSuggerees);
  });

  test('pas de constat avec trop peu de notes', () {
    final bilan = BilanService.calculer(
      lundi: lundi,
      journal: const {},
      activites: const [],
      repasPhotos: [repas(0, Repas.diner, h: 22)],
      progres: Progres(fringales: [jour(0, 16)]),
      objectifVerres: 8,
    );
    expect(bilan.constats, isEmpty);
  });

  test('vocabulaire interdit : ni compensation, ni échec, ni restriction', () {
    final bilan = BilanService.calculer(
      lundi: lundi,
      journal: {
        for (var i = 0; i < 5; i++)
          '2026-11-${16 + i}': const JourHabitudes(ressentis: {Ressenti.stress: 5}),
      },
      activites: const [],
      repasPhotos: [
        for (var i = 0; i < 4; i++)
          repas(i, Repas.diner,
              h: 22,
              r: {RessentiRepas.faim: 5},
              portions: Portions.normalisees(0, 1, 3)),
      ],
      progres: Progres(fringales: [jour(0, 16), jour(1, 17)]),
      objectifVerres: 8,
    );
    final tout = [
      ...bilan.reussites.map((l) => l.texte),
      ...bilan.constats.map((l) => l.texte),
      ...IdeeSemaine.values.map((i) => i.texte),
      BilanService.texteAPartager(bilan: bilan, prenom: 'Kira', ideesChoisies: IdeeSemaine.values),
    ].join(' ').toLowerCase();
    for (final mot in [
      'rembours', 'compens', 'échec', 'rattrap', 'restriction', 'interdit', 'calorie', 'kcal',
      'brûler', 'éliminer', 'trop mangé', 'écart',
    ]) {
      expect(tout, isNot(contains(mot)), reason: mot);
    }
  });

  test('texte à partager : repas, ressentis, et pesées seulement si demandées', () {
    final bilan = BilanService.calculer(
      lundi: lundi,
      journal: const {},
      activites: const [],
      repasPhotos: [
        repas(0, Repas.dejeuner, r: {RessentiRepas.satiete: 2}, nom: 'Placali sauce gombo'),
      ],
      progres: Progres(),
      objectifVerres: 8,
    );
    final pesee = Pesee(id: 'p', date: jour(2), poidsKg: 99.4);
    final sans = BilanService.texteAPartager(bilan: bilan, prenom: 'Kira', ideesChoisies: const []);
    expect(sans, contains('Placali sauce gombo'));
    expect(sans, contains('satiété après : juste bien'));
    expect(sans, isNot(contains('PESÉES')));

    final avec = BilanService.texteAPartager(
        bilan: bilan, prenom: 'Kira', ideesChoisies: const [], pesees: [pesee]);
    expect(avec, contains('99,4 kg'));
  });

  testWidgets('écran du bilan : choisir 2 idées au plus, pour la semaine suivante',
      (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    final acces = find.byKey(const Key('acces_bilans'));
    await tester.ensureVisible(acces);
    await tester.pumpAndSettle();
    await tester.tap(acces);
    await tester.pumpAndSettle();
    expect(find.byType(BilanScreen), findsOneWidget);
    expect(find.textContaining('page blanche'), findsOneWidget); // semaine vide, ton doux

    for (final idee in [IdeeSemaine.prepPetitDej, IdeeSemaine.legumes, IdeeSemaine.fruit]) {
      final case_ = find.byKey(Key('idee_${idee.name}'));
      await tester.ensureVisible(case_);
      await tester.pumpAndSettle();
      await tester.tap(case_);
      await tester.pumpAndSettle();
    }
    final lundiBilan = BilanService.semaineParDefaut(DateTime.now());
    final lundiSuivant = DateTime(lundiBilan.year, lundiBilan.month, lundiBilan.day + 7);
    final idees = RecompensesProvider(stockage).ideesDe(lundiSuivant);
    expect(idees, [IdeeSemaine.prepPetitDej.name, IdeeSemaine.legumes.name]); // 2 au plus
    expect(find.byKey(const Key('bouton_partager_bilan')), findsOneWidget);
    expect(find.byKey(const Key('bouton_copier_bilan')), findsOneWidget);
  });

  testWidgets('accueil : les idées choisies pour la semaine s\'affichent', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await RecompensesProvider(stockage)
        .basculerIdee(RecompensesService.debutSemaine(DateTime.now()), IdeeSemaine.fruit.name);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carte_idees_semaine'), skipOffstage: false), findsOneWidget);
  });
}
