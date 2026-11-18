import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/reglages_provider.dart';
import 'package:premiere_app/screens/accueil_screen.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';
import 'package:premiere_app/screens/reglages_screen.dart';
import 'package:premiere_app/services/rappels_service.dart';

import 'outils.dart';

/// Tests des rappels doux aux heures de repas.
void main() {
  group('quand rappeler', () {
    const r = Reglages(); // 8 h, 13 h, 20 h
    Repas? a(int h, int m, {Set<Repas> notes = const {}, Set<Repas> deCote = const {},
            Reglages reglages = r}) =>
        RappelsService.rappelActuel(
          maintenant: DateTime(2026, 11, 18, h, m),
          reglages: reglages,
          dejaNotes: notes,
          misDeCote: deCote,
        );

    test('pendant les 2 h 30 qui suivent l\'heure du repas', () {
      expect(a(12, 59), isNull);
      expect(a(13, 0), Repas.dejeuner);
      expect(a(15, 29), Repas.dejeuner);
      expect(a(15, 30), isNull);
      expect(a(8, 30), Repas.petitDejeuner);
      expect(a(21, 0), Repas.diner);
    });

    test('pas de rappel si le repas est noté, mis de côté ou si c\'est désactivé', () {
      expect(a(13, 30, notes: {Repas.dejeuner}), isNull);
      expect(a(13, 30, deCote: {Repas.dejeuner}), isNull);
      expect(a(13, 30, reglages: const Reglages(rappelsRepas: false)), isNull);
    });

    test('messages : des invitations, jamais des reproches', () {
      for (final repas in Repas.values) {
        final m = RappelsService.message(repas).toLowerCase();
        expect(m, contains('tu veux'));
        for (final mot in ['oublié', 'oubli', 'pas encore', 'toujours pas', 'n\'as pas']) {
          expect(m, isNot(contains(mot)));
        }
      }
      expect(RappelsService.formaterHeure(13 * 60 + 5), '13:05');
    });

    test('anciens réglages : rappels activés à 8 h, 13 h, 20 h', () {
      final ancien = Reglages.fromJson({'objectifVerres': 8});
      expect(ancien.rappelsRepas, isTrue);
      expect(ancien.heureDejeuner, 13 * 60);
    });
  });

  /// Réglages où seul le déjeuner est « maintenant » (quelle que soit l'heure du test).
  Reglages dejeunerMaintenant() {
    final n = DateTime.now();
    final minutes = n.hour * 60 + n.minute;
    return Reglages(
      heureDejeuner: (minutes - 10) % 1440,
      heurePetitDejeuner: (minutes + 300) % 1440,
      heureDiner: (minutes + 600) % 1440,
    );
  }

  Future<void> lancer(WidgetTester tester, Reglages reglages) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true, reglages: reglages);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
  }

  testWidgets('le rappel s\'affiche sur l\'accueil, « Plus tard » le range', (tester) async {
    await lancer(tester, dejeunerMaintenant());
    expect(find.byKey(const Key('rappel_repas')), findsOneWidget);
    expect(find.text('Tu veux noter ton déjeuner ? 🌸'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rappel_plus_tard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rappel_repas')), findsNothing);
    await tester.pump(const Duration(seconds: 2)); // fin des animations
  });

  testWidgets('« Noter » ouvre le journal sur le bon repas, puis le rappel disparaît',
      (tester) async {
    await lancer(tester, dejeunerMaintenant());
    await tester.tap(find.byKey(const Key('rappel_noter')));
    await tester.pumpAndSettle();
    expect(find.byType(AjouterRepasScreen), findsOneWidget);
    final puce = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Déjeuner').first);
    expect(puce.selected, isTrue);

    await tester.tap(find.byKey(const Key('plat_ci_attieke_poisson')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bouton_terminer_repas')));
    await tester.pumpAndSettle();
    expect(find.byType(AccueilScreen), findsOneWidget);
    expect(find.byKey(const Key('rappel_repas')), findsNothing);
    await tester.pump(const Duration(seconds: 2)); // fin des animations
  });

  testWidgets('rappels désactivés : rien ne s\'affiche', (tester) async {
    await lancer(tester, dejeunerMaintenant().copyWith(rappelsRepas: false));
    expect(find.byKey(const Key('rappel_repas')), findsNothing);
  });

  testWidgets('réglages : couper les rappels masque les heures', (tester) async {
    await lancer(tester, const Reglages());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const ReglagesScreen()));
    await tester.pumpAndSettle();
    final interrupteur = find.byKey(const Key('interrupteur_rappels'));
    await tester.ensureVisible(interrupteur);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('heure_dejeuner')), findsOneWidget);
    expect(find.text('13:00'), findsOneWidget);

    await tester.tap(interrupteur);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('heure_dejeuner')), findsNothing);
    final reglages = Provider.of<ReglagesProvider>(
        tester.element(find.byType(ReglagesScreen)),
        listen: false);
    expect(reglages.reglages.rappelsRepas, isFalse);
  });
}
