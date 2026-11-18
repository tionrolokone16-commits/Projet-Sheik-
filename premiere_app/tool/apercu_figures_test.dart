// Aperçu des figurines d'exercices (outil de vérification visuelle).
//
// Lancement : flutter test tool/apercu_figures_test.dart
// Produit build/apercu_figures.png : chaque exercice, pose de départ et d'arrivée.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/models/exercice.dart';
import 'package:premiere_app/services/exercices_service.dart';
import 'package:premiere_app/widgets/figure_exercice.dart';

void main() {
  testWidgets('aperçu des figurines', (tester) async {
    tester.view.physicalSize = const Size(800, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cle = GlobalKey();
    Exercice arrivee(Exercice e) => Exercice(
          id: e.id, nom: e.nom, emoji: e.emoji, niveau: e.niveau, zone: e.zone,
          etapes: e.etapes, conseil: e.conseil, versionDouce: e.versionDouce,
          poseDepart: e.poseArrivee, poseArrivee: e.poseArrivee, mur: e.mur,
        );
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: cle,
        child: Container(
          color: Colors.white,
          child: Wrap(children: [
            for (final e in ExercicesService.exercices) ...[
              Container(
                width: 400,
                height: 200,
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  FigureExercice(exercice: e, anime: false, taille: 180),
                  FigureExercice(exercice: arrivee(e), anime: false, taille: 180),
                ]),
              ),
            ],
          ]),
        ),
      ),
    ));
    final image = await tester.runAsync(() async {
      final boundary = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('build/apercu_figures.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(image!);
  });
}
