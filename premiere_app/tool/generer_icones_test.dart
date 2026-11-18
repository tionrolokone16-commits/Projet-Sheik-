// Génère le logo et les icônes de l'application (web, iPhone, iPad).
//
// Lancement :  flutter test tool/generer_icones_test.dart
//
// Le logo est un monogramme « K » tracé avec la police Manrope
// (tool/polices/Manrope.ttf, licence SIL OFL : voir tool/polices/OFL.txt),
// blanc sur un fond framboise, avec une petite étincelle dorée.
// Le dessin reste dans la « zone sûre » centrale, pour ne pas être rogné
// par les masques ronds d'Android ou les coins arrondis d'iOS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('génère le logo et les icônes', () async {
    // Charge la vraie police Manrope (sinon les tests utilisent une police factice).
    final octets = File('tool/polices/Manrope.ttf').readAsBytesSync();
    await (FontLoader('Manrope')..addFont(Future.value(ByteData.sublistView(octets)))).load();

    final cibles = {
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'web/icons/apple-touch-icon.png': 180, // taille attendue par iOS
      'web/favicon.png': 32,
      'assets/images/logo.png': 512, // affiché dans l'application
    };
    for (final MapEntry(key: chemin, value: taille) in cibles.entries) {
      File(chemin)
        ..createSync(recursive: true)
        ..writeAsBytesSync(await _dessiner(taille.toDouble()));
    }
  });
}

Future<List<int>> _dessiner(double t) async {
  final enregistreur = ui.PictureRecorder();
  final canvas = Canvas(enregistreur, Rect.fromLTWH(0, 0, t, t));
  final zone = Rect.fromLTWH(0, 0, t, t);

  // Fond framboise, avec une lumière douce venue du coin supérieur gauche.
  canvas.drawRect(
    zone,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEC407A), Color(0xFFC2185B)],
      ).createShader(zone),
  );
  canvas.drawRect(
    zone,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.8),
        radius: 0.9,
        colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0)],
      ).createShader(zone),
  );

  // Monogramme « K » en Manrope ExtraBold.
  final lettre = TextPainter(
    text: TextSpan(
      text: 'K',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: t * 0.56,
        fontVariations: const [FontVariation('wght', 800)],
        color: Colors.white,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  // Le point doré mesure ~9 % de l'icône : on centre l'ensemble « K. ».
  final rayonPoint = t * 0.048;
  final largeurTotale = lettre.width + t * 0.025 + rayonPoint * 2;
  final position = Offset((t - largeurTotale) / 2, (t - lettre.height) / 2);
  lettre.paint(canvas, position);

  // Point doré posé sur la ligne de base, comme une signature : « K. ».
  final basLettre = position.dy + lettre.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  canvas.drawCircle(
    Offset(position.dx + lettre.width + t * 0.025 + rayonPoint, basLettre - rayonPoint),
    rayonPoint,
    Paint()..color = const Color(0xFFF6C453),
  );

  final image = await enregistreur.endRecording().toImage(t.round(), t.round());
  final donnees = await image.toByteData(format: ui.ImageByteFormat.png);
  return donnees!.buffer.asUint8List();
}
