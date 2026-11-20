import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/recette.dart';
import '../providers/recompenses_provider.dart';
import '../services/recettes_service.dart';
import '../services/recompenses_service.dart';
import '../widgets/carte_recette.dart';

/// Recettes de chez nous : des cartes à retourner, plat d'origine au recto,
/// version plus équilibrée au verso.
class RecettesScreen extends StatelessWidget {
  const RecettesScreen({super.key});

  Future<void> _cuisinee(BuildContext context, Recette recette) async {
    final recompenses = context.read<RecompensesProvider>();
    final maintenant = DateTime.now();
    final defiChoisi = recompenses.defisDeLaSemaine(maintenant).contains(Defi.recetteIvoirienne);
    if (defiChoisi) {
      // Fait avancer le défi « recette ivoirienne revisitée ».
      await recompenses.ajusterDefi(maintenant, Defi.recetteIvoirienne, 1);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          defiChoisi
              ? '${recette.emoji} Bravo ! Ton défi de la semaine avance.'
              : '${recette.emoji} Bravo, bon appétit !',
        ),
        action:
            defiChoisi ||
                recompenses.defisDeLaSemaine(maintenant).length >= RecompensesService.defisMax
            ? null
            : SnackBarAction(
                label: 'En faire un défi',
                onPressed: () async {
                  await recompenses.choisirDefi(maintenant, Defi.recetteIvoirienne);
                  await recompenses.ajusterDefi(maintenant, Defi.recetteIvoirienne, 1);
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recettes de chez nous')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: LayoutBuilder(
              builder: (context, contraintes) {
                // 1 colonne sur téléphone, 2 sur iPad.
                final colonnes = contraintes.maxWidth > 640 ? 2 : 1;
                final largeur = (contraintes.maxWidth - 32 - 12 * (colonnes - 1)) / colonnes;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(
                      'Nos plats ont toute leur place. Retourne une carte pour '
                      'découvrir une façon plus équilibrée de les savourer 🌸',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final (i, r) in RecettesService.recettes.indexed)
                          SizedBox(
                                width: largeur,
                                child: CarteRecette(
                                  recette: r,
                                  onCuisinee: () => _cuisinee(context, r),
                                ),
                              )
                              .animate(delay: (60 * i).ms)
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                      ],
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
