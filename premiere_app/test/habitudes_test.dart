import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/services/habitudes_service.dart';

import 'outils.dart';

/// Tests des habitudes : eau, sommeil, repas, ressentis, activités.
void main() {
  final jour = DateTime(2026, 11, 18);

  test('eau, repas, ressentis et sommeil sont enregistrés', () async {
    final stockage = await preparerStockage();
    final h = HabitudesProvider(stockage);

    await h.ajouterVerre(jour);
    await h.ajouterVerre(jour);
    await h.retirerVerre(jour);
    await h.basculerRepas(jour, Repas.dejeuner);
    await h.definirRessenti(jour, Ressenti.energie, 4);
    await h.definirSommeil(jour, 7.5);

    // Relecture depuis le stockage, comme après un redémarrage.
    final relu = HabitudesProvider(stockage).jour(jour);
    expect(relu.verres, 1);
    expect(relu.repas, {Repas.dejeuner});
    expect(relu.ressentis[Ressenti.energie], 4);
    expect(relu.sommeilHeures, 7.5);

    // Toucher le même emoji efface le ressenti.
    await h.definirRessenti(jour, Ressenti.energie, 4);
    expect(h.jour(jour).ressentis, isEmpty);
  });

  test('on ne descend jamais sous 0 verre, et les jours vides disparaissent', () async {
    final stockage = await preparerStockage();
    final h = HabitudesProvider(stockage);
    await h.retirerVerre(jour);
    expect(h.jour(jour).verres, 0);
    expect(stockage.chargerJournal(), isEmpty);
  });

  test('habitudes tenues : eau, sommeil, mouvement, repas', () {
    const vide = JourHabitudes();
    expect(HabitudesService.tenues(vide, activitesDuJour: [], objectifVerres: 8), isEmpty);

    final complet = JourHabitudes(verres: 8, sommeilHeures: 7, repas: Repas.principaux);
    final marche = Activite(id: '1', date: jour, type: TypeActivite.marche, dureeMinutes: 20);
    expect(
      HabitudesService.tenues(complet, activitesDuJour: [marche], objectifVerres: 8),
      Habitude.values.toSet(),
    );
  });

  test('messages : jamais de reproche', () {
    for (var n = 0; n <= 4; n++) {
      expect(HabitudesService.message(n).toLowerCase(), isNot(contains('échec')));
    }
    expect(HabitudesService.messageSommeil(5), contains('Chaque nuit compte'));
    expect(HabitudesService.formaterHeures(7.5), '7 h 30');
    expect(HabitudesService.formaterMinutes(75), '1 h 15');
  });

  testWidgets('aucun débordement sur un petit téléphone', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    tester.view.physicalSize = const Size(375, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    for (final onglet in ['Poids', 'Habitudes', 'Calendrier', 'Profil', 'Accueil']) {
      await tester.tap(find.text(onglet));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet $onglet');
    }
  });

  testWidgets('toucher la bouteille ajoute un verre', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Habitudes'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 8'), findsOneWidget);
    await tester.tap(find.byKey(const Key('bouteille_eau')));
    await tester.tap(find.byKey(const Key('bouteille_eau')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('noter une activité depuis l\'onglet Habitudes', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Habitudes'));
    await tester.pumpAndSettle();

    final bouton = find.byKey(const Key('bouton_noter_activite'));
    // Le bouton est en bas de la liste : on fait défiler jusqu'à lui.
    await tester.scrollUntilVisible(
      bouton,
      300,
      // La liste verticale du jour, à l'intérieur du journal glissant.
      scrollable: find
          .descendant(of: find.byType(PageView), matching: find.byType(Scrollable))
          .last,
    );
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Danse'));
    await tester.tap(find.text('20 min'));
    await tester.tap(find.byKey(const Key('bouton_valider_activite')));
    await tester.pumpAndSettle();

    final activites = stockage.chargerActivites();
    expect(activites.single.type, TypeActivite.danse);
    expect(activites.single.dureeMinutes, 20);
  });
}
