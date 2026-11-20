import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/pesee.dart';
import 'format.dart';

/// Période affichée sur le graphique.
enum PeriodeGraphique {
  unMois('1 mois', 31),
  troisMois('3 mois', 92),
  tout('Tout', null);

  const PeriodeGraphique(this.libelle, this.jours);
  final String libelle;
  final int? jours;
}

/// Courbe d'évolution du poids, avec :
/// - les pesées (points) ;
/// - une ligne de tendance (moyenne des 7 derniers jours), plus lisible ;
/// - le poids objectif en pointillés, s'il est dans la zone affichée.
class GraphiquePoids extends StatelessWidget {
  const GraphiquePoids({
    super.key,
    required this.pesees,
    required this.periode,
    this.poidsObjectifKg,
  });

  final List<Pesee> pesees;
  final PeriodeGraphique periode;
  final double? poidsObjectifKg;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final styleAxe = Theme.of(context).textTheme.bodySmall!;

    // Pesées de la période choisie.
    final limite = periode.jours == null
        ? null
        : DateTime.now().subtract(Duration(days: periode.jours!));
    final visibles = pesees.where((p) => limite == null || p.date.isAfter(limite)).toList();

    if (visibles.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            visibles.isEmpty
                ? 'Pas encore de pesée sur cette période.'
                : 'Ajoute une deuxième pesée pour voir ta courbe se dessiner 🌱',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // L'axe horizontal compte les jours depuis la première pesée visible.
    final debut = visibles.first.date;
    double enJours(DateTime d) => d.difference(debut).inHours / 24;

    final points = [for (final p in visibles) FlSpot(enJours(p.date), p.poidsKg)];

    // Tendance : moyenne des pesées des 7 derniers jours pour chaque point.
    final tendance = [for (final p in visibles) FlSpot(enJours(p.date), _moyenne7Jours(p.date))];

    final minPoids = visibles.map((p) => p.poidsKg).reduce(math.min);
    final maxPoids = visibles.map((p) => p.poidsKg).reduce(math.max);
    final minY = (minPoids - 1).floorToDouble();
    final maxY = (maxPoids + 1).ceilToDouble();
    final maxX = math.max(points.last.x, 1.0);

    final objectifVisible =
        poidsObjectifKg != null && poidsObjectifKg! >= minY && poidsObjectifKg! <= maxY;

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 8),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: couleurs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: math.max(1, ((maxY - minY) / 4).roundToDouble()),
                  getTitlesWidget: (valeur, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(formaterDecimal(valeur), style: styleAxe),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: math.max(1, (maxX / 4).ceilToDouble()),
                  getTitlesWidget: (valeur, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat(
                        'd MMM',
                        'fr_FR',
                      ).format(debut.add(Duration(hours: (valeur * 24).round()))),
                      style: styleAxe,
                    ),
                  ),
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (objectifVisible)
                  HorizontalLine(
                    y: poidsObjectifKg!,
                    color: couleurs.tertiary,
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: styleAxe.copyWith(color: couleurs.tertiary),
                      labelResolver: (_) => 'Objectif',
                    ),
                  ),
              ],
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => couleurs.inverseSurface,
                getTooltipItems: (touches) => [
                  for (final t in touches)
                    // On n'affiche une bulle que pour les vraies pesées.
                    t.barIndex == 0
                        ? LineTooltipItem(
                            '${formaterDecimal(t.y)} kg\n'
                            '${DateFormat('d MMM', 'fr_FR').format(visibles[t.spotIndex].date)}',
                            TextStyle(color: couleurs.onInverseSurface),
                          )
                        : null,
                ],
              ),
            ),
            lineBarsData: [
              // Pesées réelles.
              LineChartBarData(
                spots: points,
                color: couleurs.primary,
                barWidth: 2.5,
                isCurved: false,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: couleurs.primary.withValues(alpha: 0.10),
                ),
              ),
              // Tendance lissée.
              LineChartBarData(
                spots: tendance,
                color: couleurs.secondary.withValues(alpha: 0.7),
                barWidth: 2,
                isCurved: true,
                preventCurveOverShooting: true,
                dotData: const FlDotData(show: false),
                dashArray: [2, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Moyenne des pesées sur les 7 jours se terminant à [date] (incluse).
  double _moyenne7Jours(DateTime date) {
    final debut = date.subtract(const Duration(days: 6));
    final fenetre = pesees
        .where((p) => !p.date.isBefore(debut) && !p.date.isAfter(date))
        .map((p) => p.poidsKg)
        .toList();
    return fenetre.reduce((a, b) => a + b) / fenetre.length;
  }
}
