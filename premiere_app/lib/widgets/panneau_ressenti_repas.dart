import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/jour_habitudes.dart';
import '../models/plat.dart';
import '../providers/habitudes_provider.dart';
import 'selecteur_ressenti.dart';

/// Ouvre le panneau des détails d'un repas noté : moment, taille de la
/// portion et ressentis (faim, satiété, plaisir). Tout est facultatif et
/// enregistré au fur et à mesure.
Future<void> afficherPanneauRessentiRepas(
  BuildContext context,
  String idRepas, {
  bool vientDEtreNote = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _Panneau(idRepas: idRepas, vientDEtreNote: vientDEtreNote),
  );
}

class _Panneau extends StatelessWidget {
  const _Panneau({required this.idRepas, required this.vientDEtreNote});

  final String idRepas;
  final bool vientDEtreNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitudes = context.watch<HabitudesProvider>();
    final repas = habitudes.repasParId(idRepas);
    if (repas == null) return const SizedBox(height: 120);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vientDEtreNote
                  ? '✓ ${repas.emojiPlat ?? '📸'} ${repas.titre}, c\'est noté !'
                  : '${repas.emojiPlat ?? '📸'} ${repas.titre}',
              key: const Key('titre_panneau_repas'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (vientDEtreNote)
              Text(
                'Si tu veux, ajoute quelques détails. Sinon, tu peux fermer 🌸',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            Text('Moment', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in Repas.values)
                  ChoiceChip(
                    avatar: Text(m.emoji),
                    label: Text(m.libelle),
                    selected: repas.repas == m,
                    onSelected: (_) => habitudes.modifierRepas(idRepas, repas: m),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Portion', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TaillePortion>(
                segments: [
                  for (final t in TaillePortion.values)
                    ButtonSegment(value: t, label: Text('${t.emoji} ${t.libelle}')),
                ],
                selected: {repas.taille},
                showSelectedIcon: false,
                onSelectionChanged: (s) => habitudes.modifierRepas(idRepas, taille: s.first),
              ),
            ),
            const SizedBox(height: 16),
            for (final r in RessentiRepas.values) ...[
              SelecteurRessenti(
                ressenti: r,
                valeur: repas.ressentis[r],
                onChoisir: (v) {
                  final nouveaux = {...repas.ressentis};
                  // Toucher à nouveau le même emoji l'efface.
                  if (nouveaux[r] == v) {
                    nouveaux.remove(r);
                  } else {
                    nouveaux[r] = v;
                  }
                  habitudes.modifierRepas(idRepas, ressentis: nouveaux);
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('bouton_terminer_repas'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Terminé'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
