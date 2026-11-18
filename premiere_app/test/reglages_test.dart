import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/poids_provider.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';
import 'package:premiere_app/screens/bilan_screen.dart';
import 'package:premiere_app/screens/calendrier_screen.dart';
import 'package:premiere_app/screens/chemin_screen.dart';
import 'package:premiere_app/screens/mon_plan_screen.dart';
import 'package:premiere_app/screens/recettes_screen.dart';
import 'package:premiere_app/screens/recompenses_screen.dart';
import 'package:premiere_app/screens/reglages_screen.dart';
import 'package:premiere_app/screens/repas_photo_screen.dart';
import 'package:premiere_app/screens/respiration_screen.dart';

import 'outils.dart';

/// Tests des réglages et vérification générale en mode sombre.
void main() {
  Future<void> ouvrirReglages(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('bouton_reglages_accueil')));
    await tester.pumpAndSettle();
    expect(find.byType(ReglagesScreen), findsOneWidget);
  }

  Future<void> retour(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('masquer le poids sur l\'accueil', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    await PoidsProvider(stockage).ajouter(DateTime.now(), 78);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carte_progression'), skipOffstage: false), findsOneWidget);

    await ouvrirReglages(tester);
    await tester.tap(find.byKey(const Key('interrupteur_masquer_poids')));
    await tester.pumpAndSettle();
    await retour(tester);

    expect(find.byKey(const Key('carte_progression'), skipOffstage: false), findsNothing);
    expect(stockage.chargerReglages().masquerPoidsAccueil, isTrue);
  });

  testWidgets('objectif d\'eau réglable', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    await ouvrirReglages(tester);
    await tester.tap(find.byKey(const Key('plus_verre_objectif')));
    await tester.pumpAndSettle();
    expect(find.text('9 verres par jour (environ 2,3 L)'), findsOneWidget);
    await retour(tester);
    expect(find.text('0 / 9 verres'), findsOneWidget);
  });

  testWidgets('thème sombre', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    await ouvrirReglages(tester);
    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    final contexte = tester.element(find.byType(ReglagesScreen));
    expect(Theme.of(contexte).brightness, Brightness.dark);
    expect(stockage.chargerReglages().theme, ThemeChoisi.sombre);
  });

  testWidgets('tout effacer ramène à l\'onboarding (après confirmation)', (tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await ouvrirReglages(tester);

    // Annuler : rien n'est effacé.
    await tester.tap(find.byKey(const Key('bouton_tout_effacer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garder mes données'));
    await tester.pumpAndSettle();
    expect(stockage.chargerProfil(), isNotNull);

    // Confirmer : retour au tout début.
    await tester.tap(find.byKey(const Key('bouton_tout_effacer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmer_effacement')));
    await tester.pumpAndSettle();
    expect(stockage.chargerProfil(), isNull);
    expect(find.text('Bienvenue dans Kira\'s FAT'), findsOneWidget);
  });

  testWidgets('tour complet en mode sombre sur petit téléphone', (tester) async {
    final stockage = await preparerStockage(
        avecProfil: true, reglages: const Reglages(theme: ThemeChoisi.sombre));
    await PoidsProvider(stockage).ajouter(DateTime.now(), 78);
    tester.view.physicalSize = const Size(375, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    for (final onglet in ['Poids', 'Habitudes', 'Profil', 'Accueil']) {
      await tester.tap(find.text(onglet));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'onglet $onglet');
    }
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final (nom, ecran) in [
      ('réglages', const ReglagesScreen()),
      ('chemin', const CheminScreen()),
      ('défis', const RecompensesScreen()),
      ('recettes', const RecettesScreen()),
      ('calendrier', CalendrierScreen(jourSelectionne: DateTime.now())),
      ('assiette', RepasPhotoScreen(date: DateTime.now())),
      ('mon plan', const MonPlanScreen()),
      ('noter un repas', AjouterRepasScreen(date: DateTime.now())),
      ('bilan', const BilanScreen()),
    ]) {
      nav.push(MaterialPageRoute(builder: (_) => ecran));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'écran $nom');
      nav.pop();
      await tester.pumpAndSettle();
    }
    // La respiration tourne en boucle : on avance le temps à la main.
    nav.push(MaterialPageRoute(builder: (_) => const RespirationScreen()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull, reason: 'écran respiration');
  });
}
