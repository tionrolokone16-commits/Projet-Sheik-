import 'package:material_ui/material_ui.dart';

import '../services/calculs_service.dart';
import 'format.dart';

/// Message doux affiché quand l'objectif correspond à un IMC inférieur à 18,5.
class CarteImcTropBas extends StatelessWidget {
  const CarteImcTropBas({super.key, required this.tailleCm});

  final double tailleCm;

  @override
  Widget build(BuildContext context) {
    final minimum = formaterDecimal(CalculsService.poidsObjectifMinimal(tailleCm));
    return CarteDouce(
      titre: 'Prenons soin de toi',
      message:
          'Cet objectif correspondrait à un IMC inférieur à 18,5, nous ne '
          'pouvons donc pas le retenir. Pour ta taille, le repère minimum est '
          'de $minimum kg. N\'hésite pas à en parler à un professionnel de '
          'santé : il pourra t\'aider à définir un objectif adapté 💗',
    );
  }
}

/// Encadré d'information au ton doux (jamais rouge ni alarmant).
class CarteDouce extends StatelessWidget {
  const CarteDouce({
    super.key,
    required this.message,
    this.icone = Icons.favorite_outline,
    this.titre,
  });

  final String message;
  final IconData icone;
  final String? titre;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Card(
      color: couleurs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: couleurs.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titre != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        titre!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: couleurs.onTertiaryContainer,
                        ),
                      ),
                    ),
                  Text(message, style: TextStyle(color: couleurs.onTertiaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
