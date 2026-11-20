// Aperçu de l'écran « Bouger » au-dessus de l'objectif au format iPhone (outil de vérification visuelle).
//
// Lancement : flutter test tool/apercu_seances_test.dart
// Produit build/apercu_seances.png. (Les emojis apparaissent en carrés.)
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
import 'package:premiere_app/screens/exercices_screen.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu séances', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: Reglages(theme: ThemeChoisi.clair, rappelsRepas: false),
    );
    final h = HabitudesProvider(stockage);
    await h.definirRessenti(DateTime.now(), Ressenti.energie, 4);
    // Un repas copieux : l'objectif du jour est dépassé d'environ 300 kcal.
    final r = await h.ajouterRepas(
      date: DateTime.now(),
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      nomPlat: 'Garba',
    );
    await h.definirKcalRepas(r.id, 2050);

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
        .push(MaterialPageRoute(builder: (_) => const ExercicesScreen()));
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_seances.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
