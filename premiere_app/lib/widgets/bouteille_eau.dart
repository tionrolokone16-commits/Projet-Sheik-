import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Bouteille d'eau dessinée à la main, qui se remplit à chaque toucher.
///
/// - Le niveau monte en douceur jusqu'à la nouvelle valeur.
/// - Une petite vague anime la surface après chaque ajout, puis s'apaise.
/// - Des graduations marquent chaque verre jusqu'à l'objectif.
class BouteilleEau extends StatefulWidget {
  const BouteilleEau({
    super.key,
    required this.verres,
    required this.objectif,
    required this.onAjouter,
  });

  final int verres;
  final int objectif;
  final VoidCallback onAjouter;

  @override
  State<BouteilleEau> createState() => _BouteilleEauState();
}

class _BouteilleEauState extends State<BouteilleEau>
    with SingleTickerProviderStateMixin {
  /// Animation de la vague (0 → 1), relancée à chaque nouveau verre.
  late final AnimationController _vague = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
    value: 1, // Au repos au départ.
  );

  @override
  void didUpdateWidget(BouteilleEau ancien) {
    super.didUpdateWidget(ancien);
    if (widget.verres != ancien.verres) _vague.forward(from: 0);
  }

  @override
  void dispose() {
    _vague.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final sombre = couleurs.brightness == Brightness.dark;
    final remplissage =
        widget.objectif <= 0 ? 0.0 : math.min(widget.verres / widget.objectif, 1.0);

    return Semantics(
      button: true,
      label: 'Bouteille d\'eau : ${widget.verres} verres sur ${widget.objectif}. '
          'Toucher pour ajouter un verre.',
      child: GestureDetector(
        key: const Key('bouteille_eau'),
        onTap: widget.onAjouter,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TweenAnimationBuilder<double>(
            // Le niveau d'eau glisse en douceur vers sa nouvelle valeur.
            tween: Tween(end: remplissage),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, niveau, _) => AnimatedBuilder(
              animation: _vague,
              builder: (context, _) {
                // Petit rebond de la bouteille au début de la vague.
                final t = _vague.value;
                final rebond = 1 + 0.05 * math.sin(math.pi * math.min(t * 4, 1));
                return Transform.scale(
                  scale: rebond,
                  child: CustomPaint(
                    size: const Size(130, 230),
                    painter: _PeintreBouteille(
                      remplissage: niveau,
                      vague: t,
                      graduations: widget.objectif,
                      contour: couleurs.primary,
                      verre: sombre
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      eau: const Color(0xFF6EC6E8),
                      eauClaire: const Color(0xFFA8DDF2),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PeintreBouteille extends CustomPainter {
  _PeintreBouteille({
    required this.remplissage,
    required this.vague,
    required this.graduations,
    required this.contour,
    required this.verre,
    required this.eau,
    required this.eauClaire,
  });

  /// Niveau d'eau entre 0 et 1.
  final double remplissage;

  /// Avancement de la vague : 0 = elle commence, 1 = surface calme.
  final double vague;
  final int graduations;
  final Color contour;
  final Color verre;
  final Color eau;
  final Color eauClaire;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hautCorps = h * 0.16;

    // Forme de la bouteille : un corps arrondi + un goulot.
    final corps = RRect.fromLTRBR(0, hautCorps, w, h, Radius.circular(w * 0.28));
    final goulot = RRect.fromLTRBR(w * 0.30, h * 0.07, w * 0.70, hautCorps + 12,
        const Radius.circular(8));
    final forme = Path.combine(
      PathOperation.union,
      Path()..addRRect(corps),
      Path()..addRRect(goulot),
    );

    // Fond « verre ».
    canvas.drawPath(forme, Paint()..color = verre);

    // Eau, découpée à la forme de la bouteille.
    if (remplissage > 0) {
      canvas.save();
      canvas.clipPath(forme);
      final zoneUtile = h - hautCorps;
      final surface = h - zoneUtile * remplissage;
      // L'amplitude de la vague diminue jusqu'à une surface presque plate.
      final amplitude = 7 * (1 - Curves.easeOut.transform(vague)) + 1.5;
      final phase = vague * math.pi * 4;
      canvas.drawPath(
        _vague(w, h, surface, amplitude, phase + math.pi),
        Paint()..color = eauClaire,
      );
      canvas.drawPath(
        _vague(w, h, surface + 4, amplitude * 0.8, phase),
        Paint()..color = eau,
      );
      canvas.restore();
    }

    // Graduations : un petit trait par verre, sur le côté gauche.
    final trait = Paint()
      ..color = contour.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < graduations; i++) {
      final y = h - (h - hautCorps) * i / graduations;
      canvas.drawLine(Offset(w * 0.10, y), Offset(w * 0.20, y), trait);
    }

    // Contour et bouchon.
    canvas.drawPath(
      forme,
      Paint()
        ..color = contour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.26, 0, w * 0.74, h * 0.08, const Radius.circular(6)),
      Paint()..color = contour,
    );

    // Reflet de lumière.
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.76, hautCorps + 24, w * 0.84, h * 0.6,
          const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  /// Chemin de l'eau avec une surface ondulée.
  Path _vague(double w, double h, double surface, double amplitude, double phase) {
    final chemin = Path()..moveTo(0, surface);
    for (double x = 0; x <= w; x += 2) {
      chemin.lineTo(x, surface + math.sin(x / w * 2 * math.pi * 1.3 + phase) * amplitude);
    }
    return chemin
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldRepaint(_PeintreBouteille ancien) =>
      ancien.remplissage != remplissage ||
      ancien.vague != vague ||
      ancien.graduations != graduations ||
      ancien.contour != contour ||
      ancien.verre != verre;
}
