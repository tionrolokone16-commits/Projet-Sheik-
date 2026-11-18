import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/models/profil.dart';
import 'package:premiere_app/models/reglages.dart';
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
Future<StockageService> preparerStockage({
  bool avecProfil = false,
  Reglages? reglages,
}) async {
  ThemeFormeDouce.utiliserGoogleFonts = false; // pas d'internet en test
  CoucheCelebrations.confettisActives = false; // horloge réelle → test infini
  SharedPreferences.setMockInitialValues({
    if (avecProfil) 'forme_douce.profil': jsonEncode(profilExemple.toJson()),
    // Rappels désactivés par défaut : sinon les tests dépendraient de l'heure
    // (la carte de rappel s'afficherait sur l'accueil aux heures de repas).
    'forme_douce.reglages':
        jsonEncode((reglages ?? const Reglages(rappelsRepas: false)).toJson()),
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
