import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/calendrier_screen.dart';
import 'package:premiere_app/services/journal_service.dart';

import 'outils.dart';

/// Tests du journal : ton des journées, navigation entre jours, calendrier.
void main() {
  test('le ton vient uniquement des ressentis (stress inversé)', () {
    expect(JournalService.ton(const JourHabitudes(verres: 8)), isNull);
    expect(
      JournalService.ton(const JourHabitudes(
          ressentis: {Ressenti.energie: 5, Ressenti.stress: 1, Ressenti.sommeil: 5})),
      TonJour.lumineuse,
    );
    expect(
      JournalService.ton(const JourHabitudes(
          ressentis: {Ressenti.energie: 1, Ressenti.stress: 5})),
      TonJour.cocooning,
    );
    expect(JournalService.ton(const JourHabitudes(ressentis: {Ressenti.energie: 3})),
        TonJour.tranquille);
  });

  test('aujourd\'hui / hier', () {
    final m = DateTime(2026, 11, 18, 9);
    expect(JournalService.nomRelatif(DateTime(2026, 11, 18), maintenant: m), 'Aujourd\'hui');
    expect(JournalService.nomRelatif(DateTime(2026, 11, 17), maintenant: m), 'Hier');
    expect(JournalService.nomRelatif(DateTime(2026, 11, 10), maintenant: m), isNull);
  });

  Future<void> ouvrirHabitudes(WidgetTester tester) async {
    await tester.tap(find.text('Habitudes'));
    await tester.pumpAndSettle();
  }

  testWidgets('glisser vers la droite affiche la veille', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await ouvrirHabitudes(tester);

    expect(find.text('Aujourd\'hui'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(500, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Hier'), findsOneWidget);

    // Le bouton « Aujourd'hui » ramène au jour actuel.
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Aujourd\'hui'));
    await tester.pumpAndSettle();
    expect(find.text('Hier'), findsNothing);
  });

  testWidgets('le petit mot est enregistré', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await ouvrirHabitudes(tester);

    final champ = find.byKey(const Key('champ_note_journal'));
    await tester.scrollUntilVisible(champ, 300,
        scrollable: find
            .descendant(of: find.byType(PageView), matching: find.byType(Scrollable))
            .last);
    await tester.enterText(champ, 'Belle balade avec ma sœur');
    await tester.pump(const Duration(seconds: 1)); // délai d'enregistrement
    expect(HabitudesProvider(stockage).jour(DateTime.now()).note,
        'Belle balade avec ma sœur');
  });

  testWidgets('choisir un jour dans le calendrier', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await ouvrirHabitudes(tester);

    await tester.tap(find.byKey(const Key('bouton_calendrier')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendrierScreen), findsOneWidget);
    expect(find.text('Comment lire ton calendrier'), findsOneWidget);

    // On choisit le 1er du mois (aujourd'hui si on est le 1er).
    await tester.tap(find.descendant(
        of: find.byType(CalendrierScreen), matching: find.text('1')).first);
    await tester.pumpAndSettle();
    expect(find.byType(CalendrierScreen), findsNothing);
    final premier = DateTime.now().day == 1;
    expect(find.text(premier ? 'Aujourd\'hui' : 'Hier'),
        DateTime.now().day == 2 || premier ? findsOneWidget : findsNothing);
  });

  testWidgets('calendrier sans débordement sur petit téléphone', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    tester.view.physicalSize = const Size(375, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await ouvrirHabitudes(tester);
    await tester.tap(find.byKey(const Key('bouton_calendrier')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
