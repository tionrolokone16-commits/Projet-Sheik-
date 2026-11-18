import 'package:material_ui/material_ui.dart';

import '../models/profil.dart';
import '../services/calculs_service.dart';
import 'format.dart';

/// Carte affichant le repère calorique indicatif, toujours accompagné
/// de la mention « Indications générales, pas un avis médical. ».
class CarteObjectifCalorique extends StatelessWidget {
  const CarteObjectifCalorique({
    super.key,
    required this.profil,
    this.poidsActuelKg,
  });

  final Profil profil;

  /// Dernier poids connu ; à défaut, le poids de départ est utilisé.
  final double? poidsActuelKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = CalculsService.objectifCalorique(profil, poidsActuelKg: poidsActuelKg);

    // Phrase d'explication adaptée à la situation.
    final String explication;
    if (r.perteHebdoKg == 0) {
      explication = 'Tu as atteint ton objectif 🎉 Ce repère t\'aide à '
          'garder ton équilibre.';
    } else if (r.plancherApplique) {
      explication = 'Nous gardons un minimum de ${CalculsService.kcalMinimum} '
          'kcal pour bien te nourrir : la perte sera un peu plus lente '
          '(environ ${formaterDecimal(r.perteHebdoKg)} kg par semaine), '
          'et c\'est très bien ainsi.';
    } else {
      explication = 'Pour une perte douce d\'environ '
          '${formaterDecimal(r.perteHebdoKg)} kg par semaine.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Repère énergétique', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${formaterEntier(r.kcalParJour)} kcal / jour',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(explication),
            const SizedBox(height: 8),
            Text(
              'Métabolisme de base : ${formaterEntier(r.metabolismeBase.round())} kcal · '
              'Dépense estimée : ${formaterEntier(r.depenseJournaliere.round())} kcal',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              CalculsService.mentionMedicale,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
