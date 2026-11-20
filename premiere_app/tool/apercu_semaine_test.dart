// Aperçu de la vue Semaine du calendrier au format iPhone (outil de vérification visuelle).
//
// Lancement : flutter test tool/apercu_semaine_test.dart
// Produit build/apercu_semaine_clair.png et build/apercu_semaine_sombre.png.
// (Les emojis apparaissent en carrés : l'outil de test ne sait pas les dessiner.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  for (final (nom, theme) in [('clair', ThemeChoisi.clair), ('sombre', ThemeChoisi.sombre)]) {
    testWidgets('aperçu semaine $nom', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1100 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final stockage = await preparerStockage(
        avecProfil: true,
        reglages: Reglages(theme: theme, rappelsRepas: false, suiviCycle: true),
      );
      final h = HabitudesProvider(stockage);
      final aujourdhui = DateTime.now();
      // Jours d'exemple : de 0 à 4 habitudes, quelques règles et humeurs.
      for (var i = 0; i < 18; i++) {
        final d = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day - i, 12);
        final niveau = i % 5;
        for (var v = 0; v < (niveau >= 1 ? 8 : 2); v++) {
          await h.ajouterVerre(d);
        }
        if (niveau >= 2) await h.definirSommeil(d, 8);
        if (niveau >= 3) {
          await h.ajouterActivite(date: d, type: TypeActivite.marche, dureeMinutes: 30);
        }
        if (niveau >= 4) {
          for (final r in Repas.principaux) {
            await h.basculerRepas(d, r);
          }
        }
        if (i % 3 == 0) await h.definirRessenti(d, Ressenti.energie, 4);
        if (i >= 10 && i <= 13) await h.basculerRegles(d);
      }

      final cle = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: cle,
          child: FormeDouceApp(stockage: stockage),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calendrier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semaine'));
      await tester.pumpAndSettle();

      final image = await tester.runAsync(() async {
        final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await rendu.toImage(pixelRatio: 1);
        final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
        return donnees!.buffer.asUint8List();
      });
      File('build/apercu_semaine_$nom.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(image!);
    });
  }
}
