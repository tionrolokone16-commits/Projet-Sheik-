import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';
import 'package:premiere_app/screens/calendrier_onglet_screen.dart';
import 'package:premiere_app/services/habitudes_service.dart';
import 'package:premiere_app/services/journal_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Vue d'un jour : pas, digestion, séance faite, repas oubliés.
void main() {
  group('pas, digestion et séance faite', () {
    test('sont enregistrés puis relus à l\'identique', () {
      const jour = JourHabitudes(pas: 6500, digestion: 4, seanceFaite: true);
      final relu = JourHabitudes.fromJson(jour.toJson());
      expect(relu.pas, 6500);
      expect(relu.digestion, 4);
      expect(relu.seanceFaite, isTrue);
      expect(relu.estVide, isFalse);
      expect(const JourHabitudes().toJson().containsKey('pas'), isFalse);
    });

    test('une séance faite ou 5 000 pas comptent comme mouvement', () {
      Set<Habitude> tenues(JourHabitudes j) =>
          HabitudesService.tenues(j, activitesDuJour: const [], objectifVerres: 8);
      expect(tenues(const JourHabitudes(seanceFaite: true)), contains(Habitude.mouvement));
      expect(tenues(const JourHabitudes(pas: 5000)), contains(Habitude.mouvement));
      // Moins de pas : rien n'est retiré, l'habitude reste simplement neutre.
      expect(tenues(const JourHabitudes(pas: 3000)), isNot(contains(Habitude.mouvement)));
    });

    test('la digestion ne change pas l\'humeur du jour', () {
      expect(JournalService.humeur(const JourHabitudes(digestion: 1)), isNull);
      expect(
        JournalService.humeur(const JourHabitudes(digestion: 1, ressentis: {Ressenti.energie: 5})),
        5,
      );
    });

    test('affichage des pas', () {
      expect(HabitudesService.formaterPas(500), '500');
      expect(HabitudesService.formaterPas(7500), '7\u00a0500');
      expect(HabitudesService.formaterPas(123456), '123\u00a0456');
    });
  });

  Future<HabitudesProvider> ouvrirJour(WidgetTester tester, DateTime date) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => JourScreen(date: date)));
    await tester.pumpAndSettle();
    return Provider.of<HabitudesProvider>(tester.element(find.byType(JourScreen)), listen: false);
  }

  Future<void> voir(WidgetTester tester, Finder cible, {double pas = 200}) async {
    await tester.scrollUntilVisible(
      cible,
      pas,
      scrollable: find
          .descendant(of: find.byType(JourScreen), matching: find.byType(Scrollable))
          .first,
    );
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
  }

  testWidgets('noter ses pas, sa digestion et sa séance', (tester) async {
    final aujourdhui = DateTime.now();
    final habitudes = await ouvrirJour(tester, aujourdhui);

    await voir(tester, find.byKey(const Key('bouton_noter_pas')));
    await tester.tap(find.byKey(const Key('bouton_noter_pas')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_pas')), '6500');
    await tester.tap(find.byKey(const Key('valider_pas')));
    await tester.pumpAndSettle();
    expect(habitudes.jour(aujourdhui).pas, 6500);
    expect(find.text('6\u00a0500'), findsOneWidget);

    await voir(tester, find.byKey(const Key('puce_seance_faite')));
    await tester.tap(find.byKey(const Key('puce_seance_faite')));
    await tester.pumpAndSettle();
    expect(habitudes.jour(aujourdhui).seanceFaite, isTrue);
    expect(find.text('Séance faite, bravo !'), findsOneWidget);

    final digestion = find.byKey(const Key('selecteur_digestion'));
    await voir(tester, digestion, pas: -200);
    await tester.tap(find.descendant(of: digestion, matching: find.text('😌')));
    await tester.pumpAndSettle();
    expect(habitudes.jour(aujourdhui).digestion, 5);
  });

  testWidgets('jour passé : on peut y ajouter un repas oublié', (tester) async {
    final n = DateTime.now();
    final avantHier = DateTime(n.year, n.month, n.day - 2);
    final habitudes = await ouvrirJour(tester, avantHier);
    await habitudes.basculerRepas(avantHier, Repas.petitDejeuner);
    await tester.pumpAndSettle();

    expect(find.text('verres ce jour-là'), findsOneWidget);
    final bouton = find.byKey(const Key('bouton_noter_repas'));
    await voir(tester, bouton);
    expect(find.byKey(const Key('aide_repas_oublie')), findsOneWidget);

    await tester.tap(bouton);
    await tester.pumpAndSettle();
    final ecran = tester.widget<AjouterRepasScreen>(find.byType(AjouterRepasScreen));
    expect(DateUtils.isSameDay(ecran.date, avantHier), isTrue);
    expect(ecran.moment, Repas.dejeuner); // le petit-déjeuner est déjà noté
  });
}
