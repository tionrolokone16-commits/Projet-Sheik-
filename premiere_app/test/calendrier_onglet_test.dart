import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/plat.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/calendrier_onglet_screen.dart';
import 'package:premiere_app/services/calendrier_service.dart';
import 'package:premiere_app/theme.dart';
import 'package:table_calendar/table_calendar.dart';

import 'outils.dart';

/// Tests de l'onglet Calendrier (vue mois).
void main() {
  group('couleur et pastilles d\'un jour', () {
    final jour = DateTime(2026, 11, 18, 12);

    test('la couleur vient des habitudes ; un jour vide reste neutre', () {
      expect(CalendrierService.couleur(0, Brightness.light), isNull);
      final teintes = [for (var n = 1; n <= 4; n++) CalendrierService.couleur(n, Brightness.light)];
      expect(teintes.toSet().length, 4); // 4 roses différents, du pâle au vif
    });

    test('pastilles : repas, eau, activité, humeur, plaisir, règles', () {
      final resume = CalendrierService.resume(
        jour: const JourHabitudes(
          verres: 3,
          ressentis: {Ressenti.energie: 5, Ressenti.stress: 1},
          regles: true,
        ),
        activitesDuJour: [
          Activite(id: '1', date: jour, type: TypeActivite.marche, dureeMinutes: 20),
        ],
        repasDuJour: [
          RepasPhoto(
            id: 'r',
            date: jour,
            repas: Repas.dejeuner,
            portions: Portions.equilibre,
            ressentis: const {RessentiRepas.plaisir: 5},
          ),
        ],
        objectifVerres: 8,
        suiviCycle: true,
      );
      expect(resume.pastilles, ['🍽️', '💧', '🏃🏾‍♀️', '😊', '🌸', '🩸']);
      expect(resume.habitudes, 1); // seul le mouvement est « tenu » ici
    });

    test('règles : jamais affichées si le suivi de cycle est désactivé', () {
      final resume = CalendrierService.resume(
        jour: const JourHabitudes(regles: true),
        activitesDuJour: const [],
        repasDuJour: const [],
        objectifVerres: 8,
        suiviCycle: false,
      );
      expect(resume.pastilles, isEmpty);
    });

    test('ce qui a été mangé ne change jamais la couleur', () {
      JourHabitudes j(Set<Repas> repas) => JourHabitudes(verres: 8, repas: repas);
      int niveau(List<RepasPhoto> repas) => CalendrierService.resume(
        jour: j(const {}),
        activitesDuJour: const [],
        repasDuJour: repas,
        objectifVerres: 8,
        suiviCycle: false,
      ).habitudes;
      final grosRepas = RepasPhoto(
        id: 'x',
        date: jour,
        repas: Repas.diner,
        portions: Portions.normalisees(0, 1, 5),
        taille: TaillePortion.grande,
      );
      expect(niveau([grosRepas]), niveau(const []));
    });
  });

  group('lisibilité du numéro du jour sur chaque teinte', () {
    double contraste(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (clair, fonce) = la > lb ? (la, lb) : (lb, la);
      return (clair + 0.05) / (fonce + 0.05);
    }

    ThemeFormeDouce.utiliserGoogleFonts = false;
    for (final (nom, theme) in [
      ('clair', ThemeFormeDouce.clair()),
      ('sombre', ThemeFormeDouce.sombre()),
    ]) {
      test('thème $nom', () {
        for (final teinte in CalendrierService.teintes(theme.colorScheme.brightness)) {
          expect(contraste(theme.colorScheme.onSurface, teinte), greaterThanOrEqualTo(4.5));
        }
      });
    }
  });

  Future<void> ouvrirCalendrier(WidgetTester tester, {bool suiviCycle = false}) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: Reglages(rappelsRepas: false, suiviCycle: suiviCycle),
    );
    await HabitudesProvider(stockage).ajouterVerre(DateTime.now());
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendrier'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendrierOngletScreen), findsOneWidget);
    expect(find.byType(TableCalendar<void>), findsOneWidget);
  }

  Key cleAujourdhui() {
    final n = DateTime.now();
    return Key('jour_${n.year}_${n.month}_${n.day}');
  }

  testWidgets('onglet Calendrier : toucher aujourd\'hui ouvre le détail du jour', (tester) async {
    await ouvrirCalendrier(tester);
    final aujourdhui = find.byKey(cleAujourdhui());
    expect(aujourdhui, findsOneWidget);
    expect(find.descendant(of: aujourdhui, matching: find.text('💧')), findsOneWidget);

    await tester.tap(aujourdhui);
    await tester.pumpAndSettle();
    expect(find.byType(JourScreen), findsOneWidget);
    expect(find.byKey(const Key('puce_regles')), findsNothing); // suivi désactivé
  });

  testWidgets('suivi de cycle : noter un jour de règles depuis le calendrier', (tester) async {
    await ouvrirCalendrier(tester, suiviCycle: true);
    await tester.tap(find.byKey(cleAujourdhui()));
    await tester.pumpAndSettle();

    final puce = find.byKey(const Key('puce_regles'));
    await tester.scrollUntilVisible(
      puce,
      200,
      scrollable: find
          .descendant(of: find.byType(JourScreen), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(puce);
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(cleAujourdhui()), matching: find.text('🩸')),
      findsOneWidget,
    );
  });

  testWidgets('flèches : mois précédent, et pas de mois futur', (tester) async {
    await ouvrirCalendrier(tester);
    final titre = find.byKey(const Key('titre_mois'));
    final avant = tester.widget<Text>(titre).data;
    final suivant = tester.widget<IconButton>(find.byKey(const Key('mois_suivant')));
    expect(suivant.onPressed, isNull); // on est sur le mois en cours

    await tester.tap(find.byKey(const Key('mois_precedent')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(titre).data, isNot(avant));
  });
}
