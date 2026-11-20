import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/ingredient.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/services/calories_service.dart';
import 'package:premiere_app/widgets/panneau_ressenti_repas.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Calories des repas : uniquement d'après les ingrédients et les grammes
/// (ou un total saisi à la main). Aucune valeur toute faite par plat.
void main() {
  RepasPhoto repas({String? nom, int? kcal, List<Composant> composition = const []}) => RepasPhoto(
    id: 'r',
    date: DateTime(2026, 11, 20, 13),
    repas: Repas.dejeuner,
    portions: Portions.equilibre,
    nomPlat: nom,
    kcalManuel: kcal,
    composition: composition,
  );

  test('un plat sans ingrédients : calories à compléter, jamais estimées', () {
    expect(CaloriesService.kcalRepas(repas(nom: 'Garba')), isNull);
    expect(CaloriesService.kcalRepas(repas()), isNull);
  });

  test('les calories viennent des ingrédients et des grammes', () {
    final r = repas(
      nom: 'Garba',
      composition: const [
        Composant(idIngredient: 'attieke', grammes: 250),
        Composant(idIngredient: 'thon', grammes: 100),
      ],
    );
    expect(CaloriesService.kcalRepas(r), 400 + 200);
  });

  test('un total saisi à la main est enregistré', () {
    final r = repas(nom: 'Yaourt aux fruits', kcal: 180);
    expect(CaloriesService.kcalRepas(r), 180);
    expect(RepasPhoto.fromJson(r.toJson()).kcalManuel, 180);
    expect(RepasPhoto.fromJson(repas().toJson()).kcalManuel, isNull);
  });

  test('affichage', () {
    expect(CaloriesService.formater(650), '≈\u00a0650\u00a0kcal');
    expect(CaloriesService.formater(1850), '≈\u00a01\u00a0850\u00a0kcal');
  });

  test('total du jour : les repas à compléter ne comptent pas, et sont signalés', () async {
    final h = HabitudesProvider(await preparerStockage(avecProfil: true));
    final n = DateTime.now();
    await h.ajouterRepas(
      date: n,
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      nomPlat: 'Garba',
    );
    await h.ajouterRepas(
      date: n,
      repas: Repas.diner,
      portions: Portions.equilibre,
      nomPlat: 'Riz',
      composition: const [Composant(idIngredient: 'riz', grammes: 200)],
    );
    expect(h.kcalConsommees(n), 260);
    expect(h.repasACompleter(n).single.nomPlat, 'Garba');
  });

  testWidgets('repas sans ingrédients : « à compléter », puis saisir le total', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    final note = await HabitudesProvider(stockage).ajouterRepas(
      date: DateTime.now(),
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      nomPlat: 'Garba',
    );
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    final contexte = tester.element(find.byType(Scaffold).first);
    afficherPanneauRessentiRepas(contexte, note.id);
    await tester.pumpAndSettle();
    String kcalPanneau() =>
        tester.widget<Text>(find.byKey(const Key('kcal_repas'))).textSpan!.toPlainText();
    expect(kcalPanneau(), contains('À compléter'));
    expect(find.byKey(const Key('detailler_grammes')), findsOneWidget);

    await tester.tap(find.byKey(const Key('corriger_kcal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_nombre')), '600');
    await tester.tap(find.byKey(const Key('valider_nombre')));
    await tester.pumpAndSettle();
    expect(kcalPanneau(), contains('≈\u00a0600\u00a0kcal'));
    expect(kcalPanneau(), contains('saisi à la main'));
    final h = Provider.of<HabitudesProvider>(contexte, listen: false);
    expect(h.repasParId(note.id)!.kcalManuel, 600);
  });
}
