import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/services/messages_service.dart';

import 'outils.dart';

/// Tests du suivi du poids et des messages bienveillants.
void main() {
  test('une seule pesée par jour, triées et sauvegardées', () async {
    final stockage = await preparerStockage();
    final poids = PoidsProvider(stockage);
    await poids.ajouter(DateTime(2026, 11, 10, 8), 80);
    await poids.ajouter(DateTime(2026, 11, 3), 81);
    await poids.ajouter(DateTime(2026, 11, 10, 20), 79.6); // même jour : remplace
    expect(poids.pesees.length, 2);
    expect(poids.derniere!.poidsKg, 79.6);
    expect(stockage.chargerPesees().length, 2);

    final supprimee = await poids.supprimer(poids.derniere!.id);
    expect(poids.pesees.length, 1);
    await poids.restaurer(supprimee!);
    expect(poids.pesees.length, 2);
  });

  test('messages toujours positifs, même si le poids augmente', () {
    final hausse = MessagesService.variation(0.6);
    expect(hausse, contains('normal'));
    for (final m in [hausse, MessagesService.variation(-0.4), MessagesService.variation(0)]) {
      expect(m.toLowerCase(), isNot(contains('échec')));
    }
  });

  testWidgets('le graphique s\'affiche avec plusieurs pesées', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    final poids = PoidsProvider(stockage);
    final aujourdhui = DateTime.now();
    for (var i = 0; i < 6; i++) {
      await poids.ajouter(aujourdhui.subtract(Duration(days: 5 * i)),
          80 - i * 0.4 + (i.isEven ? 0.3 : 0));
    }

    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poids'));
    await tester.pumpAndSettle();

    expect(find.text('Évolution'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ajout d\'une pesée depuis l\'écran Poids', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poids'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bouton_ajouter_pesee')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_poids_pesee')), '78,4');
    await tester.tap(find.byKey(const Key('bouton_valider_pesee')));
    await tester.pumpAndSettle();

    expect(stockage.chargerPesees().single.poidsKg, 78.4);
    expect(find.text('78,4 kg'), findsWidgets);
  });
}
