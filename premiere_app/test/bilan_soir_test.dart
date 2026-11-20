import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/recompenses_provider.dart';
import 'package:premiere_app/screens/accueil_screen.dart';
import 'package:premiere_app/screens/bilan_soir_screen.dart';
import 'package:premiere_app/services/bilan_soir_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Bilan du soir et « journée compliquée ».
void main() {
  group('quand afficher le bilan du soir', () {
    const reglages = Reglages(heureBilanSoir: 21 * 60);
    bool affiche(int h, {bool vu = false, Reglages r = reglages}) => BilanSoirService.aAfficher(
      maintenant: DateTime(2026, 11, 20, h, 5),
      reglages: r,
      dejaVu: vu,
    );

    test('à partir de l\'heure choisie, une fois par jour', () {
      expect(affiche(20), isFalse);
      expect(affiche(21), isTrue);
      expect(affiche(22, vu: true), isFalse);
      expect(affiche(22, r: const Reglages(bilanSoir: false)), isFalse);
    });

    test('réglages enregistrés puis relus', () {
      final relu = Reglages.fromJson(
        const Reglages(bilanSoir: false, heureBilanSoir: 20 * 60 + 30).toJson(),
      );
      expect(relu.bilanSoir, isFalse);
      expect(relu.heureBilanSoir, 20 * 60 + 30);
      expect(Reglages.fromJson(const {}).heureBilanSoir, 21 * 60);
    });
  });

  group('bravos', () {
    test('ce qui a été fait, en phrases positives', () {
      final bravos = BilanSoirService.bravos(
        jour: const JourHabitudes(
          verres: 8,
          repas: {Repas.dejeuner, Repas.diner},
          seanceFaite: true,
          pas: 4200,
          note: 'Belle balade',
        ),
        activitesDuJour: [
          Activite(id: '1', date: DateTime(2026), type: TypeActivite.marche, dureeMinutes: 25),
        ],
        repasDuJour: const [],
        objectifVerres: 8,
      );
      expect(bravos.map((b) => b.texte), [
        'Tu as noté 2 repas',
        '8 verres d\'eau : objectif atteint ✨',
        '25 min de mouvement',
        'Ta séance est faite',
        '4\u00a0200 pas',
        'Tu t\'es écrit un petit mot',
      ]);
    });

    test('journée vide : rien de manqué, juste de la douceur', () {
      final bravos = BilanSoirService.bravos(
        jour: const JourHabitudes(),
        activitesDuJour: const [],
        repasDuJour: const [],
        objectifVerres: 8,
      );
      expect(bravos, isEmpty);
      expect(BilanSoirService.introduction(0), contains('Te reposer compte aussi'));
    });

    test('réconfort et idées : ni restriction ni compensation', () {
      final textes = [
        BilanSoirService.reconfort,
        for (final i in IdeeDemain.values) i.texte,
      ].map((t) => t.toLowerCase());
      for (final t in textes) {
        for (final mot in ['compens', 'rembours', 'calorie', 'régime', 'échec', 'moins manger']) {
          expect(t, isNot(contains(mot)), reason: t);
        }
      }
    });
  });

  testWidgets('bilan du soir : bravo, journée compliquée et idées pour demain', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(
      avecProfil: true,
      // Heure 0 h : le bilan est toujours « l'heure passée » pendant le test.
      reglages: const Reglages(rappelsRepas: false, heureBilanSoir: 0),
    );
    await HabitudesProvider(stockage).ajouterVerre(DateTime.now());
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    final carte = find.byKey(const Key('carte_bilan_soir'));
    await defilerAccueilJusqua(tester, carte);
    await tester.tap(carte);
    await tester.pumpAndSettle();
    expect(find.byType(BilanSoirScreen), findsOneWidget);
    expect(find.text('1 verre d\'eau'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bouton_journee_compliquee')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carte_reconfort')), findsOneWidget);

    final recompenses = Provider.of<RecompensesProvider>(
      tester.element(find.byType(BilanSoirScreen)),
      listen: false,
    );
    for (final idee in [IdeeDemain.coucherTot, IdeeDemain.eau, IdeeDemain.air]) {
      final case_ = find.byKey(Key('idee_demain_${idee.name}'));
      await tester.ensureVisible(case_);
      await tester.pumpAndSettle();
      await tester.tap(case_);
      await tester.pumpAndSettle();
    }
    final n = DateTime.now();
    final demain = DateTime(n.year, n.month, n.day + 1);
    // 2 idées au plus.
    expect(recompenses.ideesDuJour(demain), ['coucherTot', 'eau']);

    await tester.ensureVisible(find.byKey(const Key('bouton_bonne_nuit')));
    await tester.tap(find.byKey(const Key('bouton_bonne_nuit')));
    await tester.pumpAndSettle();
    // Déjà ouvert aujourd'hui : la carte ne revient pas.
    expect(find.byType(AccueilScreen), findsOneWidget);
    expect(carte, findsNothing);
  });

  testWidgets('les idées choisies la veille s\'affichent sur l\'accueil', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    final recompenses = Provider.of<RecompensesProvider>(
      tester.element(find.byType(AccueilScreen)),
      listen: false,
    );
    await recompenses.basculerIdeeDuJour(DateTime.now(), IdeeDemain.moment.name);
    await tester.pumpAndSettle();
    final carte = find.byKey(const Key('carte_idees_du_jour'));
    await defilerAccueilJusqua(tester, carte);
    expect(find.text('${IdeeDemain.moment.emoji}  ${IdeeDemain.moment.texte}'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // fin des animations
  });
}
