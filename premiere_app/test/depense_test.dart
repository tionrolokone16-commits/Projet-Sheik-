import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/calendrier_onglet_screen.dart';
import 'package:premiere_app/services/depense_service.dart';

import 'outils.dart';

/// Calories dépensées : repos, vie quotidienne, nuit, activités, pas.
void main() {
  // Profil d'exemple : femme, 35 ans, 165 cm, 80 kg.
  // Métabolisme de base = 10 × 80 + 6,25 × 165 − 5 × 35 − 161 = 1 495,25 kcal.
  Activite activite(TypeActivite type, int minutes) =>
      Activite(id: '$type', date: DateTime(2026, 11, 20, 12), type: type, dureeMinutes: minutes);

  DepenseJour calculer(JourHabitudes jour, [List<Activite> activites = const []]) =>
      DepenseService.calculer(
        profil: profilExemple,
        poidsKg: 80,
        jour: jour,
        activitesDuJour: activites,
      );

  test('journée au repos : métabolisme de base + vie quotidienne', () {
    final d = calculer(const JourHabitudes());
    expect(d.base, 1495);
    expect(d.quotidien, 299);
    expect(d.mouvement, 0);
    expect(d.total, 1794);
  });

  test('la nuit : métabolisme de base / 24 × heures × 0,95', () {
    expect(calculer(const JourHabitudes(sommeilHeures: 8)).sommeil, 473);
    // La nuit fait partie du repos : elle ne s'ajoute pas au total.
    expect(calculer(const JourHabitudes(sommeilHeures: 8)).total, 1794);
  });

  test('activités : (MET − 1) × poids × durée', () {
    expect(DepenseService.kcalActivite(TypeActivite.marche, 30, 80), 100);
    expect(DepenseService.kcalActivite(TypeActivite.course, 30, 80), 280);
    expect(calculer(const JourHabitudes(), [activite(TypeActivite.danse, 60)]).activites, 320);
  });

  test('séance cochée sans activité notée : 20 min de renforcement', () {
    expect(calculer(const JourHabitudes(seanceFaite: true)).activites, 80);
    // Avec une activité notée, elle n'est pas comptée deux fois.
    expect(
      calculer(const JourHabitudes(seanceFaite: true), [
        activite(TypeActivite.renforcement, 15),
      ]).activites,
      60,
    );
  });

  test('pas : sans compter deux fois une marche notée', () {
    expect(calculer(const JourHabitudes(pas: 6000)).pas, 240);
    expect(calculer(const JourHabitudes(pas: 6000), [activite(TypeActivite.marche, 30)]).pas, 120);
  });

  test('plus de poids, plus de dépense pour la même activité', () {
    expect(
      DepenseService.kcalActivite(TypeActivite.marche, 30, 100),
      greaterThan(DepenseService.kcalActivite(TypeActivite.marche, 30, 70)),
    );
  });

  testWidgets('vue du jour : énergie du jour, nuit et pas', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    final h = HabitudesProvider(stockage);
    final n = DateTime.now();
    await h.definirSommeil(n, 8);
    await h.definirPas(n, 6000);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => JourScreen(date: n)));
    await tester.pumpAndSettle();

    // 1 495 + 299 + 240 (pas) = 2 034 kcal.
    expect(find.byKey(const Key('kcal_depense')), findsOneWidget);
    expect(find.text('≈\u00a02\u00a0034\u00a0kcal'), findsOneWidget);
    final nuit = find.byKey(const Key('kcal_nuit'));
    await tester.scrollUntilVisible(
      nuit,
      200,
      scrollable: find
          .descendant(of: find.byType(JourScreen), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.textContaining('≈\u00a0473\u00a0kcal'), findsOneWidget);
    await tester.pumpAndSettle();
    // On revient à l'accueil : les animations de la vue du jour se terminent.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
  });
}
