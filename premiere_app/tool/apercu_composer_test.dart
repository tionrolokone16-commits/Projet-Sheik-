// Aperçu de « Composer mon plat » (vérification visuelle).
//
// Lancement : flutter test tool/apercu_composer_test.dart
// Produit build/apercu_composer.png. (Les emojis apparaissent en carrés.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/ingredient.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/composer_plat_screen.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu composer', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1000 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(theme: ThemeChoisi.clair, rappelsRepas: false, bilanSoir: false),
    );
    final r = await HabitudesProvider(stockage).ajouterRepas(
      date: DateTime.now(),
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      nomPlat: 'Attiéké poisson',
      composition: const [
        Composant(idIngredient: 'attieke', grammes: 250),
        Composant(idIngredient: 'poisson_braise', grammes: 180),
        Composant(idIngredient: 'tomate', grammes: 60),
        Composant(idIngredient: 'oignon', grammes: 30),
        Composant(idIngredient: 'huile', grammes: 15),
      ],
    );

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
            builder: (_) => ComposerPlatScreen(date: DateTime.now(), idRepas: r.id),
          ),
        );
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_composer.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
