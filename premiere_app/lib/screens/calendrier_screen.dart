import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/habitudes_service.dart';
import '../services/journal_service.dart';
import '../widgets/calendrier_mois.dart';

/// Calendrier du journal. Toucher un jour le renvoie à l'écran précédent.
/// On change de mois avec les flèches ou en glissant.
class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key, required this.jourSelectionne});

  final DateTime jourSelectionne;

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  late DateTime _mois =
      DateTime(widget.jourSelectionne.year, widget.jourSelectionne.month);

  /// Sens de la dernière navigation (pour l'animation de glissement).
  int _sens = 1;

  bool get _estMoisActuel {
    final n = DateTime.now();
    return _mois.year == n.year && _mois.month == n.month;
  }

  void _changerMois(int delta) {
    if (delta > 0 && _estMoisActuel) return; // Pas de mois futurs.
    setState(() {
      _sens = delta;
      _mois = DateTime(_mois.year, _mois.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titreMois = toBeginningOfSentenceCase(
        DateFormat('MMMM y', 'fr_FR').format(_mois));

    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'calendrier',
          child: Material(
            type: MaterialType.transparency,
            child: Text('Mon calendrier', style: theme.appBarTheme.titleTextStyle),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Mois précédent',
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: () => _changerMois(-1),
                            ),
                            Expanded(
                              child: Text(
                                titreMois,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Mois suivant',
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: _estMoisActuel ? null : () => _changerMois(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Glisser à gauche / à droite pour changer de mois.
                        GestureDetector(
                          onHorizontalDragEnd: (d) {
                            final v = d.primaryVelocity ?? 0;
                            if (v > 250) _changerMois(-1);
                            if (v < -250) _changerMois(1);
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (enfant, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: Offset(0.15 * _sens, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: enfant,
                              ),
                            ),
                            child: CalendrierMois(
                              key: ValueKey(_mois),
                              mois: _mois,
                              jourSelectionne: widget.jourSelectionne,
                              onChoisir: (date) => Navigator.of(context).pop(date),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _ResumeMois(mois: _mois),
                const _Legende(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bilan positif du mois : jours notés et habitudes prises en soin.
class _ResumeMois extends StatelessWidget {
  const _ResumeMois({required this.mois});

  final DateTime mois;

  @override
  Widget build(BuildContext context) {
    final habitudes = context.watch<HabitudesProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;
    var joursNotes = 0;
    var totalHabitudes = 0;
    final nbJours = DateTime(mois.year, mois.month + 1, 0).day;
    for (var j = 1; j <= nbJours; j++) {
      final date = DateTime(mois.year, mois.month, j);
      final jour = habitudes.jour(date);
      final activites = habitudes.activitesDu(date);
      if (!jour.estVide || activites.isNotEmpty) joursNotes++;
      totalHabitudes += HabitudesService.tenues(jour,
              activitesDuJour: activites, objectifVerres: objectifVerres)
          .length;
    }
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          joursNotes == 0
              ? 'Un mois tout neuf à écrire 🌱'
              : '$joursNotes ${joursNotes > 1 ? 'jours notés' : 'jour noté'} et '
                  '$totalHabitudes ${totalHabitudes > 1 ? 'habitudes prises' : 'habitude prise'} '
                  'en soin ce mois-ci 🌸',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Explication des couleurs et des points.
class _Legende extends StatelessWidget {
  const _Legende();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final luminosite = theme.colorScheme.brightness;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment lire ton calendrier', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final ton in TonJour.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: ton.couleur(luminosite),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(ton.libelle)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'La couleur vient de ton humeur (énergie, stress, sommeil). '
              'Chaque point • est une habitude prise en soin. '
              'Le poids et les calories n\'apparaissent jamais ici.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
