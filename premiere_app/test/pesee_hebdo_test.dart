import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/pesee.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/services/pesee_hebdo_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Pesée hebdomadaire : calendrier par semaine et commentaires selon l'objectif.
/// Profil d'exemple : départ 80 kg, objectif 68 kg.
void main() {
  Pesee p(int jour, double kg, {int mois = 11}) =>
      Pesee(id: '$mois-$jour', date: DateTime(2026, mois, jour), poidsKg: kg);

  test('une case par semaine, avec la pesée la plus récente de la semaine', () {
    final semaines = PeseeHebdoService.semaines(
      nombre: 3,
      maintenant: DateTime(2026, 11, 20), // vendredi
      pesees: [p(2, 79.5), p(9, 79), p(11, 78.8)],
    );
    expect(semaines.map((s) => s.lundi.day), [16, 9, 2]);
    expect(semaines[0].pesee, isNull);
    expect(semaines[1].pesee!.poidsKg, 78.8);
    expect(semaines[2].pesee!.poidsKg, 79.5);
  });

  test('date proposée : le jour de pesée, jamais dans le futur', () {
    final lundi = DateTime(2026, 11, 16);
    expect(PeseeHebdoService.dateProposee(lundi, 1, DateTime(2026, 11, 20)), lundi);
    expect(
      PeseeHebdoService.dateProposee(lundi, 7, DateTime(2026, 11, 20)),
      DateTime(2026, 11, 20),
    );
  });

  test('rappel le jour de pesée, seulement si la semaine n\'a pas de pesée', () {
    final lundi = DateTime(2026, 11, 16, 9);
    expect(PeseeHebdoService.rappelAujourdhui(maintenant: lundi, jourPesee: 1, pesees: []), isTrue);
    expect(
      PeseeHebdoService.rappelAujourdhui(maintenant: lundi, jourPesee: 1, pesees: [p(16, 79)]),
      isFalse,
    );
    expect(
      PeseeHebdoService.rappelAujourdhui(maintenant: lundi, jourPesee: 3, pesees: []),
      isFalse,
    );
  });

  test('commentaire : perte, chemin parcouru, rythme et arrivée estimée', () {
    final pesees = [p(2, 80), p(9, 79.5), p(16, 79)];
    final lignes = PeseeHebdoService.commentaire(
      profil: profilExemple,
      pesees: pesees,
      pesee: pesees.last,
    );
    expect(lignes[0], contains('0,5 kg de moins'));
    expect(lignes[1], contains('1 kg de chemin parcouru'));
    expect(lignes[1], contains('encore 11 kg'));
    expect(lignes[2], contains('0,5 kg par semaine'));
    expect(lignes[2], contains('pile dans le rythme'));
    expect(lignes[3], contains('objectif serait atteint vers'));
  });

  test('une remontée est présentée comme normale, jamais comme un recul', () {
    final pesees = [p(2, 79), p(9, 79.4)];
    final lignes = PeseeHebdoService.commentaire(
      profil: profilExemple,
      pesees: pesees,
      pesee: pesees.last,
    );
    expect(lignes.first, contains('c\'est normal'));
    for (final l in lignes) {
      for (final mot in ['échec', 'recul', 'mauvais', 'grossi']) {
        expect(l.toLowerCase(), isNot(contains(mot)));
      }
    }
  });

  test('objectif atteint', () {
    final lignes = PeseeHebdoService.commentaire(
      profil: profilExemple,
      pesees: [p(2, 68)],
      pesee: p(2, 68),
    );
    expect(lignes.single, contains('Objectif atteint'));
  });

  test('le jour de pesée est enregistré', () {
    expect(Reglages.fromJson(const Reglages(jourPesee: 6).toJson()).jourPesee, 6);
    expect(Reglages.fromJson(const {}).jourPesee, 1);
  });

  testWidgets('onglet Poids : ajouter la pesée de la semaine, puis son commentaire', (
    tester,
  ) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poids'));
    await tester.pumpAndSettle();

    final carte = find.byKey(const Key('carte_pesees_semaine'));
    expect(carte, findsOneWidget);
    expect(find.byKey(const Key('aide_pesee_semaine')), findsOneWidget);

    await tester.tap(find.byKey(const Key('semaine_pesee_0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_poids_pesee')), '79,2');
    await tester.tap(find.byKey(const Key('bouton_valider_pesee')));
    await tester.pumpAndSettle();

    final poids = Provider.of<PoidsProvider>(tester.element(carte), listen: false);
    expect(poids.derniere!.poidsKg, 79.2);
    expect(
      find.descendant(of: carte, matching: find.textContaining('0,8 kg de chemin parcouru')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5)); // fin des animations
  });
}
