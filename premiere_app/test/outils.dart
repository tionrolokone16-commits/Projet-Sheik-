import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/models/profil.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/screens/accueil_screen.dart';
import 'package:premiere_app/services/stockage_service.dart';
import 'package:premiere_app/theme.dart';
import 'package:premiere_app/widgets/couche_celebrations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outils communs aux tests.

const profilExemple = Profil(
  prenom: 'Kira',
  age: 35,
  tailleCm: 165,
  poidsDepartKg: 80,
  poidsObjectifKg: 68,
  niveauActivite: NiveauActivite.modere,
  sexe: Sexe.femme,
);

/// Prépare un stockage vide (ou avec un profil déjà rempli).
Future<StockageService> preparerStockage({bool avecProfil = false, Reglages? reglages}) async {
  ThemeFormeDouce.utiliserGoogleFonts = false; // pas d'internet en test
  CoucheCelebrations.confettisActives = false; // horloge réelle → test infini
  SharedPreferences.setMockInitialValues({
    if (avecProfil) 'forme_douce.profil': jsonEncode(profilExemple.toJson()),
    // Rappels désactivés par défaut : sinon les tests dépendraient de l'heure
    // (la carte de rappel s'afficherait sur l'accueil aux heures de repas).
    'forme_douce.reglages': jsonEncode(
      (reglages ?? const Reglages(rappelsRepas: false, bilanSoir: false)).toJson(),
    ),
  });
  await initializeDateFormatting('fr_FR');
  return StockageService.initialiser();
}

/// Simule un écran de la taille d'un iPad en portrait.
void ecranIpad(WidgetTester tester) {
  tester.view.physicalSize = const Size(820, 1180);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Fait défiler l'accueil jusqu'à un élément (même s'il n'est pas encore
/// construit), puis le rend entièrement visible.
Future<void> defilerAccueilJusqua(WidgetTester tester, Finder cible) async {
  await tester.scrollUntilVisible(
    cible,
    300,
    scrollable: find
        .descendant(of: find.byType(AccueilScreen), matching: find.byType(Scrollable))
        .first,
  );
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
}

/// Dans « Composer mon plat » : ajoute des ingrédients proposés (identifiant →
/// grammes), puis note le repas.
Future<void> composerEtNoter(WidgetTester tester, Map<String, String> ingredients) async {
  for (final MapEntry(key: id, value: grammes) in ingredients.entries) {
    final puce = find.byKey(Key('suggestion_$id'));
    await tester.ensureVisible(puce);
    await tester.pumpAndSettle();
    await tester.tap(puce);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_nombre')), grammes);
    await tester.tap(find.byKey(const Key('valider_nombre')));
    await tester.pumpAndSettle();
  }
  final bouton = find.byKey(const Key('enregistrer_plat_compose'));
  await tester.ensureVisible(bouton);
  await tester.pumpAndSettle();
  await tester.tap(bouton);
  await tester.pumpAndSettle();
}
