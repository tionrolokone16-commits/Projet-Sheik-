import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/jour_habitudes.dart';

/// Rangée de 5 emojis à toucher pour noter un ressenti (énergie, stress…).
/// L'emoji choisi grossit et se pose sur une pastille rose.
class SelecteurRessenti extends StatelessWidget {
  const SelecteurRessenti({
    super.key,
    required this.ressenti,
    required this.valeur,
    required this.onChoisir,
  });

  final Echelle ressenti;

  /// Niveau choisi, de 1 à 5 (`null` si rien n'est choisi).
  final int? valeur;
  final ValueChanged<int> onChoisir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(ressenti.libelle,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            // Description du niveau choisi, en fondu.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                valeur == null ? '' : ressenti.descriptions[valeur! - 1],
                key: ValueKey(valeur),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var niveau = 1; niveau <= 5; niveau++)
              _Emoji(
                emoji: ressenti.emojis[niveau - 1],
                description: '${ressenti.libelle} : ${ressenti.descriptions[niveau - 1]}',
                choisi: valeur == niveau,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChoisir(niveau);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _Emoji extends StatelessWidget {
  const _Emoji({
    required this.emoji,
    required this.description,
    required this.choisi,
    required this.onTap,
  });

  final String emoji;
  final String description;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: choisi,
      label: description,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: choisi ? couleurs.primaryContainer : Colors.transparent,
            border: Border.all(
              color: choisi ? couleurs.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            scale: choisi ? 1.25 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              // Les emojis non choisis restent bien visibles, juste plus discrets.
              opacity: choisi ? 1 : 0.75,
              duration: const Duration(milliseconds: 250),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }
}
