import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/plat.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/plan_provider.dart';
import 'package:premiere_app/screens/accueil_screen.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';
import 'package:premiere_app/screens/composer_plat_screen.dart';
import 'package:premiere_app/services/plats_service.dart';

import 'outils.dart';

/// Plan fictif minimal (pour tester les raccourcis « Selon mon plan »).
const _plan = '''
[[Kira's FAT · plan]]
== Petit-déjeuner
- Un fruit et un yaourt
== Menu
Lundi | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
Mardi | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
Mercredi | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
Jeudi | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
Vendredi | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
Samedi | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
Dimanche | Riz + sauce aubergine + poisson | Salade verte + poulet braisé
''';

void main() {
  group('bibliothèque de plats', () {
    test('identifiants uniques, assiettes cohérentes', () {
      final ids = <String>{};
      for (final p in PlatsService.catalogue) {
        expect(ids.add(p.id), isTrue, reason: 'doublon : ${p.id}');
        final total = p.portions.total;
        // 100 % (ou 0 pour les boissons, qui n'ont pas d'assiette).
        expect(total == 0 || (total - 1).abs() < 0.001, isTrue, reason: p.nom);
      }
    });

    test('chaque pays a plusieurs plats', () {
      for (final pays in PaysPlat.values.where((p) => p != PaysPlat.mesPlats)) {
        expect(
          PlatsService.catalogue.where((p) => p.pays == pays).length,
          greaterThanOrEqualTo(3),
          reason: pays.libelle,
        );
      }
    });

    test('estimer l\'assiette d\'un repas décrit en texte', () {
      final complet = PlatsService.estimerPortions('Riz cuit (180 g) + sauce aubergine + poisson');
      expect(complet.legumes, greaterThan(0));
      expect(complet.proteines, greaterThan(0));
      expect(complet.feculents, greaterThan(0));

      final sansFeculent = PlatsService.estimerPortions('Salade verte + poulet braisé');
      expect(sansFeculent.feculents, 0);
      // « tomate » ne doit pas être confondue avec « tô » (féculent).
      expect(PlatsService.estimerPortions('Tomate').feculents, 0);
      // « pâte de légume » est un légume, pas un féculent.
      expect(PlatsService.estimerPortions('pâte de légume').feculents, 0);
    });

    test('recherche sans accents ni majuscules', () {
      final ndole = PlatsService.catalogue.firstWhere((p) => p.id == 'cm_ndole');
      expect(PlatsService.correspond(ndole, 'NDOLE'), isTrue);
      expect(PlatsService.correspond(ndole, 'garba'), isFalse);
    });
  });

  test('les anciens repas notés restent lisibles', () {
    final ancien = RepasPhoto.fromJson({
      'id': '1',
      'date': '2026-11-10T12:30:00.000',
      'repas': 'dejeuner',
      'legumes': 0.5,
      'proteines': 0.25,
      'feculents': 0.25,
    });
    expect(ancien.titre, 'Repas en photo');
    expect(ancien.taille, TaillePortion.moyenne);
    expect(ancien.ressentis, isEmpty);
  });

  Future<void> ouvrir(WidgetTester tester, {bool avecPlan = false}) async {
    final stockage = await preparerStockage(avecProfil: true);
    if (avecPlan) await PlanProvider(stockage).importer(_plan);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    final bouton = find.byKey(const Key('accueil_noter_repas'));
    await tester.scrollUntilVisible(
      bouton,
      300,
      scrollable: find
          .descendant(of: find.byType(AccueilScreen), matching: find.byType(Scrollable))
          .first,
    );
    await tester.ensureVisible(bouton);
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.byType(AjouterRepasScreen), findsOneWidget);
  }

  HabitudesProvider habitudes(WidgetTester tester) =>
      Provider.of<HabitudesProvider>(tester.element(find.byType(Scaffold).first), listen: false);

  testWidgets('choisir un plat ouvre sa composition : ingrédients habituels et grammes', (
    tester,
  ) async {
    ecranIpad(tester);
    await ouvrir(tester);

    await tester.tap(find.byKey(const Key('plat_ci_garba')));
    await tester.pumpAndSettle();
    expect(find.byType(ComposerPlatScreen), findsOneWidget);
    // Les ingrédients habituels du garba sont proposés, sans poids tout fait.
    expect(find.byKey(const Key('suggestion_attieke')), findsOneWidget);
    expect(find.byKey(const Key('suggestion_thon')), findsOneWidget);
    expect(find.text('≈ 0 kcal'), findsOneWidget);

    await composerEtNoter(tester, {'attieke': '250', 'thon': '100'});
    expect(find.byType(AjouterRepasScreen), findsNothing);
    final repas = habitudes(tester).repasPhotos.single;
    expect(repas.nomPlat, 'Garba');
    expect(habitudes(tester).kcalRepas(repas), 400 + 200);
    // Le repas est aussi coché dans les habitudes du jour.
    expect(habitudes(tester).jour(DateTime.now()).repas, contains(repas.repas));
  });

  testWidgets('« Selon mon plan » : le repas prévu, puis ses grammes', (tester) async {
    ecranIpad(tester);
    await ouvrir(tester, avecPlan: true);
    await tester.tap(find.byKey(const Key('plan_midi')));
    await tester.pumpAndSettle();
    await composerEtNoter(tester, {'riz': '200', 'legumes_sauce': '150'});

    final repas = habitudes(tester).repasPhotos.single;
    expect(repas.nomPlat, 'Riz + sauce aubergine + poisson');
    expect(repas.repas, Repas.dejeuner);
    expect(repas.portions.legumes, greaterThan(0));
    expect(habitudes(tester).kcalRepas(repas), 260 + 45);
  });

  testWidgets('ajouter mon plat, puis le noter', (tester) async {
    ecranIpad(tester);
    await ouvrir(tester);
    await tester.tap(find.byKey(const Key('bouton_plat_perso')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_nom_plat')), 'Sauce djoumgblé');
    await tester.pump();
    await tester.tap(find.byKey(const Key('valider_plat_perso')));
    await tester.pumpAndSettle();

    final perso = habitudes(tester).platsPerso.single;
    expect(perso.nom, 'Sauce djoumgblé');
    await tester.tap(find.byKey(Key('plat_${perso.id}')));
    await tester.pumpAndSettle();
    await composerEtNoter(tester, {'huile': '10'});
    expect(habitudes(tester).repasPhotos.single.nomPlat, 'Sauce djoumgblé');
  });

  testWidgets('recherche et filtres', (tester) async {
    ecranIpad(tester);
    await ouvrir(tester);
    await tester.enterText(find.byKey(const Key('recherche_plat')), 'ndol');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plat_cm_ndole')), findsOneWidget);
    expect(find.byKey(const Key('plat_ci_garba')), findsNothing);
  });

  testWidgets('aucune calorie toute faite sur les plats', (tester) async {
    ecranIpad(tester);
    await ouvrir(tester);
    expect(find.textContaining('kcal'), findsNothing);
    await tester.pump(const Duration(seconds: 2)); // fin des animations
  });
}
