import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/recompenses_provider.dart';
import 'package:premiere_app/screens/accueil_screen.dart';
import 'package:premiere_app/screens/exercices_screen.dart';
import 'package:premiere_app/screens/seance_screen.dart';
import 'package:premiere_app/services/exercices_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Tests des exercices illustrés et des séances guidées.
void main() {
  group('bibliothèque', () {
    test('exercices complets, identifiants uniques', () {
      expect(ExercicesService.exercices.length, greaterThanOrEqualTo(8));
      final ids = <String>{};
      for (final e in ExercicesService.exercices) {
        expect(ids.add(e.id), isTrue, reason: e.id);
        expect(e.etapes.length, 3, reason: e.nom);
        expect(e.versionDouce, isNotEmpty);
      }
    });

    test('durées des séances', () {
      expect(ExercicesService.detente.dureeSecondes, 4 * 40 + 3 * 15);
      expect(ExercicesService.essai(ExercicesService.squat).dureeSecondes, 30);
      for (final s in ExercicesService.seances) {
        expect(s.dureeMinutes, inInclusiveRange(1, 15), reason: s.nom);
      }
    });

    test('proposition selon l\'énergie et le stress, jamais selon les repas', () {
      expect(ExercicesService.proposer(energie: null), isNull);
      expect(ExercicesService.proposer(energie: 1)!.seance, ExercicesService.detente);
      expect(ExercicesService.proposer(energie: 5, stress: 5)!.seance, ExercicesService.detente);
      expect(ExercicesService.proposer(energie: 3)!.seance, ExercicesService.reveil);
      expect(ExercicesService.proposer(energie: 4)!.seance, ExercicesService.renfoDoux);
      expect(ExercicesService.proposer(energie: 5)!.seance, ExercicesService.seanceEnergie);
    });

    test('bouger pour le plaisir : jamais pour « payer » un repas', () {
      final textes = [
        for (final e in ExercicesService.exercices) ...[
          e.nom,
          ...e.etapes,
          e.conseil,
          e.versionDouce,
        ],
        for (final s in ExercicesService.seances) ...[s.nom, s.description],
        for (final n in [1, 3, 4, 5]) ExercicesService.proposer(energie: n)!.raison,
      ].join(' ').toLowerCase();
      for (final mot in [
        'compens',
        'brûler',
        'éliminer',
        'calorie',
        'rattrap',
        'repas',
        'payer',
        'mérit',
      ]) {
        expect(textes, isNot(contains(mot)), reason: mot);
      }
    });
  });

  testWidgets('écran : choisir son énergie fait apparaître une séance adaptée', (tester) async {
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: await preparerStockage(avecProfil: true)));
    await tester.pumpAndSettle();
    final carte = find.byKey(const Key('carte_exercices'));
    await tester.scrollUntilVisible(
      carte,
      300,
      scrollable: find
          .descendant(of: find.byType(AccueilScreen), matching: find.byType(Scrollable))
          .first,
    );
    await tester.ensureVisible(carte);
    await tester.pumpAndSettle();
    await tester.tap(carte);
    await tester.pumpAndSettle();
    expect(find.byType(ExercicesScreen), findsOneWidget);
    expect(find.byKey(const Key('seance_proposee')), findsNothing);

    await tester.tap(find.text('🙂').first); // énergie 4 : « Bonne énergie »
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seance_proposee')), findsOneWidget);
    expect(find.textContaining('un peu de renfo'), findsOneWidget);
  });

  /// Ouvre une séance d'essai (30 s de squat) dans l'application.
  Future<NavigatorState> ouvrirEssai(WidgetTester tester) async {
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: await preparerStockage(avecProfil: true)));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute(
        builder: (_) => SeanceScreen(seance: ExercicesService.essai(ExercicesService.squat)),
      ),
    );
    // La figurine s'anime en boucle : on avance le temps à la main.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return nav;
  }

  Future<void> avancer(WidgetTester tester, int secondes) async {
    for (var i = 0; i < secondes; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('séance complète : minuteur, fin, activité notée, badge et confettis', (
    tester,
  ) async {
    await ouvrirEssai(tester);
    expect(find.text('Prépare-toi'), findsOneWidget);
    await avancer(tester, SeanceScreen.secondesPreparation);
    expect(find.text('Squat'), findsWidgets);

    await avancer(tester, 31);
    expect(find.byKey(const Key('fin_seance')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('banniere_celebration')), findsOneWidget);

    final contexte = tester.element(find.byType(SeanceScreen));
    final activite = Provider.of<HabitudesProvider>(contexte, listen: false).activites.single;
    expect(activite.type, TypeActivite.renforcement);
    expect(activite.dureeMinutes, 1);
    expect(
      Provider.of<RecompensesProvider>(contexte, listen: false).progres.badges,
      contains('premiereSeance'),
    );

    await tester.tap(find.byKey(const Key('terminer_seance')));
    await avancer(tester, 6); // fin des animations et de la bannière
    expect(find.byType(SeanceScreen), findsNothing);
  });

  testWidgets('pause : le minuteur s\'arrête', (tester) async {
    await ouvrirEssai(tester);
    await avancer(tester, SeanceScreen.secondesPreparation + 5);
    await tester.tap(find.byKey(const Key('pause_seance')));
    await tester.pump();
    final avant = tester.widget<Text>(find.byKey(const Key('secondes_restantes'))).data;
    await avancer(tester, 10);
    expect(tester.widget<Text>(find.byKey(const Key('secondes_restantes'))).data, avant);
    expect(find.text('Reprendre'), findsOneWidget);

    await tester.tap(find.byKey(const Key('fermer_seance')));
    await avancer(tester, 2);
  });

  testWidgets('« Passer » mène jusqu\'à la fin', (tester) async {
    await ouvrirEssai(tester);
    await tester.tap(find.byKey(const Key('passer_phase'))); // prépare-toi
    await tester.pump();
    await tester.tap(find.byKey(const Key('passer_phase'))); // squat
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('fin_seance')), findsOneWidget);
    await tester.tap(find.byKey(const Key('terminer_seance')));
    await avancer(tester, 6);
  });

  testWidgets('fiche d\'un exercice', (tester) async {
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: await preparerStockage(avecProfil: true)));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const ExercicesScreen()));
    await tester.pumpAndSettle();
    final carte = find.byKey(const Key('exercice_pont'));
    await tester.ensureVisible(carte);
    await tester.pumpAndSettle();
    await tester.tap(carte);
    await tester.pump(); // début de la transition
    await avancer(tester, 1);
    expect(find.byType(ExerciceDetailScreen), findsOneWidget);
    expect(find.text('Comment faire'), findsOneWidget);
    expect(find.byKey(const Key('essayer_exercice')), findsOneWidget);
  });
}
