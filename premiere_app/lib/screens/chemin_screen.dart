import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../services/paliers_service.dart';
import '../theme.dart';
import '../widgets/format.dart';

/// Type d'étape sur le chemin.
enum _TypeEtape { depart, palier, stabilisation }

class _Etape {
  const _Etape(this.type, {this.palier, required this.faite});
  final _TypeEtape type;
  final Palier? palier;

  /// Vrai si l'étape est derrière nous.
  final bool faite;
}

/// Chemin des paliers : un sentier qui serpente du départ jusqu'à
/// l'objectif, avec une pause de stabilisation après chaque palier
/// et un repère « Tu es ici ».
class CheminScreen extends StatelessWidget {
  const CheminScreen({super.key});

  static const _espacement = 130.0;

  @override
  Widget build(BuildContext context) {
    final profil = context.watch<ProfilProvider>().profil!;
    final pesees = context.watch<PoidsProvider>().pesees;
    final theme = Theme.of(context);
    final maintenant = DateTime.now();
    final etat = PaliersService.calculer(profil, pesees, maintenant: maintenant);

    // ----- Étapes : départ, puis palier + stabilisation, …, objectif -----
    final etapes = <_Etape>[const _Etape(_TypeEtape.depart, faite: true)];
    for (final (i, p) in etat.paliers.indexed) {
      etapes.add(_Etape(_TypeEtape.palier, palier: p, faite: p.atteint));
      if (!p.estObjectif) {
        final stabilisee = i < etat.dernierAtteint ||
            (i == etat.dernierAtteint && !etat.enStabilisation);
        etapes.add(_Etape(_TypeEtape.stabilisation, palier: p, faite: stabilisee));
      }
    }

    // ----- Position « Tu es ici » (en nombre d'étapes, décimale possible) -----
    final d = etat.dernierAtteint;
    final double position;
    if (pesees.isEmpty) {
      position = 0;
    } else if (etat.objectifAtteint) {
      position = (etapes.length - 1).toDouble();
    } else if (d < 0) {
      position = etat.avancement; // Entre le départ et le palier 1.
    } else if (etat.enStabilisation) {
      position = 2.0 * d + 2; // Sur l'étape de stabilisation.
    } else {
      position = 2.0 * d + 2 + etat.avancement; // Vers le palier suivant.
    }

    // ----- Message principal -----
    final String message;
    if (pesees.isEmpty) {
      message = 'Ajoute une pesée pour te situer sur le chemin 🌱';
    } else if (etat.objectifAtteint) {
      message = 'Objectif atteint 🎉 Place à l\'équilibre : garde les habitudes '
          'qui te font du bien.';
    } else if (etat.enStabilisation) {
      final jours = etat.joursStabilisationRestants(maintenant);
      message = 'Phase de stabilisation : encore $jours ${jours > 1 ? 'jours' : 'jour'}. '
          'Garde tes habitudes, pas besoin de viser plus 🌿';
    } else {
      final prochain = etat.paliers[d + 1];
      message = 'Prochain palier : ${formaterDecimal(prochain.poidsKg)} kg. '
          'Chaque petit pas compte 💗';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon chemin')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      message,
                      key: const Key('message_chemin'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: LayoutBuilder(
                      builder: (context, c) => _Sentier(
                        largeur: c.maxWidth,
                        espacement: _espacement,
                        etapes: etapes,
                        position: position,
                        profilDepartKg: profil.poidsDepartKg,
                        afficherRepere: pesees.isNotEmpty,
                        stabilisationEnCours: etat.enStabilisation ? d : -1,
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pourquoi des paliers ?', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(
                          'Avancer par étapes d\'environ 5 % et laisser ensuite '
                          'le corps se stabiliser 2 semaines aide souvent à garder '
                          'les résultats dans la durée. Un palier est validé quand '
                          'ta tendance sur 7 jours l\'atteint : une petite remontée '
                          'ne t\'enlève jamais un palier déjà gagné.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le sentier dessiné, avec ses étapes et le repère animé.
class _Sentier extends StatelessWidget {
  const _Sentier({
    required this.largeur,
    required this.espacement,
    required this.etapes,
    required this.position,
    required this.profilDepartKg,
    required this.afficherRepere,
    required this.stabilisationEnCours,
  });

  final double largeur;
  final double espacement;
  final List<_Etape> etapes;
  final double position;
  final double profilDepartKg;
  final bool afficherRepere;
  /// Index du palier dont la stabilisation est en cours (-1 si aucune).
  final int stabilisationEnCours;

  static const _tailleNoeud = 56.0;

  /// Centre de chaque étape : le sentier ondule de gauche à droite.
  Offset _point(int i) => Offset(
        largeur / 2 + largeur * 0.22 * math.sin(i * math.pi / 2),
        50 + i * espacement,
      );

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final points = [for (var i = 0; i < etapes.length; i++) _point(i)];
    final hauteur = points.last.dy + 70;

    return TweenAnimationBuilder<double>(
      // Le repère et la partie parcourue avancent doucement à l'ouverture.
      tween: Tween(begin: 0, end: position),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOutCubic,
      builder: (context, pos, _) {
        final repere = _positionSur(points, pos);
        return SizedBox(
          height: hauteur,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PeintreSentier(
                    points: points,
                    parcouru: pos,
                    couleurFond: couleurs.outlineVariant,
                    couleurParcouru: couleurs.primary,
                  ),
                ),
              ),
              for (var i = 0; i < etapes.length; i++) ..._noeud(context, i, points[i]),
              if (afficherRepere)
                Positioned(
                  left: repere.dx - 52,
                  top: repere.dy - 54,
                  child: const _Repere(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Point du sentier à une position décimale (interpolation entre étapes).
  Offset _positionSur(List<Offset> points, double pos) {
    final i = pos.floor().clamp(0, points.length - 1);
    if (i >= points.length - 1) return points.last;
    final metrique = _PeintreSentier.segment(points[i], points[i + 1])
        .computeMetrics()
        .first;
    return metrique.getTangentForOffset(metrique.length * (pos - i))!.position;
  }

  List<Widget> _noeud(BuildContext context, int i, Offset c) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final etape = etapes[i];
    final aGauche = c.dx > largeur / 2; // l'étiquette va du côté le plus large
    final largeurEtiquette = math.max(110.0, largeur / 2 - _tailleNoeud / 2 - 20);

    final (String emoji, String titre, String sousTitre) = switch (etape.type) {
      _TypeEtape.depart => ('🌱', 'Départ', '${formaterDecimal(profilDepartKg)} kg'),
      _TypeEtape.palier => (
          etape.palier!.estObjectif ? '🎯' : (etape.faite ? '🌸' : '${etape.palier!.numero}'),
          etape.palier!.estObjectif ? 'Objectif' : 'Palier ${etape.palier!.numero}',
          [
            '${formaterDecimal(etape.palier!.poidsKg)} kg',
            if (etape.palier!.atteintLe != null)
              'atteint le ${DateFormat('d MMM', 'fr_FR').format(etape.palier!.atteintLe!)}',
          ].join('\n'),
        ),
      _TypeEtape.stabilisation => (
          '🌿',
          'Stabilisation',
          etape.faite
              ? '2 semaines, c\'est fait'
              : etape.palier!.numero - 1 == stabilisationEnCours
                  ? 'en cours'
                  : '2 semaines de pause',
        ),
    };

    final petit = etape.type == _TypeEtape.stabilisation;
    final taille = petit ? 44.0 : _tailleNoeud;

    return [
      Positioned(
        left: c.dx - taille / 2,
        top: c.dy - taille / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: taille,
          height: taille,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: etape.faite ? couleurs.primary : couleurs.surfaceContainerLowest,
            border: Border.all(color: couleurs.primary, width: 2.5),
            boxShadow: [
              if (etape.faite)
                BoxShadow(color: Palette.framboise.withValues(alpha: 0.3), blurRadius: 10),
            ],
          ),
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: petit ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: etape.faite ? couleurs.onPrimary : couleurs.primary,
            ),
          ),
        ),
      ),
      Positioned(
        left: aGauche ? c.dx - taille / 2 - 12 - largeurEtiquette : c.dx + taille / 2 + 12,
        top: c.dy - 22,
        width: largeurEtiquette,
        child: Column(
          crossAxisAlignment: aGauche ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(titre,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              sousTitre,
              textAlign: aGauche ? TextAlign.end : TextAlign.start,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];
  }
}

/// Pastille « 📍 Tu es ici ».
class _Repere extends StatelessWidget {
  const _Repere();

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      child: Center(
        child: Container(
          key: const Key('tu_es_ici'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: couleurs.inverseSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Text(
            '📍 Tu es ici',
            style: TextStyle(
              color: couleurs.onInverseSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dessine le sentier : la partie à venir en pointillés clairs,
/// la partie parcourue en trait plein framboise.
class _PeintreSentier extends CustomPainter {
  _PeintreSentier({
    required this.points,
    required this.parcouru,
    required this.couleurFond,
    required this.couleurParcouru,
  });

  final List<Offset> points;
  final double parcouru;
  final Color couleurFond;
  final Color couleurParcouru;

  /// Courbe douce entre deux étapes.
  static Path segment(Offset a, Offset b) {
    final milieuY = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, milieuY, b.dx, milieuY, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fond = Paint()
      ..color = couleurFond
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final plein = Paint()
      ..color = couleurParcouru
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      final metrique = segment(points[i], points[i + 1]).computeMetrics().first;
      // Pointillés pour tout le sentier.
      _pointilles(canvas, metrique, fond);
      // Partie déjà parcourue par-dessus.
      final fraction = (parcouru - i).clamp(0.0, 1.0);
      if (fraction > 0) {
        canvas.drawPath(metrique.extractPath(0, metrique.length * fraction), plein);
      }
    }
  }

  void _pointilles(Canvas canvas, PathMetric metrique, Paint pinceau) {
    for (double d = 0; d < metrique.length; d += 16) {
      canvas.drawPath(metrique.extractPath(d, math.min(d + 8, metrique.length)), pinceau);
    }
  }

  @override
  bool shouldRepaint(_PeintreSentier ancien) =>
      ancien.parcouru != parcouru ||
      ancien.couleurFond != couleurFond ||
      ancien.couleurParcouru != couleurParcouru ||
      ancien.points.length != points.length;
}
