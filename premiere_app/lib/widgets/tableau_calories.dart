import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/profil_provider.dart';
import '../screens/calendrier_onglet_screen.dart';
import '../screens/evolution_calories_screen.dart';
import '../services/calories_service.dart';
import '../services/depense_service.dart';
import 'energie.dart';

/// Grand tableau de bord des calories du jour (accueil) :
/// anneau « consommé / objectif », dépensé et reste.
class TableauCalories extends StatelessWidget {
  const TableauCalories({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final profil = context.watch<ProfilProvider>().profil;
    final objectif = objectifActuel(context);
    final poids = poidsActuel(context);
    if (profil == null || objectif == null || poids == null) return const SizedBox.shrink();

    final habitudes = context.watch<HabitudesProvider>();
    final maintenant = DateTime.now();
    final consomme = habitudes.kcalConsommees(maintenant);
    final depense = DepenseService.calculer(
      profil: profil,
      poidsKg: poids,
      jour: habitudes.jour(maintenant),
      activitesDuJour: habitudes.activitesDu(maintenant),
    ).total;
    final cible = objectif.kcalParJour;
    final part = cible <= 0 ? 0.0 : consomme / cible;

    Widget chiffre(String libelle, int kcal, Key cle) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(libelle, style: theme.textTheme.labelMedium),
          Text(
            CaloriesService.formater(kcal),
            key: cle,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    return Card(
      key: const Key('tableau_calories'),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔥 Mes calories du jour',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Anneau : consommé sur objectif.
                InkWell(
                  key: const Key('accueil_objectif_kcal'),
                  customBorder: const CircleBorder(),
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => JourScreen(date: maintenant))),
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: part.clamp(0.0, 1.0),
                          strokeWidth: 14,
                          strokeCap: StrokeCap.round,
                          backgroundColor: couleurs.primaryContainer,
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$consomme',
                                    key: const Key('accueil_kcal_consomme'),
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: couleurs.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  'sur $cible kcal',
                                  style: theme.textTheme.labelSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      chiffre('Consommé', consomme, const Key('tableau_consomme')),
                      chiffre('Dépensé', depense, const Key('tableau_depense')),
                      chiffre('Objectif', cible, const Key('tableau_objectif')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              texteReste(consomme, cible),
              key: const Key('tableau_reste'),
              style: theme.textTheme.titleSmall?.copyWith(
                color: couleurs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (habitudes.repasACompleter(maintenant).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '⚖️ ${habitudes.repasACompleter(maintenant).length} repas sans ingrédients : '
                  'touche l\'anneau puis le repas pour indiquer les grammes.',
                  key: const Key('tableau_a_completer'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('bouton_evolution_calories'),
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const EvolutionCaloriesScreen())),
                icon: const Icon(Icons.show_chart_rounded),
                label: const Text('Voir mon évolution'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
