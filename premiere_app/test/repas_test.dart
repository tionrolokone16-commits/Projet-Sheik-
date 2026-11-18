import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/recompenses_provider.dart';
import 'package:premiere_app/screens/repas_photo_screen.dart';
import 'package:premiere_app/services/assiette_service.dart';
import 'package:premiere_app/services/recompenses_service.dart';

import 'outils.dart';

/// Tests du repas en photo et de l'assiette.
void main() {
  group('conseils de l\'assiette', () {
    test('toujours positifs, une seule petite idée au plus', () {
      final peuDeLegumes = Portions.normalisees(0, 1, 3);
      expect(AssietteService.message(peuDeLegumes), contains('Bon appétit'));
      expect(AssietteService.idee(peuDeLegumes), contains('si tu en as envie'));
      expect(AssietteService.message(Portions.equilibre), contains('Superbe'));
      expect(AssietteService.idee(Portions.equilibre), isNull);
      for (final p in [peuDeLegumes, Portions.normalisees(0, 0, 1), Portions.equilibre]) {
        final texte = '${AssietteService.message(p)} ${AssietteService.idee(p) ?? ''}'
            .toLowerCase();
        for (final mot in ['trop', 'mauvais', 'interdit', 'éviter']) {
          expect(texte, isNot(contains(mot)));
        }
      }
    });

    test('repas proposé selon l\'heure', () {
      expect(AssietteService.repasSelonHeure(DateTime(2026, 1, 1, 8)), Repas.petitDejeuner);
      expect(AssietteService.repasSelonHeure(DateTime(2026, 1, 1, 13)), Repas.dejeuner);
      expect(AssietteService.repasSelonHeure(DateTime(2026, 1, 1, 16)), Repas.collation);
      expect(AssietteService.repasSelonHeure(DateTime(2026, 1, 1, 20)), Repas.diner);
    });
  });

  group('provider', () {
    final jour = DateTime(2026, 11, 18, 13);

    test('un repas noté est aussi coché dans le journal', () async {
      final stockage = await preparerStockage();
      final h = HabitudesProvider(stockage);
      await h.basculerRepas(jour, Repas.petitDejeuner);
      await h.ajouterRepasPhoto(date: jour, repas: Repas.dejeuner, portions: Portions.equilibre);
      await h.ajouterRepasPhoto(date: jour, repas: Repas.petitDejeuner, portions: Portions.equilibre);
      // Le petit-déjeuner déjà coché le reste (pas de décochage).
      expect(h.jour(jour).repas, {Repas.petitDejeuner, Repas.dejeuner});
      expect(HabitudesProvider(stockage).repasPhotosDu(jour).length, 2);
    });

    test('seules les 20 photos les plus récentes sont gardées', () async {
      final stockage = await preparerStockage();
      final h = HabitudesProvider(stockage);
      for (var i = 0; i < 25; i++) {
        await h.ajouterRepasPhoto(
          date: DateTime(2026, 11, 1).add(Duration(hours: i)),
          repas: Repas.dejeuner,
          portions: Portions.equilibre,
          photoBase64: 'AAAA',
        );
      }
      final repas = HabitudesProvider(stockage).repasPhotos;
      expect(repas.length, 25); // les assiettes sont toutes gardées…
      expect(repas.where((r) => r.photoBase64 != null).length, 20); // …pas les photos
      expect(repas.first.photoBase64, isNotNull); // la plus récente a sa photo
      expect(repas.last.photoBase64, isNull);
    });
  });

  Future<void> ouvrirAssiette(WidgetTester tester, {bool defiLegumes = false}) async {
    final stockage = await preparerStockage(avecProfil: true);
    if (defiLegumes) {
      await RecompensesProvider(stockage).choisirDefi(DateTime.now(), Defi.legumes);
    }
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => RepasPhotoScreen(date: DateTime.now())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bouton_sans_photo')));
    await tester.pumpAndSettle();
  }

  testWidgets('noter une assiette sans photo fait avancer le défi légumes', (tester) async {
    ecranIpad(tester);
    await ouvrirAssiette(tester, defiLegumes: true);
    expect(find.byKey(const Key('message_assiette')), findsOneWidget);

    // Plus de légumes : le curseur va tout à droite.
    await tester.drag(find.byKey(const Key('curseur_Légumes')), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Superbe place pour les légumes 🥦✨'), findsOneWidget);

    final bouton = find.byKey(const Key('bouton_enregistrer_repas'));
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(find.byType(RepasPhotoScreen), findsNothing);

    final stockage = context(tester);
    final semaine = RecompensesService.cleSemaine(DateTime.now());
    expect(stockage.recompenses.progres.defis[semaine]![Defi.legumes.name], 1);
    expect(stockage.habitudes.repasPhotos.single.portions.legumes, greaterThan(0.5));
  });

  testWidgets('assiette sans débordement sur petit téléphone', (tester) async {
    tester.view.physicalSize = const Size(375, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ouvrirAssiette(tester);
    expect(tester.takeException(), isNull);
  });
}

/// Accès rapide aux providers de l'application en cours de test.
({RecompensesProvider recompenses, HabitudesProvider habitudes}) context(WidgetTester tester) {
  final element = tester.element(find.byType(Scaffold).first);
  return (
    recompenses: Provider.of<RecompensesProvider>(element, listen: false),
    habitudes: Provider.of<HabitudesProvider>(element, listen: false),
  );
}
