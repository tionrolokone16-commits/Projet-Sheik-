import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../screens/ajouter_repas_screen.dart';
import '../services/rappels_service.dart';

/// Rappel doux affiché sur l'accueil aux heures de repas :
/// « Tu veux noter ton déjeuner ? 🌸 » — Noter / Plus tard.
/// Rien ne s'affiche si le repas est déjà noté, si le rappel a été mis
/// de côté aujourd'hui, ou si les rappels sont désactivés.
class CarteRappelRepas extends StatelessWidget {
  const CarteRappelRepas({super.key});

  @override
  Widget build(BuildContext context) {
    final maintenant = DateTime.now();
    final reglagesProvider = context.watch<ReglagesProvider>();
    final habitudes = context.watch<HabitudesProvider>();
    final repas = RappelsService.rappelActuel(
      maintenant: maintenant,
      reglages: reglagesProvider.reglages,
      dejaNotes: habitudes.jour(maintenant).repas,
      misDeCote: reglagesProvider.rappelsMisDeCote(maintenant),
    );
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: repas == null
          ? const SizedBox(width: double.infinity)
          : Card(
              key: const Key('rappel_repas'),
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(repas.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            RappelsService.message(repas),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          key: const Key('rappel_plus_tard'),
                          onPressed: () =>
                              reglagesProvider.mettreRappelDeCote(repas, DateTime.now()),
                          child: const Text('Plus tard'),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.tonal(
                          key: const Key('rappel_noter'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AjouterRepasScreen(date: DateTime.now(), moment: repas),
                            ),
                          ),
                          child: const Text('Noter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
    );
  }
}
