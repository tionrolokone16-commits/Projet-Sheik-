import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/calendrier_service.dart';
import '../services/recompenses_service.dart';
import 'bilan_screen.dart';
import '../widgets/vue_jour_habitudes.dart';

/// Onglet Calendrier : le mois en un coup d'œil.
///
/// Chaque jour est coloré selon les habitudes prises en soin (rose pâle →
/// rose vif) et porte de petites pastilles. Toucher un jour ouvre son détail.
class CalendrierOngletScreen extends StatefulWidget {
  const CalendrierOngletScreen({super.key});

  @override
  State<CalendrierOngletScreen> createState() => _CalendrierOngletScreenState();
}

class _CalendrierOngletScreenState extends State<CalendrierOngletScreen> {
  DateTime _moisAffiche = DateTime.now();

  /// Vue affichée : le mois (par défaut) ou la semaine.
  bool _vueSemaine = false;

  /// Pages du calendrier (pour les flèches mois précédent / suivant).
  PageController? _pages;

  bool get _estMoisActuel {
    final n = DateTime.now();
    return _moisAffiche.year == n.year && _moisAffiche.month == n.month;
  }

  void _changerMois(bool suivant) {
    const duree = Duration(milliseconds: 300);
    suivant
        ? _pages?.nextPage(duration: duree, curve: Curves.easeOut)
        : _pages?.previousPage(duration: duree, curve: Curves.easeOut);
  }

  static DateTime _sansHeure(DateTime d) => DateTime(d.year, d.month, d.day);

