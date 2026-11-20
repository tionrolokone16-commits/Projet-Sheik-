import 'package:material_ui/material_ui.dart';

import '../models/exercice.dart';

/// Figurine dessinée qui montre un exercice.
///
/// - `anime: true` : elle va et vient doucement entre les deux poses ;
/// - `anime: false` : elle reste immobile (pour les listes).
class FigureExercice extends StatefulWidget {
  const FigureExercice({
    super.key,
    required this.exercice,
    this.taille = 160,
    this.anime = true,
    this.dureeMouvement = const Duration(milliseconds: 1600),
  });

  final Exercice exercice;
  final double taille;
  final bool anime;

  /// Durée d'un aller (départ → arrivée).
  final Duration dureeMouvement;

  @override
  State<FigureExercice> createState() => _FigureExerciceState();
}

class _FigureExerciceState extends State<FigureExercice> with SingleTickerProviderStateMixin {
  late final AnimationController _mouvement = AnimationController(
    vsync: this,
    duration: widget.dureeMouvement,
  );

  @override
  void initState() {
    super.initState();
    if (widget.anime) _mouvement.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(FigureExercice ancien) {
    super.didUpdateWidget(ancien);
    if (widget.anime && !_mouvement.isAnimating) {
      _mouvement.repeat(reverse: true);
    } else if (!widget.anime && _mouvement.isAnimating) {
      _mouvement.stop();
    }
  }

  @override
  void dispose() {
    _mouvement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Illustration : ${widget.exercice.nom}',
      image: true,
      child: AnimatedBuilder(
        animation: _mouvement,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_mouvement.value);
          return CustomPaint(
            size: Size.square(widget.taille),
            painter: _PeintreFigure(
              pose: Pose.lerp(widget.exercice.poseDepart, widget.exercice.poseArrivee, t),
              mur: widget.exercice.mur,
              couleur: couleurs.primary,
              sol: couleurs.outlineVariant,
            ),
          );
        },
      ),
    );
  }
}

class _PeintreFigure extends CustomPainter {
  _PeintreFigure({required this.pose, required this.mur, required this.couleur, required this.sol});

  final Pose pose;
  final bool mur;
  final Color couleur;
  final Color sol;

  @override
  void paint(Canvas canvas, Size size) {
    // La pose est décrite dans une boîte de 100 × 100.
    final e = size.width / 100;
    Offset p(Offset o) => Offset(o.dx * e, o.dy * e);

    final traitSol = Paint()
      ..color = sol
      ..strokeWidth = 2.5 * e
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(const Offset(4, 96)), p(const Offset(96, 96)), traitSol);
    if (mur) {
      canvas.drawLine(p(const Offset(87, 8)), p(const Offset(87, 96)), traitSol);
    }

    Paint membre(Color c, double epaisseur) => Paint()
      ..color = c
      ..strokeWidth = epaisseur * e
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void segments(List<Offset> points, Paint pinceau) {
      final chemin = Path()..moveTo(p(points.first).dx, p(points.first).dy);
      for (final pt in points.skip(1)) {
        chemin.lineTo(p(pt).dx, p(pt).dy);
      }
      canvas.drawPath(chemin, pinceau);
    }

    // Membres éloignés : plus clairs, dessinés d'abord.
    final loin = membre(couleur.withValues(alpha: 0.4), 6);
    segments([pose.hanche, pose.genouB, pose.piedB], loin);
    segments([pose.cou, pose.coudeB, pose.mainB], loin);

    // Tronc et membres proches.
    final pres = membre(couleur, 7);
    segments([pose.cou, pose.hanche], membre(couleur, 9));
    segments([pose.hanche, pose.genouA, pose.piedA], pres);
    segments([pose.cou, pose.coudeA, pose.mainA], pres);

    // Tête.
    canvas.drawCircle(p(pose.tete), 7 * e, Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_PeintreFigure ancien) =>
      ancien.pose != pose || ancien.couleur != couleur || ancien.mur != mur;
}
