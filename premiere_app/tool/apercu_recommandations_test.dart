// Aperçu des recommandations d'une journée complète au format iPhone (outil de vérification visuelle).
//
// Lancement : flutter test tool/apercu_recommandations_test.dart
// Produit build/apercu_recommandations.png. (Les emojis apparaissent en carrés.)
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
import 'package:premiere_app/screens/calendrier_onglet_screen.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu recommandations', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(theme: ThemeChoisi.clair, rappelsRepas: false),
    );
    final h = HabitudesProvider(stockage);
    final n = DateTime.now();
    final jour = DateTime(n.year, n.month, n.day - 2);
    await h.definirPas(jour, 7200);
    await h.basculerSeanceFaite(jour);
    await h.definirDigestion(jour, 4);
    for (final (i, moment, nom) in [
      (0, Repas.petitDejeuner, 'Pain'),
      (1, Repas.dejeuner, 'Riz gras'),
      (2, Repas.diner, 'Alloco'),
    ]) {
      await h.ajouterRepas(
        date: DateTime(jour.year, jour.month, jour.day, 8 + 6 * i),
        repas: moment,
        portions: Portions.normalisees(0.1, 0.3, 1),
        nomPlat: nom,
      );
    }
    for (var v = 0; v < 5; v++) {
      await h.ajouterVerre(jour);
    }
    await h.definirSommeil(jour, 6);
    await h.definirRessenti(jour, Ressenti.energie, 3);

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
        .push(MaterialPageRoute(builder: (_) => JourScreen(date: jour)));
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_recommandations.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