  void _ouvrirJour(DateTime jour) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => JourScreen(date: _sansHeure(jour))));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aujourdhui = _sansHeure(DateTime.now());
    // On écoute les données pour recolorer le calendrier dès qu'elles changent.
    context.watch<HabitudesProvider>();
    context.watch<ReglagesProvider>();

    Widget caseJour(DateTime jourUtc, {bool estAujourdhui = false, bool futur = false}) =>
        _CaseJour(
          date: _sansHeure(jourUtc),
          estAujourdhui: estAujourdhui,
          futur: futur,
          onTap: futur ? null : () => _ouvrirJour(jourUtc),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      key: const Key('choix_vue'),
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Mois'),
                          icon: Icon(Icons.calendar_view_month_rounded),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Semaine'),
                          icon: Icon(Icons.bar_chart_rounded),
                        ),
                      ],
                      selected: {_vueSemaine},
                      showSelectedIcon: false,
                      onSelectionChanged: (choix) => setState(() => _vueSemaine = choix.first),
                    ),
                  ),
                ),
                Expanded(
                  child: _vueSemaine
                      // Semaine en cours : graphique, constats, idées et partage.
                      ? VueSemaine(
                          key: const Key('vue_semaine'),
                          lundiInitial: RecompensesService.debutSemaine(DateTime.now()),
                        )
                      : _vueMois(context, theme, aujourdhui, caseJour),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vueMois(
    BuildContext context,
    ThemeData theme,
    DateTime aujourdhui,
    Widget Function(DateTime, {bool estAujourdhui, bool futur}) caseJour,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
      children: [
        // En-tête du mois (dessiné par l'appli).
        Row(
          children: [
            IconButton(
              key: const Key('mois_precedent'),
              tooltip: 'Mois précédent',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => _changerMois(false),
            ),
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(DateFormat('MMMM y', 'fr_FR').format(_moisAffiche)),
                key: const Key('titre_mois'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              key: const Key('mois_suivant'),
              tooltip: 'Mois suivant',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _estMoisActuel ? null : () => _changerMois(true),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: TableCalendar<void>(
              locale: 'fr_FR',
              firstDay: DateTime(2020),
              lastDay: aujourdhui,
              focusedDay: _moisAffiche.isAfter(aujourdhui) ? aujourdhui : _moisAffiche,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
              rowHeight: 70,
              daysOfWeekHeight: 22,
              availableGestures: AvailableGestures.horizontalSwipe,
              // L'en-tête de table_calendar dépend de l'ancienne bibliothèque
              // Material : on le masque et on affiche le nôtre (ci-dessus).
              headerVisible: false,
              onCalendarCreated: (pages) => _pages = pages,
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, _) => 'LMMJVSD'[date.weekday - 1],
                weekdayStyle: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                weekendStyle: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onPageChanged: (mois) => setState(() => _moisAffiche = mois),
              // Toutes les cases sont dessinées par l'appli (thème rose).
              calendarBuilders: CalendarBuilders<void>(
                defaultBuilder: (context, jour, _) => caseJour(jour),
                todayBuilder: (context, jour, _) => caseJour(jour, estAujourdhui: true),
                disabledBuilder: (context, jour, _) =>
                    // Jours du mois suivant : rien (comme les autres jours hors du mois).
                    jour.month == _moisAffiche.month
                    ? caseJour(jour, futur: true)
                    : const SizedBox.shrink(),
                outsideBuilder: (context, jour, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        const _Legende(),
      ],
    );
  }
}

/// Une case du calendrier : numéro du jour, couleur et pastilles.
class _CaseJour extends StatelessWidget {
  const _CaseJour({
    required this.date,
    required this.estAujourdhui,
    required this.futur,
    required this.onTap,
  });

  final DateTime date;
  final bool estAujourdhui;
  final bool futur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final habitudes = context.read<HabitudesProvider>();
    final reglages = context.read<ReglagesProvider>().reglages;
    final resume = CalendrierService.resume(
      jour: habitudes.jour(date),
      activitesDuJour: habitudes.activitesDu(date),
      repasDuJour: habitudes.repasPhotosDu(date),
      objectifVerres: reglages.objectifVerres,
      suiviCycle: reglages.suiviCycle,
    );
    final fond =
        CalendrierService.couleur(resume.habitudes, couleurs.brightness) ??
        couleurs.surfaceContainerHigh;

    return Semantics(
      button: onTap != null,
      label: [
        DateFormat('EEEE d MMMM', 'fr_FR').format(date),
        if (resume.habitudes > 0) '${resume.habitudes} habitudes prises en soin',
        if (resume.repasNotes) 'repas notés',
        if (resume.regles) 'règles',
      ].join(', '),
      excludeSemantics: true,
      // SizedBox.expand : toutes les cases ont la même taille, quel que soit
      // leur contenu.
      child: SizedBox.expand(
        child: Opacity(
          opacity: futur ? 0.35 : 1,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Material(
              color: fond,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: estAujourdhui ? couleurs.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('jour_${date.year}_${date.month}_${date.day}'),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Column(
                    children: [
                      Text(
                        '${date.day}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: estAujourdhui ? FontWeight.w900 : FontWeight.w600,
                          color: couleurs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Pastilles : petites, sur deux lignes au plus.
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 1,
                          runSpacing: 0,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            for (final p in resume.pastilles)
                              Text(p, style: const TextStyle(fontSize: 9, height: 1.2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Explication des couleurs et des pastilles.
class _Legende extends StatelessWidget {
  const _Legende();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suiviCycle = context.watch<ReglagesProvider>().reglages.suiviCycle;
    final teintes = CalendrierService.teintes(theme.colorScheme.brightness);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment lire ton calendrier', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Moins', style: theme.textTheme.bodySmall),
                const SizedBox(width: 6),
                for (final t in teintes)
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: t, borderRadius: BorderRadius.circular(6)),
                  ),
                const SizedBox(width: 6),
                Text('Plus', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Plus le rose est vif, plus tu as pris soin de tes habitudes ce jour-là '
              '(eau, sommeil, mouvement, repas). Les jours vides restent tout doux : '
              'aucun n\'est jamais rouge.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                const Text('🍽️ repas notés'),
                const Text('💧 eau'),
                const Text('🏃🏾‍♀️ mouvement (activité, séance, 5 000 pas)'),
                const Text('🙂 humeur'),
                const Text('🌸 repas plaisir'),
                if (suiviCycle) const Text('🩸 règles'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Le poids et ce que tu manges ne changent jamais la couleur d\'un jour.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Détail d'un jour, ouvert depuis le calendrier : le journal de ce jour-là
/// (repas, eau, humeur, sommeil, activité, petit mot…), modifiable.
class JourScreen extends StatelessWidget {
  const JourScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr_FR').format(date))),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: VueJourHabitudes(date: date),
          ),
        ),
      ),
    );
  }
}
