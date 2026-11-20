import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../services/calories_service.dart';
import '../services/evolution_service.dart';
import 'calendrier_onglet_screen.dart';

/// Évolution des calories jour par jour : consommé, dépensé et objectif,
/// sur 7 ou 30 jours. Toucher un jour ouvre son détail.
class EvolutionCaloriesScreen extends StatefulWidget {
  const EvolutionCaloriesScreen({super.key});

  @override
  State<EvolutionCaloriesScreen> createState() => _EvolutionCaloriesScreenState();
}

class _EvolutionCaloriesScreenState extends State<EvolutionCaloriesScreen> {
  int _jours = 7;

  void _ouvrirJour(DateTime d) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => JourScreen(date: d)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final profil = context.watch<ProfilProvider>().profil;
    final habitudes = context.watch<HabitudesProvider>();
    final pesees = context.watch<PoidsProvider>().pesees;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon évolution')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: profil == null
                ? const Center(child: Text('Complète ton profil pour voir tes calories.'))
                : Builder(
                    builder: (context) {
                      final jours = EvolutionService.derniersJours(
                        nombre: _jours,
                        maintenant: DateTime.now(),
                        profil: profil,
                        pesees: pesees,
                        journal: habitudes.journal,
                        activites: habitudes.activites,
                        kcalConsommees: habitudes.kcalConsommees,
                        aDesRepas: (d) => habitudes.repasPhotosDu(d).isNotEmpty,
                      );
                      final moyenne = EvolutionService.moyenneConsommee(jours);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int>(
                              key: const Key('periode_calories'),
                              segments: const [
                                ButtonSegment(value: 7, label: Text('7 jours')),
                                ButtonSegment(value: 30, label: Text('30 jours')),
                              ],
                              selected: {_jours},
                              showSelectedIcon: false,
                              onSelectionChanged: (s) => setState(() => _jours = s.first),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _GraphiqueCalories(jours: jours, onToucherJour: _ouvrirJour),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    children: [
                                      _Legende(couleur: couleurs.primary, texte: 'Consommé'),
                                      _Legende(couleur: couleurDepense(couleurs), texte: 'Dépensé'),
                                      _Legende(
                                        couleur: couleurs.onSurfaceVariant,
                                        texte: 'Objectif',
                                        pointilles: true,
                                      ),
                                    ],
                                  ),
                                  if (moyenne != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'En moyenne ${CaloriesService.formater(moyenne)} consommées '
                                      'les jours où tes repas sont notés.',
                                      key: const Key('moyenne_calories'),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final j in jours.reversed) _LigneJour(jour: j, onTap: _ouvrirJour),
                          const SizedBox(height: 8),
                          Text(
                            'Estimations. Un jour sans repas noté n\'est pas compté à zéro.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _GraphiqueCalories extends StatelessWidget {
  const _GraphiqueCalories({required this.jours, required this.onToucherJour});

  final List<JourCalories> jours;
  final ValueChanged<DateTime> onToucherJour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final styleAxe = theme.textTheme.labelSmall!.copyWith(color: couleurs.onSurfaceVariant);
    final maxi = jours
        .expand((j) => [j.consomme, j.depense, j.objectif])
        .fold<int>(0, (m, v) => v > m ? v : m);
    final maxY = ((maxi / 500).ceil() * 500 + 250).toDouble();
    final pas = jours.length <= 7 ? 1 : 5;

    LineChartBarData ligne(
      List<FlSpot> points,
      Color couleur, {
      bool pointilles = false,
      bool avecPoints = true,
    }) => LineChartBarData(
      spots: points,
      color: couleur,
      barWidth: pointilles ? 2 : 3,
      isCurved: false,
      dashArray: pointilles ? [6, 4] : null,
      dotData: FlDotData(show: avecPoints && jours.length <= 7),
    );

    return Semantics(
      label: 'Graphique des calories des ${jours.length} derniers jours',
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            minX: 0,
            maxX: (jours.length - 1).toDouble(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 500,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: couleurs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 500,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: styleAxe),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 26,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= jours.length || (jours.length - 1 - i) % pas != 0) {
                      return const SizedBox.shrink();
                    }
                    final d = jours[i].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        jours.length <= 7
                            ? DateFormat('E', 'fr_FR').format(d).substring(0, 1).toUpperCase()
                            : '${d.day}',
                        style: styleAxe,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchCallback: (evenement, reponse) {
                if (evenement is FlTapUpEvent && reponse?.lineBarSpots?.isNotEmpty == true) {
                  onToucherJour(jours[reponse!.lineBarSpots!.first.x.toInt()].date);
                }
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => couleurs.inverseSurface,
                getTooltipItems: (points) => [
                  for (final p in points)
                    LineTooltipItem(
                      CaloriesService.formater(p.y.round()),
                      TextStyle(color: couleurs.onInverseSurface, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              ligne(
                [for (final (i, j) in jours.indexed) FlSpot(i.toDouble(), j.objectif.toDouble())],
                couleurs.onSurfaceVariant,
                pointilles: true,
                avecPoints: false,
              ),
              ligne([
                for (final (i, j) in jours.indexed) FlSpot(i.toDouble(), j.depense.toDouble()),
              ], couleurDepense(couleurs)),
              // Consommé : seulement les jours où des repas sont notés.
              ligne([
                for (final (i, j) in jours.indexed)
                  j.repasNotes ? FlSpot(i.toDouble(), j.consomme.toDouble()) : FlSpot.nullSpot,
              ], couleurs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.couleur, required this.texte, this.pointilles = false});

  final Color couleur;
  final String texte;
  final bool pointilles;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: pointilles ? 2 : 4,
          decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(texte, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LigneJour extends StatelessWidget {
  const _LigneJour({required this.jour, required this.onTap});

  final JourCalories jour;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = jour.date;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('ligne_kcal_${d.year}_${d.month}_${d.day}'),
        onTap: () => onTap(d),
        title: Text(
          toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr_FR').format(d)),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            jour.repasNotes
                ? 'Consommé ${CaloriesService.formater(jour.consomme)}'
                : 'Repas pas notés',
            'Dépensé ${CaloriesService.formater(jour.depense)}',
            'Objectif ${CaloriesService.formater(jour.objectif)}',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

/// Couleur de la courbe « Dépensé » : un violet, bien distinct du rose.
Color couleurDepense(ColorScheme couleurs) =>
    couleurs.brightness == Brightness.dark ? const Color(0xFFB39DDB) : const Color(0xFF6A4FB3);
