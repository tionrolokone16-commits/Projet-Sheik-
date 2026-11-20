import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/screens/respiration_screen.dart';
import 'package:premiere_app/services/encouragements_service.dart';
import 'package:premiere_app/services/plante_service.dart';

import 'outils.dart';

/// Tests de l'accueil : salutation, plante, eau, progression, fringale.
void main() {
  group('salutation selon l\'heure', () {
    String a(int h) =>
        EncouragementsService.salutation('Kira', maintenant: DateTime(2026, 1, 1, h));
    test('matin, après-midi, soir, nuit', () {
      expect(a(8), 'Bonjour Kira ☀️');
      expect(a(14), 'Bel après-midi Kira 🌤️');
      expect(a(20), 'Bonsoir Kira 🌙');
      expect(a(2), 'Douce nuit Kira ✨');
    });
  });

  test('mot du jour stable dans la journée et sans reproche', () {
    final matin = EncouragementsService.messageDuJour(date: DateTime(2026, 3, 5, 8));
    final soir = EncouragementsService.messageDuJour(date: DateTime(2026, 3, 5, 22));
    expect(matin, soir);
    for (final m in EncouragementsService.messages) {
      expect(m.toLowerCase(), isNot(contains('échec')));
    }
  });

  group('plante', () {
    test('grandit avec les habitudes, jamais avec le poids', () {
      final journal = {
        '2026-11-17': const JourHabitudes(verres: 8, sommeilHeures: 8),
        '2026-11-18': JourHabitudes(verres: 8, repas: Repas.principaux),
      };
      final marche = Activite(
        id: '1',
        date: DateTime(2026, 11, 18, 9),
        type: TypeActivite.marche,
        dureeMinutes: 30,
      );
      final g = PlanteService.gouttes(journal: journal, activites: [marche], objectifVerres: 8);
      expect(g, 5); // 2 le 17 + 3 le 18
      expect(PlanteService.stade(g), StadePlante.pousse);
    });

    test('stades et niveau continu', () {
      expect(PlanteService.stade(0), StadePlante.graine);
      expect(PlanteService.stade(35), StadePlante.fleur);
      expect(PlanteService.stade(500), StadePlante.jardin);
      expect(PlanteService.niveau(0), 0);
      expect(PlanteService.niveau(500), 6);
      expect(PlanteService.fleursBonus(54), 0);
      expect(PlanteService.fleursBonus(55), 1);
      expect(PlanteService.fleursBonus(1000), 6);
    });

    test('elle attend patiemment, sans reproche', () {
      expect(PlanteService.message(12, habitudesAujourdhui: 0), contains('patiemment'));
    });
  });

  testWidgets('accueil : salutation, +1 verre depuis l\'accueil', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kira'), findsWidgets);
    expect(find.text('0 / 8 verres'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accueil_plus_verre')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 8 verres'), findsOneWidget);

    // Toucher la plante la fait se balancer sans erreur.
    await tester.tap(find.byKey(const Key('plante')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('progression affichée… ou masquée selon les réglages', (tester) async {
    var stockage = await preparerStockage(avecProfil: true);
    await PoidsProvider(stockage).ajouter(DateTime.now(), 78);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('carte_progression')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('carte_progression')), findsOneWidget);

    stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(masquerPoidsAccueil: true),
    );
    await tester.pumpWidget(FormeDouceApp(key: UniqueKey(), stockage: stockage));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carte_progression')), findsNothing);
  });

  testWidgets('fringale : une minute de respiration puis des suggestions', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    final bouton = find.byKey(const Key('bouton_fringale'));
    await tester.scrollUntilVisible(bouton, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(bouton);
    // L'animation de respiration tourne en boucle : on avance le temps à la main
    // (pas de pumpAndSettle, qui attendrait indéfiniment).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition
    expect(find.byType(RespirationScreen), findsOneWidget);
    expect(find.text('Inspire…'), findsOneWidget);

    for (var s = 0; s < 62; s++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.text('Bravo pour cette pause 🌸'), findsOneWidget);
  });

  testWidgets('fringale : on peut passer directement aux suggestions', (tester) async {
    ecranIpad(tester);
    // L'écran de respiration n'a besoin d'aucune donnée : on l'affiche seul.
    await tester.pumpWidget(const MaterialApp(home: RespirationScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('bouton_passer_respiration')));
    await tester.pumpAndSettle();
    expect(find.text('Bravo pour cette pause 🌸'), findsOneWidget);
  });
}
