import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../services/calendrier_service.dart';

/// Habitudes prises en soin jour par jour (0 à 4), du lundi au dimanche.
///
/// Mêmes roses que le calendrier. Un jour sans habitude garde une petite
/// barre neutre : il n'est jamais mis en avant ni coloré en rouge.
class GraphiqueSemaine extends StatelessWidget {
  const GraphiqueSemaine({super.key, required this.habitudesParJour});

  final List<int> habitudesParJour;

  static const _lettres = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _noms = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final styleAxe = theme.textTheme.labelMedium!.copyWith(color: couleurs.onSurfaceVariant);

    return Semantics(
      label: [
        'Habitudes prises en soin',
        for (var i = 0; i < 7; i++) '${_noms[i]} ${habitudesParJour[i]} sur 4',
      ].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        height: 170,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: 4,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: couleurs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 22,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: styleAxe),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_lettres[v.toInt()], style: styleAxe),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < 7; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      // Jour vide : petite barre neutre, juste pour garder le rythme.
                      toY: habitudesParJour[i] == 0 ? 0.12 : habitudesParJour[i].toDouble(),
                      width: 22,
                      borderRadius: BorderRadius.circular(8),
                      color:
                          CalendrierService.couleur(habitudesParJour[i], couleurs.brightness) ??
                          couleurs.surfaceContainerHighest,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
