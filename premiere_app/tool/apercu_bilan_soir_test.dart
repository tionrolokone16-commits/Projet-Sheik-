// Aperçu du bilan du soir, « journée compliquée » ouverte (vérification visuelle).
//
// Lancement : flutter test tool/apercu_bilan_soir_test.dart
// Produit build/apercu_bilan_soir.png. (Les emojis apparaissent en carrés.)
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
import 'package:premiere_app/screens/bilan_soir_screen.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu bilan du soir', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1500 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(theme: ThemeChoisi.sombre, rappelsRepas: false, bilanSoir: false),
    );
    final h = HabitudesProvider(stockage);
    final n = DateTime.now();
    for (var i = 0; i < 5; i++) {
      await h.ajouterVerre(n);
    }
    await h.basculerRepas(n, Repas.dejeuner);
    await h.ajouterActivite(date: n, type: TypeActivite.marche, dureeMinutes: 20);

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
        .push(MaterialPageRoute(builder: (_) => const BilanSoirScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bouton_journee_compliquee')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('idee_demain_coucherTot')));
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_bilan_soir.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
