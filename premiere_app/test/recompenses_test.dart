import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/pesee.dart';
import 'package:premiere_app/models/progres.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/providers/recompenses_provider.dart';
import 'package:premiere_app/screens/chemin_screen.dart';
import 'package:premiere_app/screens/recompenses_screen.dart';
import 'package:premiere_app/services/paliers_service.dart';
import 'package:premiere_app/services/recompenses_service.dart';
import 'package:premiere_app/services/stockage_service.dart';

import 'outils.dart';

/// Tests des paliers, défis, badges et célébrations.
void main() {
  Pesee pesee(int jour, double kg) =>
      Pesee(id: '$jour', date: DateTime(2026, 10, jour), poidsKg: kg);

  group('paliers', () {
    test('un palier tous les 5 % jusqu\'à l\'objectif', () {
      expect(PaliersService.poidsPaliers(profilExemple), [76, 72, 68]);
    });

    test('atteint par la tendance, puis 2 semaines de stabilisation', () {
      final pesees = [pesee(1, 80), pesee(8, 77), pesee(15, 75.8), pesee(16, 75.6)];
      final etat = PaliersService.calculer(
        profilExemple,
        pesees,
        maintenant: DateTime(2026, 10, 20),
      );
      expect(etat.dernierAtteint, 0);
      // Le 15, la fenêtre de 7 jours (9 → 15 oct.) ne contient que 75,8 kg.
      expect(etat.paliers.first.atteintLe, DateTime(2026, 10, 15));
      expect(etat.enStabilisation, isTrue);
      expect(etat.joursStabilisationRestants(DateTime(2026, 10, 20)), 9);
    });

    test('une pesée isolée sous le palier ne suffit pas', () {
      final pesees = [pesee(1, 77), pesee(2, 75.9)]; // moyenne 76,45
      final etat = PaliersService.calculer(
        profilExemple,
        pesees,
        maintenant: DateTime(2026, 10, 3),
      );
      expect(etat.dernierAtteint, -1);
    });

    test('une remontée ne retire jamais un palier atteint', () {
      final pesees = [pesee(1, 75.5), pesee(20, 79), pesee(21, 79.5)];
      final etat = PaliersService.calculer(
        profilExemple,
        pesees,
        maintenant: DateTime(2026, 11, 30),
      );
      expect(etat.dernierAtteint, 0);
      expect(etat.enStabilisation, isFalse); // les 14 jours sont passés
    });
  });

  group('défis', () {
    final lundi = DateTime(2026, 11, 16);

    test('progression automatique depuis le journal', () {
      final journal = {
        '2026-11-16': const JourHabitudes(repas: {Repas.petitDejeuner}),
        '2026-11-17': const JourHabitudes(repas: {Repas.petitDejeuner}),
        '2026-11-25': const JourHabitudes(repas: {Repas.petitDejeuner}), // autre semaine
      };
      final activites = [
        Activite(
          id: '1',
          date: DateTime(2026, 11, 18),
          type: TypeActivite.marche,
          dureeMinutes: 25,
        ),
        Activite(
          id: '2',
          date: DateTime(2026, 11, 19),
          type: TypeActivite.marche,
          dureeMinutes: 10,
        ),
      ];
      int p(Defi d) => RecompensesService.progresDefi(
        d,
        lundi: lundi,
        journal: journal,
        activites: activites,
        progres: Progres(),
        objectifVerres: 8,
      );
      expect(p(Defi.petitsDejeuners), 2);
      expect(p(Defi.marches), 1); // la marche de 10 min ne compte pas pour ce défi
    });

    test('3 défis maximum, compteur manuel borné', () async {
      final stockage = await preparerStockage();
      final r = RecompensesProvider(stockage);
      for (final d in [Defi.legumes, Defi.danse, Defi.sommeil, Defi.journal]) {
        await r.choisirDefi(lundi, d);
      }
      expect(r.defisDeLaSemaine(lundi), [Defi.legumes, Defi.danse, Defi.sommeil]);
      for (var i = 0; i < 9; i++) {
        await r.ajusterDefi(lundi, Defi.legumes, 1);
      }
      expect(r.progres.defis['2026-11-16']![Defi.legumes.name], Defi.legumes.cible);
    });

    test('aucun défi ne récompense une restriction', () {
      for (final d in Defi.values) {
        final texte = '${d.titre} ${d.description}'.toLowerCase();
        for (final mot in ['moins', 'sauter', 'éviter', 'calorie', 'jeûn']) {
          expect(texte, isNot(contains(mot)), reason: d.name);
        }
      }
    });
  });

  group('célébrations', () {
    test('semaine douce : seulement une fois la semaine terminée', () {
      final journal = {
        for (var i = 0; i < 7; i++)
          cleDuJour(DateTime(2026, 11, 16 + i)): const JourHabitudes(verres: 8, sommeilHeures: 8),
      };
      List<String> cles(DateTime n) => RecompensesService.evenements(
        journal: journal,
        activites: const [],
        objectifVerres: 8,
        progres: Progres(),
        profil: profilExemple,
        pesees: const [],
        maintenant: n,
      ).map((e) => e.cle).toList();
      expect(cles(DateTime(2026, 11, 21)), isNot(contains('semaine:2026-11-16')));
      expect(cles(DateTime(2026, 11, 22)), contains('semaine:2026-11-16'));
    });

    test('rien à célébrer quand le poids augmente', () {
      final evts = RecompensesService.evenements(
        journal: const {},
        activites: const [],
        objectifVerres: 8,
        progres: Progres(),
        profil: profilExemple,
        pesees: [pesee(1, 80), pesee(5, 81), pesee(9, 82)],
      );
      expect(evts, isEmpty);
    });

    test('chaque événement n\'est célébré qu\'une fois, avec son badge', () async {
      final stockage = await preparerStockage();
      final r = RecompensesProvider(stockage);
      const e = Evenement(
        cle: 'premiereGoutte',
        emoji: '💧',
        titre: 'T',
        message: 'M',
        idBadge: 'premiereGoutte',
      );
      await r.celebrer([e]);
      await r.celebrer([e]);
      expect(r.prendreCelebration(), isNotNull);
      expect(r.prendreCelebration(), isNull);
      expect(RecompensesProvider(stockage).progres.badges.keys, ['premiereGoutte']);
    });
  });

  group('écrans', () {
    testWidgets('chemin : repère « Tu es ici » et message', (tester) async {
      final stockage = await preparerStockage(avecProfil: true);
      await PoidsProvider(stockage).ajouter(DateTime.now(), 78);
      ecranIpad(tester);
      await tester.pumpWidget(FormeDouceApp(stockage: stockage));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Poids'));
      await tester.pumpAndSettle();
      final bouton = find.byKey(const Key('bouton_chemin_poids'));
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(find.byType(CheminScreen), findsOneWidget);
      expect(find.byKey(const Key('tu_es_ici')), findsOneWidget);
      expect(find.textContaining('Prochain palier : 76 kg'), findsOneWidget);
    });

    testWidgets('noter une victoire : bannière de célébration et badge', (tester) async {
      final stockage = await preparerStockage(avecProfil: true);
      ecranIpad(tester);
      await tester.pumpWidget(FormeDouceApp(stockage: stockage));
      await tester.pumpAndSettle();
      final carte = find.byKey(const Key('carte_recompenses'));
      await defilerAccueilJusqua(tester, carte);
      await tester.tap(carte);
      await tester.pumpAndSettle();
      expect(find.byType(RecompensesScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('bouton_noter_victoire')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meilleur sommeil'));
      await tester.tap(find.byKey(const Key('bouton_valider_victoire')));
      await tester.pump(); // ferme le panneau
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('banniere_celebration')), findsOneWidget);
      expect(find.text('Bravo pour cette victoire !'), findsOneWidget);

      await tester.pumpAndSettle(); // fin des bannières
      expect(RecompensesProvider(stockage).progres.badges, contains('premiereVictoire'));
      expect(find.byKey(const Key('banniere_celebration')), findsNothing);
    });

    testWidgets('choisir un défi depuis l\'écran', (tester) async {
      final stockage = await preparerStockage(avecProfil: true);
      ecranIpad(tester);
      await tester.pumpWidget(FormeDouceApp(stockage: stockage));
      await tester.pumpAndSettle();
      final carte = find.byKey(const Key('carte_recompenses'));
      await defilerAccueilJusqua(tester, carte);
      await tester.tap(carte);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bouton_choisir_defi')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une recette ivoirienne revisitée'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plus_recetteIvoirienne')));
      await tester.pumpAndSettle();
      expect(
        find.text('Défi réussi : Une recette ivoirienne revisitée\n🏅 Nouveau badge !'),
        findsNothing,
      ); // la bannière est déjà repartie…
      expect(RecompensesProvider(stockage).progres.badges, contains('defi_recetteIvoirienne'));
    });

    testWidgets('chemin et défis sans débordement sur petit téléphone', (tester) async {
      final stockage = await preparerStockage(avecProfil: true);
      await PoidsProvider(stockage).ajouter(DateTime.now(), 78);
      tester.view.physicalSize = const Size(375, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(FormeDouceApp(stockage: stockage));
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute(builder: (_) => const CheminScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => const RecompensesScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
