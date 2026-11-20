// Aperçu de l'onglet Poids avec les pesées de la semaine (vérification visuelle).
//
// Lancement : flutter test tool/apercu_poids_test.dart
// Produit build/apercu_poids.png. (Les emojis apparaissent en carrés.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/poids_provider.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu poids', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1500 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(theme: ThemeChoisi.clair, rappelsRepas: false, bilanSoir: false),
    );
    final poids = PoidsProvider(stockage);
    final n = DateTime.now();
    final lundi = DateTime(n.year, n.month, n.day - (n.weekday - 1));
    // Une pesée par semaine sur 5 semaines (sauf la semaine en cours), avec une remontée.
    for (final (s, kg) in [(5, 80.0), (4, 79.4), (3, 78.9), (2, 79.1), (1, 78.4)]) {
      await poids.ajouter(DateTime(lundi.year, lundi.month, lundi.day - 7 * s), kg);
    }

    final cle = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: cle,
        child: FormeDouceApp(stockage: stockage),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poids'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('semaine_pesee_1')));
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_poids.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
