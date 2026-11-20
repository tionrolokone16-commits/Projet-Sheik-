import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/pesee.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/services/calculs_service.dart';
import 'package:premiere_app/services/calories_service.dart';
import 'package:premiere_app/services/evolution_service.dart';
import 'package:premiere_app/widgets/energie.dart';

import 'outils.dart';

/// Objectif calorique du jour : selon le poids visé, recalculé à chaque pesée.
void main() {
  test('reste ou au-dessus de l\'objectif, sans jugement', () {
    expect(texteReste(1200, 1650), 'Reste ≈\u00a0450\u00a0kcal');
    expect(texteReste(1850, 1650), '≈\u00a0200\u00a0kcal au-dessus de ton objectif');
  });

  test('l\'objectif suit le poids : une nouvelle pesée le recalcule', () {
    final a80 = CalculsService.objectifCalorique(profilExemple, poidsActuelKg: 80).kcalParJour;
    final a75 = CalculsService.objectifCalorique(profilExemple, poidsActuelKg: 75).kcalParJour;
    expect(a75, lessThan(a80));
    // Jamais sous 1 200 kcal, et entretien une fois l'objectif atteint.
    expect(a75, greaterThanOrEqualTo(CalculsService.kcalMinimum));
    final atteint = CalculsService.objectifCalorique(profilExemple, poidsActuelKg: 68);
    expect(atteint.perteHebdoKg, 0);
  });

  testWidgets('accueil : objectif du jour, consommé et reste', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    final n = DateTime.now();
    await HabitudesProvider(
      stockage,
    ).ajouterRepas(date: n, repas: Repas.dejeuner, portions: Portions.equilibre, nomPlat: 'Garba');
    await PoidsProvider(stockage).ajouter(DateTime(n.year, n.month, n.day - 1), 78);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    final objectif = CalculsService.objectifCalorique(profilExemple, poidsActuelKg: 78).kcalParJour;
    await defilerAccueilJusqua(tester, find.byKey(const Key('accueil_objectif_kcal')));
    String texte(String cle) => tester.widget<Text>(find.byKey(Key(cle))).data!;
    expect(texte('accueil_kcal_consomme'), '750');
    expect(texte('tableau_consomme'), CaloriesService.formater(750));
    expect(texte('tableau_objectif'), CaloriesService.formater(objectif));
    expect(texte('tableau_reste'), texteReste(750, objectif));

    // « Voir mon évolution » : graphique et liste des jours.
    await tester.ensureVisible(find.byKey(const Key('bouton_evolution_calories')));
    await tester.tap(find.byKey(const Key('bouton_evolution_calories')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moyenne_calories')), findsOneWidget);
    expect(find.byKey(Key('ligne_kcal_${n.year}_${n.month}_${n.day}')), findsOneWidget);
    await tester.tap(find.text('30 jours'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5)); // fin des animations
  });

  group('évolution jour par jour', () {
    test('le poids de chaque jour : la pesée de ce jour ou d\'avant', () {
      final pesees = [
        Pesee(id: 'a', date: DateTime(2026, 11, 10), poidsKg: 79),
        Pesee(id: 'b', date: DateTime(2026, 11, 17), poidsKg: 78),
      ];
      expect(EvolutionService.poidsA(DateTime(2026, 11, 5), pesees, profilExemple), 80);
      expect(EvolutionService.poidsA(DateTime(2026, 11, 12), pesees, profilExemple), 79);
      expect(EvolutionService.poidsA(DateTime(2026, 11, 17), pesees, profilExemple), 78);
    });

    test('les jours sans repas noté ne comptent pas dans la moyenne', () {
      JourCalories j(int kcal, {bool notes = true}) => JourCalories(
        date: DateTime(2026, 11, 20),
        consomme: kcal,
        depense: 2000,
        objectif: 1700,
        repasNotes: notes,
      );
      expect(EvolutionService.moyenneConsommee([j(1600), j(0, notes: false), j(1800)]), 1700);
      expect(EvolutionService.moyenneConsommee([j(0, notes: false)]), isNull);
    });
  });
}
