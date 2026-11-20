import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/services/calculs_service.dart';
import 'package:premiere_app/services/calories_service.dart';
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
    expect(
      find.text('${CaloriesService.formater(750)} sur ${CaloriesService.formater(objectif)}'),
      findsOneWidget,
    );
    expect(find.text(texteReste(750, objectif)), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // fin des animations
  });
}
