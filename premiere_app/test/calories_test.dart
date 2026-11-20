import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/plat.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/services/calories_service.dart';
import 'package:premiere_app/services/plats_service.dart';
import 'package:premiere_app/widgets/panneau_ressenti_repas.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Calories des repas : estimations par plat, taille de portion, correction à la main.
void main() {
  RepasPhoto repas({
    String? nom,
    Repas moment = Repas.dejeuner,
    TaillePortion taille = TaillePortion.moyenne,
    Portions portions = Portions.equilibre,
    int? kcal,
  }) => RepasPhoto(
    id: 'r',
    date: DateTime(2026, 11, 20, 13),
    repas: moment,
    portions: portions,
    nomPlat: nom,
    taille: taille,
    kcalManuel: kcal,
  );

  test('chaque plat du catalogue a une estimation réaliste', () {
    for (final p in PlatsService.catalogue) {
      expect(CaloriesService.kcalParPlat.containsKey(p.id), isTrue, reason: p.nom);
      expect(CaloriesService.kcalPlat(p), inInclusiveRange(0, 1200), reason: p.nom);
    }
  });

  test('le plat est retrouvé par son nom, et la taille de portion compte', () {
    final plats = PlatsService.catalogue;
    expect(CaloriesService.kcalRepas(repas(nom: 'Garba'), plats), 750);
    expect(CaloriesService.kcalRepas(repas(nom: ' garba '), plats), 750);
    expect(
      CaloriesService.kcalRepas(repas(nom: 'Garba', taille: TaillePortion.petite), plats),
      563,
    );
    expect(
      CaloriesService.kcalRepas(repas(nom: 'Garba', taille: TaillePortion.grande), plats),
      975,
    );
  });

  test('repas en photo ou du plan : estimation selon le moment et l\'assiette', () {
    final plats = PlatsService.catalogue;
    final petitDej = CaloriesService.kcalRepas(repas(moment: Repas.petitDejeuner), plats);
    final dejeuner = CaloriesService.kcalRepas(repas(), plats);
    expect(petitDej, lessThan(dejeuner));
    final riche = CaloriesService.kcalRepas(repas(portions: Portions.normalisees(0, 1, 3)), plats);
    expect(riche, greaterThan(dejeuner));
  });

  test('une valeur saisie à la main remplace l\'estimation et est enregistrée', () {
    final r = repas(nom: 'Garba', kcal: 520);
    expect(CaloriesService.kcalRepas(r, PlatsService.catalogue), 520);
    expect(RepasPhoto.fromJson(r.toJson()).kcalManuel, 520);
    expect(RepasPhoto.fromJson(repas().toJson()).kcalManuel, isNull);
  });

  test('affichage', () {
    expect(CaloriesService.formater(650), '≈\u00a0650\u00a0kcal');
    expect(CaloriesService.formater(1850), '≈\u00a01\u00a0850\u00a0kcal');
  });

  test('total du jour', () async {
    final h = HabitudesProvider(await preparerStockage(avecProfil: true));
    final n = DateTime.now();
    for (final nom in ['Garba', 'Un fruit']) {
      await h.ajouterRepas(
        date: n,
        repas: Repas.dejeuner,
        portions: Portions.equilibre,
        nomPlat: nom,
      );
    }
    expect(h.kcalConsommees(n), 830);
    await h.definirKcalRepas(h.repasPhotosDu(n).first.id, 100);
    expect(h.kcalConsommees(n), 100 + 750);
  });

  testWidgets('corriger les calories d\'un repas', (tester) async {
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
    expect(find.textContaining('≈\u00a0750\u00a0kcal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('corriger_kcal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_nombre')), '600');
    await tester.tap(find.byKey(const Key('valider_nombre')));
    await tester.pumpAndSettle();
    expect(find.textContaining('≈\u00a0600\u00a0kcal'), findsOneWidget);
    expect(find.textContaining('saisi à la main'), findsOneWidget);
    final h = Provider.of<HabitudesProvider>(contexte, listen: false);
    expect(h.repasParId(note.id)!.kcalManuel, 600);
  });
}
