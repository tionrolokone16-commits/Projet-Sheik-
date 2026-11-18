import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/recette.dart';

/// Couleurs des trois familles d'aliments.
class CouleursAssiette {
  CouleursAssiette._();
  static const legumes = Color(0xFF8FCB6B);
  static const proteines = Color(0xFFFF8A7A);
  static const feculents = Color(0xFFF6C453);
}

/// Jolie assiette colorée : légumes, protéines et féculents en parts.
/// Les parts se déploient en tournant à l'apparition et à chaque changement.
class Assiette extends StatelessWidget {
  const Assiette({super.key, required this.portions, this.taille = 160});

  final Portions portions;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).colorScheme.brightness == Brightness.dark;
    String pct(double v) => '${(v * 100).round()} %';
    return Semantics(
      label: 'Assiette : légumes ${pct(portions.legumes)}, '
          'protéines ${pct(portions.proteines)}, féculents ${pct(portions.feculents)}',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, deploiement, _) => TweenAnimationBuilder<Portions>(
          tween: _TweenPortions(end: portions),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, p, _) => CustomPaint(
            size: Size.square(taille),
            painter: _PeintreAssiette(portions: p, deploiement: deploiement, sombre: sombre),
          ),
        ),
      ),
    );
  }
}

/// Légende : pastille de couleur + nom + pourcentage.
class LegendeAssiette extends StatelessWidget {
  const LegendeAssiette({super.key, required this.portions});

  final Portions portions;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    Widget ligne(Color c, String emoji, String nom, double v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text('$emoji $nom · ${(v * 100).round()} %', style: style)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ligne(CouleursAssiette.legumes, '🥦', 'Légumes', portions.legumes),
        ligne(CouleursAssiette.proteines, '🍗', 'Protéines', portions.proteines),
        ligne(CouleursAssiette.feculents, '🍚', 'Féculents', portions.feculents),
      ],
    );
  }
}

/// Interpolation douce entre deux répartitions.
class _TweenPortions extends Tween<Portions> {
  _TweenPortions({required Portions end}) : super(begin: end, end: end);

  @override
  Portions lerp(double t) {
    final a = begin!;
    final b = end!;
    double l(double x, double y) => x + (y - x) * t;
    return Portions(
      legumes: l(a.legumes, b.legumes),
      proteines: l(a.proteines, b.proteines),
      feculents: l(a.feculents, b.feculents),
    );
  }
}

class _PeintreAssiette extends CustomPainter {
  _PeintreAssiette({required this.portions, required this.deploiement, required this.sombre});

  final Portions portions;

  /// 0 → 1 : les parts se déploient à l'apparition.
  final double deploiement;
  final bool sombre;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final rayon = size.width / 2;

    // Assiette : bord avec ombre douce, puis fond.
    canvas.drawCircle(
      centre.translate(0, 3),
      rayon - 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(centre, rayon - 2,
        Paint()..color = sombre ? const Color(0xFF4A2B3B) : Colors.white);
    canvas.drawCircle(
      centre,
      rayon * 0.82,
      Paint()
        ..color = sombre ? const Color(0xFF5A3647) : const Color(0xFFFCE4EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Parts colorées, à l'intérieur du rebord.
    final zone = Rect.fromCircle(center: centre, radius: rayon * 0.76);
    final total = portions.total;
    if (total <= 0) return;
    var depart = -math.pi / 2;
    for (final (valeur, couleur) in [
      (portions.legumes, CouleursAssiette.legumes),
      (portions.proteines, CouleursAssiette.proteines),
      (portions.feculents, CouleursAssiette.feculents),
    ]) {
      final angle = 2 * math.pi * valeur / total * deploiement;
      if (angle > 0) {
        canvas.drawArc(zone, depart, angle, true, Paint()..color = couleur);
        // Fine séparation blanche entre les parts.
        canvas.drawArc(
          zone,
          depart,
          angle,
          true,
          Paint()
            ..color = sombre ? const Color(0xFF4A2B3B) : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      depart += angle;
    }
  }

  @override
  bool shouldRepaint(_PeintreAssiette ancien) =>
      ancien.portions != portions ||
      ancien.deploiement != deploiement ||
      ancien.sombre != sombre;
}
