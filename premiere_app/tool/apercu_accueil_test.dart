// Aperçu de l'accueil au format iPhone (outil de vérification visuelle).
//
// Lancement : flutter test tool/apercu_accueil_test.dart
// Produit build/apercu_accueil_clair.png et build/apercu_accueil_sombre.png.
// (Les emojis apparaissent en carrés : l'outil de test ne sait pas les dessiner.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/providers/poids_provider.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    // Vraie police (sinon les tests affichent des blocs à la place des lettres).
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  for (final (nom, theme) in [('clair', ThemeChoisi.clair), ('sombre', ThemeChoisi.sombre)]) {
    testWidgets('aperçu accueil $nom', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1500 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final stockage = await preparerStockage(
          avecProfil: true, reglages: Reglages(theme: theme, rappelsRepas: false));
      final h = HabitudesProvider(stockage);
      for (var i = 0; i < 3; i++) {
        await h.ajouterVerre(DateTime.now());
      }
      await h.ajouterActivite(
          date: DateTime.now(), type: TypeActivite.marche, dureeMinutes: 30);
      await PoidsProvider(stockage).ajouter(DateTime.now(), 78);

      final cle = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: cle, child: FormeDouceApp(stockage: stockage)));
      await tester.pumpAndSettle();

      final image = await tester.runAsync(() async {
        final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await rendu.toImage(pixelRatio: 1);
        final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
        return donnees!.buffer.asUint8List();
      });
      File('build/apercu_accueil_$nom.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(image!);
    });
  }
}
