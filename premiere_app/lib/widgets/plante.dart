import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Plante virtuelle dessinée à la main.
///
/// [niveau] va de 0 (graine) à 6 (jardin) : la tige monte, les feuilles
/// apparaissent, un bouton se forme puis s'ouvre en fleur.
/// Toucher la plante la fait doucement se balancer.
class Plante extends StatefulWidget {
  const Plante({super.key, required this.niveau, this.fleursBonus = 0});

  final double niveau;
  final int fleursBonus;

  @override
  State<Plante> createState() => _PlanteState();
}

class _PlanteState extends State<Plante> with SingleTickerProviderStateMixin {
  /// Balancement déclenché au toucher (puis la plante s'immobilise).
  late final AnimationController _balancement = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
    value: 1,
  );

  @override
  void didUpdateWidget(Plante ancien) {
    super.didUpdateWidget(ancien);
    // Elle se balance aussi de joie quand elle grandit.
    if (widget.niveau > ancien.niveau) _balancement.forward(from: 0);
  }

  @override
  void dispose() {
    _balancement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Ta plante. Toucher pour la caresser.',
      button: true,
      child: GestureDetector(
        key: const Key('plante'),
        onTap: () => _balancement.forward(from: 0),
        child: TweenAnimationBuilder<double>(
          // La croissance se fait en douceur.
          tween: Tween(end: widget.niveau),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, niveau, _) => AnimatedBuilder(
            animation: _balancement,
            builder: (context, _) {
              final t = _balancement.value;
              // Oscillation amortie : forte au début, nulle à la fin.
              final angle = math.sin(t * math.pi * 5) * 0.09 * (1 - t);
              return CustomPaint(
                size: const Size(220, 230),
                painter: _PeintrePlante(
                  niveau: niveau,
                  fleursBonus: widget.fleursBonus,
                  angle: angle,
                  sombre: couleurs.brightness == Brightness.dark,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PeintrePlante extends CustomPainter {
  _PeintrePlante({
    required this.niveau,
    required this.fleursBonus,
    required this.angle,
    required this.sombre,
  });

  final double niveau;
  final int fleursBonus;
  final double angle;
  final bool sombre;

  static const _vertTige = Color(0xFF6FA36B);
  static const _vertFeuille = Color(0xFF86C07F);
  static const _terre = Color(0xFF8D6E63);
  static const _pot = Color(0xFFF2A7A0);
  static const _potOmbre = Color(0xFFE0857D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final basePot = h;
    final hautPot = h - 64;
    final centreX = w / 2;

    // ----- Plante (dessinée avant le pot, qui cache le bas de la tige) -----
    canvas.save();
    // Le balancement pivote autour de la base de la tige.
    canvas.translate(centreX, hautPot + 6);
    canvas.rotate(angle);

    final hauteurTige = 130 * (niveau / 4).clamp(0.0, 1.0);

    if (niveau < 0.15) {
      // Graine posée dans la terre.
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -6), width: 16, height: 11),
        Paint()..color = const Color(0xFFA1887F),
      );
    } else {
      // Tige légèrement courbée.
      final tige = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-10, -hauteurTige * 0.5, 0, -hauteurTige);
      canvas.drawPath(
        tige,
        Paint()
          ..color = _vertTige
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );

      // Feuilles : jusqu'à 6, la dernière grandit progressivement.
      final feuilles = (niveau * 1.5).clamp(0.0, 6.0);
      for (var i = 0; i < feuilles.ceil(); i++) {
        final taille = (feuilles - i).clamp(0.0, 1.0);
        final f = 0.2 + 0.13 * i; // position le long de la tige (0 = bas)
        final cote = i.isEven ? -1.0 : 1.0;
        // x suit la légère courbe de la tige.
        _feuille(canvas, Offset(-20 * f * (1 - f), -hauteurTige * f), cote, taille);
      }

      // Bouton puis fleur au sommet.
      final sommet = Offset(0, -hauteurTige);
      if (niveau >= 3 && niveau < 4) {
        _bouton(canvas, sommet, (niveau - 3).clamp(0.3, 1.0));
      } else if (niveau >= 4) {
        _fleur(canvas, sommet, 1, ouverture: (niveau - 4 + 0.4).clamp(0.4, 1.0));
      }

      // Fleurs secondaires sur de petites branches.
      final positions = [
        Offset(-38, -hauteurTige * 0.62),
        Offset(36, -hauteurTige * 0.74),
        Offset(-30, -hauteurTige * 0.86),
        Offset(30, -hauteurTige * 0.45),
        Offset(-44, -hauteurTige * 0.38),
        Offset(44, -hauteurTige * 0.95),
      ];
      final branche = Paint()
        ..color = _vertTige
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < fleursBonus && i < positions.length; i++) {
        final p = positions[i];
        canvas.drawLine(Offset(0, p.dy + 12), p, branche);
        _fleur(canvas, p, 0.6, ouverture: 1, variante: i);
      }
    }
    canvas.restore();

    // ----- Pot -----
    final pot = Path()
      ..moveTo(centreX - 52, hautPot)
      ..lineTo(centreX + 52, hautPot)
      ..lineTo(centreX + 40, basePot)
      ..lineTo(centreX - 40, basePot)
      ..close();
    canvas.drawPath(pot, Paint()..color = _pot);
    // Rebord du pot.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centreX - 58, hautPot - 4, 116, 18),
        const Radius.circular(8),
      ),
      Paint()..color = _potOmbre,
    );
    // Terre visible.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centreX, hautPot), width: 96, height: 10),
      Paint()..color = _terre,
    );
    // Petit cœur sur le pot.
    _coeur(canvas, Offset(centreX, hautPot + 36), 9,
        Colors.white.withValues(alpha: sombre ? 0.55 : 0.8));
  }

  void _feuille(Canvas canvas, Offset base, double cote, double taille) {
    if (taille <= 0) return;
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(cote * taille, taille);
    final feuille = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(14, -18, 34, -10)
      ..quadraticBezierTo(18, 4, 0, 0);
    canvas.drawPath(feuille, Paint()..color = _vertFeuille);
    canvas.restore();
  }

  void _bouton(Canvas canvas, Offset centre, double taille) {
    canvas.drawOval(
      Rect.fromCenter(center: centre.translate(0, -8 * taille), width: 18 * taille, height: 26 * taille),
      Paint()..color = Palette.framboise,
    );
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx - 9 * taille, centre.dy)
        ..quadraticBezierTo(centre.dx, centre.dy - 10 * taille, centre.dx + 9 * taille, centre.dy)
        ..close(),
      Paint()..color = _vertFeuille,
    );
  }

  void _fleur(Canvas canvas, Offset centre, double echelle,
      {required double ouverture, int variante = 0}) {
    final teintes = [Palette.framboise, Palette.corail, const Color(0xFFF48FB1)];
    final couleur = teintes[variante % teintes.length];
    final rayon = 22 * echelle * ouverture;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * rayon * 0.75,
        rayon * 0.62,
        Paint()..color = couleur.withValues(alpha: 0.92),
      );
    }
    canvas.drawCircle(centre, rayon * 0.42, Paint()..color = Palette.dore);
  }

  void _coeur(Canvas canvas, Offset c, double t, Color couleur) {
    final chemin = Path()
      ..moveTo(c.dx, c.dy + t * 0.9)
      ..cubicTo(c.dx - t * 1.6, c.dy - t * 0.2, c.dx - t * 0.6, c.dy - t * 1.3, c.dx, c.dy - t * 0.4)
      ..cubicTo(c.dx + t * 0.6, c.dy - t * 1.3, c.dx + t * 1.6, c.dy - t * 0.2, c.dx, c.dy + t * 0.9)
      ..close();
    canvas.drawPath(chemin, Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_PeintrePlante ancien) =>
      ancien.niveau != niveau ||
      ancien.fleursBonus != fleursBonus ||
      ancien.angle != angle ||
      ancien.sombre != sombre;
}
