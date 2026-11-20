// Aperçu de « Noter un repas » avec « Comme hier » et les favoris (vérification visuelle).
//
// Lancement : flutter test tool/apercu_repas_rapide_test.dart
// Produit build/apercu_repas_rapide.png. (Les emojis apparaissent en carrés.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu repas rapide', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1000 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(theme: ThemeChoisi.clair, rappelsRepas: false),
    );
    final h = HabitudesProvider(stockage);
    final n = DateTime.now();
    for (final (jours, nom) in [
      (1, 'Garba'),
      (2, 'Garba'),
      (3, 'Attiéké poisson braisé'),
      (4, 'Attiéké poisson braisé'),
      (5, 'Riz sauce graine'),
      (6, 'Riz sauce graine'),
    ]) {
      await h.ajouterRepas(
        date: DateTime(n.year, n.month, n.day - jours, 13),
        repas: Repas.dejeuner,
        portions: Portions.equilibre,
        nomPlat: nom,
        emojiPlat: '🍲',
      );
    }

    final cle = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: cle,
        child: FormeDouceApp(stockage: stockage),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute(
            builder: (_) => AjouterRepasScreen(date: n, moment: Repas.dejeuner),
          ),
        );
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_repas_rapide.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
