// Aperçu du tableau de bord des calories et de « Mon évolution » (vérification visuelle).
//
// Lancement : flutter test tool/apercu_evolution_test.dart
// Produit build/apercu_evolution.png. (Les emojis apparaissent en carrés.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/reglages.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/evolution_calories_screen.dart';

import '../test/outils.dart';

void main() {
  setUpAll(() async {
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    for (final famille in ['Roboto', 'Manrope']) {
      await (FontLoader(famille)..addFont(Future.value(ByteData.sublistView(octets)))).load();
    }
  });

  testWidgets('aperçu évolution', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1300 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final stockage = await preparerStockage(
      avecProfil: true,
      reglages: const Reglages(theme: ThemeChoisi.clair, rappelsRepas: false, bilanSoir: false),
    );
    final h = HabitudesProvider(stockage);
    final n = DateTime.now();
    const menus = [
      ['Bouillie de mil', 'Garba', 'Soupe de légumes'],
      ['Pain', 'Attiéké poisson braisé', 'Poisson braisé'],
      ['Thé ou café', 'Riz sauce arachide', 'Alloco'],
    ];
    for (var i = 0; i < 7; i++) {
      if (i == 3) continue; // un jour sans repas noté
      final menu = menus[i % 3];
      for (final (k, moment) in [Repas.petitDejeuner, Repas.dejeuner, Repas.diner].indexed) {
        await h.ajouterRepas(
          date: DateTime(n.year, n.month, n.day - i, 8 + 5 * k),
          repas: moment,
          portions: Portions.equilibre,
          nomPlat: menu[k],
        );
      }
      if (i.isEven) {
        await h.ajouterActivite(
          date: DateTime(n.year, n.month, n.day - i, 18),
          type: TypeActivite.marche,
          dureeMinutes: 40,
        );
      }
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
        .push(MaterialPageRoute(builder: (_) => const EvolutionCaloriesScreen()));
    await tester.pumpAndSettle();

    final image = await tester.runAsync(() async {
      final rendu = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await rendu.toImage(pixelRatio: 1);
      final donnees = await img.toByteData(format: ui.ImageByteFormat.png);
      return donnees!.buffer.asUint8List();
    });
    File('build/apercu_evolution.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
