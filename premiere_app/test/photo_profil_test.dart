import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/profil.dart';
import 'package:premiere_app/providers/profil_provider.dart';
import 'package:premiere_app/widgets/avatar_profil.dart';
import 'package:premiere_app/widgets/logo_kira.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Petite image PNG valide (1 × 1 pixel rose), encodée en base64.
const _photoTest =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP4/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';

/// Tests de la photo de profil et du logo.
void main() {
  test('la photo est enregistrée avec le profil, et peut être retirée', () {
    final avec = profilExemple.copyWith(photoBase64: _photoTest);
    final relu = Profil.fromJson(jsonDecode(jsonEncode(avec.toJson())) as Map<String, dynamic>);
    expect(relu.photoBase64, _photoTest);
    expect(relu.copyWith(age: 36).photoBase64, _photoTest); // gardée par défaut
    expect(relu.copyWith(retirerPhoto: true).photoBase64, isNull);
    expect(profilExemple.toJson().containsKey('photo'), isFalse);
  });

  Future<ProfilProvider> lancerAvecPhoto(WidgetTester tester) async {
    final stockage = await preparerStockage(avecProfil: true);
    final provider = ProfilProvider(stockage);
    await provider.enregistrer(profilExemple.copyWith(photoBase64: _photoTest));
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    return Provider.of<ProfilProvider>(tester.element(find.byType(Scaffold).first), listen: false);
  }

  testWidgets('la photo s\'affiche sur l\'accueil et dans le profil', (tester) async {
    ecranIpad(tester);
    await lancerAvecPhoto(tester);
    final accueil = find.byKey(const Key('avatar_accueil'));
    expect(find.descendant(of: accueil, matching: find.byType(Image)), findsOneWidget);

    // Toucher l'avatar de l'accueil ouvre l'onglet Profil.
    await tester.tap(accueil);
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('avatar_profil')), matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('modifier le profil garde la photo', (tester) async {
    ecranIpad(tester);
    final provider = await lancerAvecPhoto(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('champ_poids_objectif')), '70');
    final bouton = find.byKey(const Key('bouton_enregistrer_profil'));
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    expect(provider.profil!.poidsObjectifKg, 70);
    expect(provider.profil!.photoBase64, _photoTest);
  });

  testWidgets('retirer la photo', (tester) async {
    ecranIpad(tester);
    final provider = await lancerAvecPhoto(tester);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('avatar_profil')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retirer_photo')));
    await tester.pumpAndSettle();
    expect(provider.profil!.photoBase64, isNull);
    // Sans photo : l'initiale du prénom.
    expect(
      find.descendant(of: find.byKey(const Key('avatar_profil')), matching: find.text('K')),
      findsOneWidget,
    );
  });

  testWidgets('avatar sans prénom : une silhouette, pas de « ? »', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AvatarProfil(photoBase64: null, prenom: '')),
      ),
    );
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets('le logo s\'affiche sur la page de bienvenue', (tester) async {
    ecranIpad(tester);
    await tester.pumpWidget(FormeDouceApp(stockage: await preparerStockage()));
    await tester.pumpAndSettle();
    expect(find.byType(LogoKira), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
