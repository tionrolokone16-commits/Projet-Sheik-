import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/services/stockage_service.dart';

import 'outils.dart';

/// Tests de l'onboarding et de l'écran Profil.
void main() {
  late StockageService stockage;

  Future<void> suivant(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('bouton_suivant')));
    await tester.pumpAndSettle();
  }

  /// Parcourt l'onboarding jusqu'à la page « objectif » incluse.
  Future<void> jusquaObjectif(WidgetTester tester, {required String objectif}) async {
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue dans Kira\'s FAT'), findsOneWidget);
    await suivant(tester);

    await tester.enterText(find.byKey(const Key('champ_prenom')), 'Kira');
    await tester.enterText(find.byKey(const Key('champ_age')), '35');
    await suivant(tester);

    await tester.tap(find.text('Femme'));
    await tester.enterText(find.byKey(const Key('champ_taille')), '165');
    await suivant(tester);

    await tester.enterText(find.byKey(const Key('champ_poids_depart')), '80,5');
    await tester.enterText(find.byKey(const Key('champ_poids_objectif')), objectif);
    await tester.pumpAndSettle();
    await suivant(tester);
  }

  testWidgets('onboarding complet puis écran principal', (tester) async {
    stockage = await preparerStockage();
    ecranIpad(tester);
    await jusquaObjectif(tester, objectif: '68');

    expect(find.text('Ton quotidien'), findsOneWidget);
    await suivant(tester);
    expect(find.text('Tout est prêt, Kira !'), findsOneWidget);
    expect(find.text('Indications générales, pas un avis médical.'), findsOneWidget);
    await suivant(tester);

    final profil = stockage.chargerProfil()!;
    expect(profil.prenom, 'Kira');
    expect(profil.poidsDepartKg, 80.5);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('onboarding : prénom obligatoire', (tester) async {
    stockage = await preparerStockage();
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await suivant(tester);
    await suivant(tester); // sans rien remplir
    expect(find.text('Comment veux-tu qu\'on t\'appelle ?'), findsOneWidget);
  });

  testWidgets('onboarding : objectif avec IMC < 18,5 refusé avec douceur', (tester) async {
    stockage = await preparerStockage();
    ecranIpad(tester);
    await jusquaObjectif(tester, objectif: '45');
    expect(find.text('Prenons soin de toi'), findsOneWidget);
    expect(find.text('Ton quotidien'), findsNothing); // on reste sur la page
    expect(stockage.chargerProfil(), isNull);
  });

  testWidgets('profil : modification enregistrée', (tester) async {
    stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('champ_poids_objectif')), '70');
    final bouton = find.byKey(const Key('bouton_enregistrer_profil'));
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(stockage.chargerProfil()!.poidsObjectifKg, 70);
  });
}
