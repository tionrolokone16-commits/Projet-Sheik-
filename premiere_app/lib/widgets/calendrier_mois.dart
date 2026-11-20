import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/habitudes_service.dart';
import '../services/journal_service.dart';

/// Grille d'un mois : chaque jour est coloré selon l'humeur notée,
/// et de petits points montrent les habitudes prises en soin.
class CalendrierMois extends StatelessWidget {
  const CalendrierMois({
    super.key,
    required this.mois,
    required this.onChoisir,
    this.jourSelectionne,
  });

  /// N'importe quelle date du mois à afficher.
  final DateTime mois;
  final ValueChanged<DateTime> onChoisir;
  final DateTime? jourSelectionne;

  static const _initiales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final habitudes = context.watch<HabitudesProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;
    final theme = Theme.of(context);

    final premier = DateTime(mois.year, mois.month, 1);
    final nbJours = DateTime(mois.year, mois.month + 1, 0).day;
    final decalage = premier.weekday - 1; // La semaine commence le lundi.
    final maintenant = DateTime.now();
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);

    return Column(
      children: [
        Row(
          children: [
            for (final i in _initiales)
              Expanded(
                child: Center(
                  child: Text(
                    i,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.82,
          children: [
            for (var i = 0; i < decalage; i++) const SizedBox.shrink(),
            for (var j = 1; j <= nbJours; j++)
              () {
                final date = DateTime(mois.year, mois.month, j);
                final jour = habitudes.jour(date);
                final nbHabitudes = HabitudesService.tenues(
                  jour,
                  activitesDuJour: habitudes.activitesDu(date),
                  objectifVerres: objectifVerres,
                ).length;
                return _CaseJour(
                  date: date,
                  ton: JournalService.ton(jour),
                  nbHabitudes: nbHabitudes,
                  estAujourdhui: date == aujourdhui,
                  estSelectionne:
                      jourSelectionne != null && DateUtils.isSameDay(date, jourSelectionne),
                  estFutur: date.isAfter(aujourdhui),
                  onTap: () => onChoisir(date),
                );
              }(),
          ],
        ),
      ],
    );
  }
}

class _CaseJour extends StatelessWidget {
  const _CaseJour({
    required this.date,
    required this.ton,
    required this.nbHabitudes,
    required this.estAujourdhui,
    required this.estSelectionne,
    required this.estFutur,
    required this.onTap,
  });

  final DateTime date;
  final TonJour? ton;
  final int nbHabitudes;
  final bool estAujourdhui;
  final bool estSelectionne;
  final bool estFutur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final fond = ton?.couleur(couleurs.brightness) ?? couleurs.surfaceContainerHigh;

    return Semantics(
      button: !estFutur,
      label: [
        DateFormat('EEEE d MMMM', 'fr_FR').format(date),
        if (ton != null) ton!.libelle,
        if (nbHabitudes > 0) '$nbHabitudes habitudes prises en soin',
      ].join(', '),
      child: Opacity(
        opacity: estFutur ? 0.35 : 1,
        child: Material(
          color: fond,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: estSelectionne
                  ? couleurs.primary
                  : estAujourdhui
                  ? couleurs.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: estSelectionne ? 2.5 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: estFutur ? null : onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: estAujourdhui ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Un point par habitude prise en soin (jusqu'à 4).
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < nbHabitudes; i++)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: couleurs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
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
