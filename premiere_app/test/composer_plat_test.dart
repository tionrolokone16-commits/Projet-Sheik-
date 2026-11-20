import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/ingredient.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';
import 'package:premiere_app/screens/composer_plat_screen.dart';
import 'package:premiere_app/services/ingredients_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Composer un plat au gramme près : ingrédients, grammes, calories.
void main() {
  const riz200 = Composant(idIngredient: 'riz', grammes: 200);
  const poisson150 = Composant(idIngredient: 'poisson_braise', grammes: 150);
  const huile10 = Composant(idIngredient: 'huile', grammes: 10);
  const legumes100 = Composant(idIngredient: 'legumes_sauce', grammes: 100);

  test('base d\'ingrédients : identifiants uniques, valeurs réalistes', () {
    final ids = <String>{};
    for (final i in IngredientsService.catalogue) {
      expect(ids.add(i.id), isTrue, reason: i.id);
      expect(i.kcal100g, inInclusiveRange(10, 900), reason: i.nom);
      expect(i.portionGrammes, greaterThan(0), reason: i.nom);
    }
    for (final g in GroupeIngredient.values) {
      expect(IngredientsService.catalogue.where((i) => i.groupe == g), isNotEmpty);
    }
  });

  test('calories : grammes × kcal pour 100 g', () {
    expect(IngredientsService.parId('riz')!.kcal(200), 260);
    expect(IngredientsService.parId('huile')!.kcal(10), 90);
    expect(IngredientsService.kcal([riz200, poisson150, huile10]), 260 + 225 + 90);
  });

  test('assiette et nom proposé d\'après les ingrédients', () {
    final p = IngredientsService.portions([riz200, poisson150, legumes100, huile10]);
    expect(p.feculents, closeTo(200 / 450, 0.001));
    expect(p.proteines, closeTo(150 / 450, 0.001));
    expect(p.legumes, closeTo(100 / 450, 0.001));
    expect(
      IngredientsService.nomPropose([riz200, poisson150]),
      'Riz blanc cuit, Poisson braisé ou grillé',
    );
  });

  test('recherche sans accents', () {
    expect(IngredientsService.chercher('attieke').single.id, 'attieke');
    expect(IngredientsService.chercher('').length, IngredientsService.catalogue.length);
  });

  test('la composition est enregistrée avec le repas', () {
    final r = RepasPhoto(
      id: 'r',
      date: DateTime(2026, 11, 20, 13),
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      composition: const [riz200, huile10],
    );
    final relu = RepasPhoto.fromJson(r.toJson());
    expect(relu.composition.map((c) => (c.idIngredient, c.grammes)), [('riz', 200), ('huile', 10)]);
  });

  test('modifier la composition d\'un repas, et la garder en le notant à nouveau', () async {
    final h = HabitudesProvider(await preparerStockage(avecProfil: true));
    final n = DateTime.now();
    final garba = await h.ajouterRepas(
      date: n,
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      nomPlat: 'Garba',
    );
    expect(h.kcalRepas(garba), isNull); // aucune calorie toute faite
    await h.modifierComposition(garba.id, const [
      Composant(idIngredient: 'attieke', grammes: 250),
      Composant(idIngredient: 'thon', grammes: 100),
      huile10,
    ]);
    final detaille = h.repasParId(garba.id)!;
    expect(h.kcalRepas(detaille), 400 + 200 + 90);
    expect(detaille.nomPlat, 'Garba');

    final copie = await h.renoterRepas(detaille, date: n, moment: Repas.diner);
    expect(copie.composition.length, 3);
    expect(h.kcalRepas(copie), 690);
  });

  testWidgets('composer un plat : ingrédients, grammes, total, puis noter', (tester) async {
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: await preparerStockage(avecProfil: true)));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute(
            builder: (_) => AjouterRepasScreen(date: DateTime.now(), moment: Repas.dejeuner),
          ),
        );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('bouton_composer_plat')));
    await tester.tap(find.byKey(const Key('bouton_composer_plat')));
    await tester.pumpAndSettle();
    expect(find.byType(ComposerPlatScreen), findsOneWidget);

    Future<void> ajouter(String recherche, String id, String grammes) async {
      await tester.tap(find.byKey(const Key('ajouter_ingredient')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('recherche_ingredient')), recherche);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('ingredient_$id')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('champ_nombre')), grammes);
      await tester.tap(find.byKey(const Key('valider_nombre')));
      await tester.pumpAndSettle();
    }

    await ajouter('riz blanc', 'riz', '200');
    await ajouter('huile', 'huile', '10');
    String total() => tester.widget<Text>(find.byKey(const Key('total_plat_compose'))).data!;
    expect(total(), '≈\u00a0350\u00a0kcal');

    final habitudes = Provider.of<HabitudesProvider>(
      tester.element(find.byType(ComposerPlatScreen)),
      listen: false,
    );
    await tester.ensureVisible(find.byKey(const Key('enregistrer_plat_compose')));
    await tester.tap(find.byKey(const Key('enregistrer_plat_compose')));
    await tester.pumpAndSettle();
    expect(find.byType(ComposerPlatScreen), findsNothing);
    expect(find.byType(AjouterRepasScreen), findsNothing);
    final note = habitudes.repasPhotosDu(DateTime.now()).single;
    expect(habitudes.kcalRepas(note), 350);
    expect(note.composition.length, 2);
    await tester.pump(const Duration(seconds: 5)); // fin des animations
  });
}
