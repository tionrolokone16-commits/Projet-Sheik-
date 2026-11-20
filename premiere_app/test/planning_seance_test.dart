import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/reglages_provider.dart';
import 'package:premiere_app/screens/exercices_screen.dart';
import 'package:premiere_app/services/exercices_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Planning des séances et séance proposée pour la journée.
void main() {
  group('séance proposée pour la journée', () {
    final lundi = DateTime(2026, 11, 16);
    final mardi = DateTime(2026, 11, 17);

    test('les dates d\'exemple tombent bien un lundi et un mardi', () {
      expect(lundi.weekday, DateTime.monday);
      expect(mardi.weekday, DateTime.tuesday);
    });

    test('jour de séance prévu : selon l\'énergie', () {
      final p = ExercicesService.proposerDuJour(date: lundi, joursSeance: {1, 4}, energie: 4);
      expect(p.seance, ExercicesService.renfoDoux);
      expect(p.raison, contains('jours de séance'));
    });

    test('énergie pas encore notée : on la demande', () {
      final p = ExercicesService.proposerDuJour(date: lundi, joursSeance: {1});
      expect(p.seance, isNull);
    });

    test('jour sans séance prévue : repos ou détente, au choix', () {
      final p = ExercicesService.proposerDuJour(date: mardi, joursSeance: {1}, energie: 5);
      expect(p.seance, ExercicesService.detente);
      expect(p.raison, contains('comme tu le sens'));
    });

    test('pas de planning : comme avant, selon l\'énergie', () {
      final p = ExercicesService.proposerDuJour(date: mardi, joursSeance: {}, energie: 5);
      expect(p.seance, ExercicesService.seanceEnergie);
    });

    test('moral bas : un moment doux', () {
      final p = ExercicesService.proposerDuJour(
        date: lundi,
        joursSeance: {1},
        energie: 5,
        humeur: 2,
      );
      expect(p.seance, ExercicesService.detente);
    });

    test('déjà bougé : bravo, et rien d\'obligatoire', () {
      final p = ExercicesService.proposerDuJour(
        date: lundi,
        joursSeance: {1},
        energie: 5,
        dejaBouge: true,
      );
      expect(p.seance, ExercicesService.detente);
      expect(p.raison, contains('bravo'));
    });

    test('textes doux : ni obligation ni compensation', () {
      final textes = [
        for (final d in [lundi, mardi])
          for (final e in [null, 1, 3, 5])
            for (final b in [false, true])
              ExercicesService.proposerDuJour(
                date: d,
                joursSeance: {1},
                energie: e,
                dejaBouge: b,
              ).raison.toLowerCase(),
      ];
      for (final t in textes) {
        for (final mot in ['compens', 'rembours', 'calorie', 'échec', 'dois', 'obligatoire']) {
          expect(t, isNot(contains(mot)), reason: t);
        }
      }
    });

    test('le planning est enregistré puis relu', () {
      final relu = Reglages.fromJson(const Reglages(joursSeance: {5, 1}).toJson());
      expect(relu.joursSeance, {1, 5});
      expect(Reglages.fromJson(const {}).joursSeance, isEmpty);
    });
  });

  testWidgets('choisir ses jours de séance change la proposition du jour', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const ExercicesScreen()));
    await tester.pumpAndSettle();

    final contexte = tester.element(find.byType(ExercicesScreen));
    final reglages = Provider.of<ReglagesProvider>(contexte, listen: false);
    final habitudes = Provider.of<HabitudesProvider>(contexte, listen: false);
    final aujourdhui = DateTime.now().weekday;
    final autreJour = aujourdhui % 7 + 1;

    // Seul un autre jour est choisi : aujourd'hui, repos ou détente.
    await tester.tap(find.byKey(Key('jour_seance_$autreJour')));
    await tester.pumpAndSettle();
    expect(reglages.reglages.joursSeance, {autreJour});
    expect(find.textContaining('Pas de séance prévue'), findsOneWidget);
    expect(find.text('1 séance par semaine, à ton rythme 🌸'), findsOneWidget);

    // Aujourd'hui ajouté : on demande l'énergie, puis la séance s'adapte.
    await tester.tap(find.byKey(Key('jour_seance_$aujourdhui')));
    await tester.pumpAndSettle();
    expect(find.textContaining('jours de séance 📅'), findsOneWidget);
    await habitudes.definirRessenti(DateTime.now(), Ressenti.energie, 4);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seance_proposee')), findsOneWidget);
    expect(find.text(ExercicesService.renfoDoux.nom), findsWidgets);
  });
}
