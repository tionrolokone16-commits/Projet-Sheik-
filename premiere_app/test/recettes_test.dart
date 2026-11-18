import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/providers/recompenses_provider.dart';
import 'package:premiere_app/screens/accueil_screen.dart';
import 'package:premiere_app/screens/recettes_screen.dart';
import 'package:premiere_app/services/recettes_service.dart';
import 'package:premiere_app/services/recompenses_service.dart';

import 'outils.dart';

/// Tests des recettes ivoiriennes et de l'assiette.
void main() {
  test('chaque recette est complète et son assiette fait 100 %', () {
    expect(RecettesService.recettes.length, greaterThanOrEqualTo(8));
    final ids = <String>{};
    for (final r in RecettesService.recettes) {
      expect(ids.add(r.id), isTrue, reason: 'identifiant en double : ${r.id}');
      expect(r.astuces, isNotEmpty, reason: r.nom);
      expect(r.portions.total, closeTo(1, 0.001), reason: r.nom);
    }
  });

  test('on n\'interdit jamais le plat d\'origine', () {
    for (final r in RecettesService.recettes) {
      final texte = [r.description, ...r.astuces].join(' ').toLowerCase();
      for (final mot in ['interdit', 'éviter', 'à bannir', 'jamais', 'mauvais']) {
        expect(texte, isNot(contains(mot)), reason: '${r.nom} : « $mot »');
      }
    }
  });

  test('portions normalisées', () {
    final p = Portions.normalisees(2, 1, 1);
    expect(p.legumes, 0.5);
    expect(p.total, closeTo(1, 0.0001));
  });

  Future<void> ouvrirRecettes(WidgetTester tester) async {
    await tester.pumpWidget(FormeDouceApp(stockage: await preparerStockage(avecProfil: true)));
    await tester.pumpAndSettle();
    final carte = find.byKey(const Key('carte_recettes'));
    // On fait défiler la liste de l'accueil jusqu'à la carte, puis on la centre.
    await tester.scrollUntilVisible(carte, 300,
        scrollable: find
            .descendant(of: find.byType(AccueilScreen), matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(carte);
    await tester.pumpAndSettle();
    await tester.tap(carte);
    await tester.pumpAndSettle();
    expect(find.byType(RecettesScreen), findsOneWidget);
  }

  testWidgets('toucher une carte la retourne, puis la remet à l\'endroit', (tester) async {
    ecranIpad(tester);
    await ouvrirRecettes(tester);

    expect(find.byKey(const Key('verso_attieke_poisson')), findsNothing);
    await tester.tap(find.byKey(const Key('recette_attieke_poisson')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('verso_attieke_poisson')), findsOneWidget);

    await tester.tap(find.byKey(const Key('recette_attieke_poisson')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('verso_attieke_poisson')), findsNothing);
  });

  testWidgets('« Je l\'ai cuisinée » fait avancer le défi de la semaine', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await RecompensesProvider(stockage).choisirDefi(DateTime.now(), Defi.recetteIvoirienne);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const RecettesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recette_attieke_poisson')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cuisinee_attieke_poisson')));
    await tester.pumpAndSettle();

    final semaine = RecompensesService.cleSemaine(DateTime.now());
    expect(RecompensesProvider(stockage).progres.defis[semaine]![Defi.recetteIvoirienne.name], 1);
  });

  testWidgets('recettes sans débordement sur petit téléphone', (tester) async {
    tester.view.physicalSize = const Size(375, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ouvrirRecettes(tester);
    // On retourne chaque carte visible pour vérifier aussi les versos.
    for (final r in RecettesService.recettes.take(3)) {
      final carte = find.byKey(Key('recette_${r.id}'));
      await tester.scrollUntilVisible(carte, 200,
          scrollable: find
              .descendant(of: find.byType(RecettesScreen), matching: find.byType(Scrollable))
              .first);
      await tester.tap(carte);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
