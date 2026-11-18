// Génère les icônes de l'application (web, iPhone, iPad).
//
// Lancement :  flutter test tool/generer_icones_test.dart
//
// L'icône est dessinée en code : fond en dégradé framboise → corail,
// fleur blanche à cinq pétales et cœur doré. Le dessin reste dans la
// « zone sûre » centrale, pour ne pas être rogné par les masques ronds
// d'Android ou les coins arrondis d'iOS.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('génère les icônes', () async {
    final cibles = {
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'web/icons/apple-touch-icon.png': 180, // taille attendue par iOS
      'web/favicon.png': 32,
    };
    for (final MapEntry(key: chemin, value: taille) in cibles.entries) {
      final octets = await _dessiner(taille.toDouble());
      File(chemin).writeAsBytesSync(octets);
    }
  });
}

Future<List<int>> _dessiner(double t) async {
  final enregistreur = ui.PictureRecorder();
  final canvas = Canvas(enregistreur, Rect.fromLTWH(0, 0, t, t));

  // Fond : dégradé en diagonale, sur toute la surface.
  canvas.drawRect(
    Rect.fromLTWH(0, 0, t, t),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE91E63), Color(0xFFFF8A7A)],
      ).createShader(Rect.fromLTWH(0, 0, t, t)),
  );

  final centre = Offset(t / 2, t / 2);

  // Halo doux derrière la fleur.
  canvas.drawCircle(
    centre,
    t * 0.33,
    Paint()..color = Colors.white.withValues(alpha: 0.16),
  );

  // Cinq pétales blancs.
  // Pétales en ovale, bien distincts les uns des autres.
  for (var i = 0; i < 5; i++) {
    final a = i * 2 * math.pi / 5 - math.pi / 2;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(a + math.pi / 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -t * 0.17), width: t * 0.17, height: t * 0.24),
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  // Cœur doré, avec un petit reflet.
  canvas.drawCircle(centre, t * 0.085, Paint()..color = const Color(0xFFF6C453));
  canvas.drawCircle(
    centre.translate(-t * 0.025, -t * 0.025),
    t * 0.025,
    Paint()..color = Colors.white.withValues(alpha: 0.55),
  );

  final image = await enregistreur.endRecording().toImage(t.round(), t.round());
  final donnees = await image.toByteData(format: ui.ImageByteFormat.png);
  return donnees!.buffer.asUint8List();
}
