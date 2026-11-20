import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/recommandations_service.dart';
import 'energie.dart';

/// « Mes recommandations » : quand la journée est complète (repas, eau, nuit,
/// énergie), des conseils tirés de ce qui a été noté. Avant cela, la carte
/// indique ce qu'il reste à noter (sauf si [seulementSiComplete]).
class CarteRecommandations extends StatelessWidget {
  const CarteRecommandations({super.key, required this.date, this.seulementSiComplete = false});

  final DateTime date;

  /// Sur l'accueil : rien tant que la journée n'est pas complète.
  final bool seulementSiComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final habitudes = context.watch<HabitudesProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;
    final jour = habitudes.jour(date);
    final repas = habitudes.repasPhotosDu(date);
    final manquantes = RecommandationsService.manquantes(jour: jour, repasDuJour: repas);
    if (manquantes.isNotEmpty && seulementSiComplete) return const SizedBox.shrink();

    final titre = Text(
      '💡 Mes recommandations',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );

    if (manquantes.isNotEmpty) {
      return Card(
        key: const Key('recommandations_a_completer'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titre,
              const SizedBox(height: 8),
              Text(
                'Note encore ${manquantes.map((m) => '${m.emoji} ${m.libelle}').join(', ')} '
                'pour recevoir tes recommandations du jour.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final recommandations = RecommandationsService.calculer(
      jour: jour,
      repasDuJour: repas,
      activitesDuJour: habitudes.activitesDu(date),
      objectifVerres: objectifVerres,
      consomme: habitudes.kcalConsommees(date),
      // Tant que des repas n'ont pas leurs ingrédients, le total serait faux :
      // pas de conseil sur les calories.
      objectifKcal: habitudes.repasACompleter(date).isEmpty
          ? objectifActuel(context)?.kcalParJour
          : null,
    );
    return Card(
      key: const Key('carte_recommandations'),
      color: couleurs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titre,
            const SizedBox(height: 4),
            Text(
              'Ta journée est complète, merci ! Voici mes conseils :',
              style: theme.textTheme.bodySmall,
            ),
            for (final r in recommandations)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.titre,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(r.texte, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
