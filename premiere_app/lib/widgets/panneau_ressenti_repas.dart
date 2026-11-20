import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/jour_habitudes.dart';
import '../models/plat.dart';
import '../providers/habitudes_provider.dart';
import '../screens/composer_plat_screen.dart';
import '../services/calories_service.dart';
import '../services/ingredients_service.dart';
import 'dialogue_nombre.dart';
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
            // ----- Ingrédients pesés -----
            if (repas.composition.isNotEmpty) ...[
              Text('Ingrédients', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                [
                  for (final c in repas.composition)
                    if (IngredientsService.parId(c.idIngredient) case final i?)
                      '${i.emoji} ${i.nom.split(' (').first} ${c.grammes} g',
                ].join(' · '),
                key: const Key('ingredients_repas'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              key: const Key('detailler_grammes'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ComposerPlatScreen(date: repas.date, idRepas: repas.id),
                ),
              ),
              icon: const Text('⚖️'),
              label: Text(
                repas.composition.isEmpty ? 'Détailler en grammes' : 'Modifier les ingrédients',
              ),
            ),
            const SizedBox(height: 16),
            // ----- Calories (estimées, modifiables) -----
            Text('Calories', style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: CaloriesService.formater(habitudes.kcalRepas(repas)),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: repas.kcalManuel == null ? '  estimation' : '  saisi à la main',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    key: const Key('kcal_repas'),
                  ),
                ),
                if (repas.kcalManuel != null)
                  TextButton(
                    onPressed: () => habitudes.definirKcalRepas(idRepas, null),
                    child: const Text('Estimer'),
                  ),
                TextButton(
                  key: const Key('corriger_kcal'),
                  onPressed: () async {
                    final kcal = await demanderNombre(
                      context,
                      titre: 'Calories de ce repas',
                      initial: habitudes.kcalRepas(repas),
                      aide: 'Si tu connais la valeur (étiquette, appli…), tu peux la corriger.',
                      unite: 'kcal',
                      maximum: 5000,
                    );
                    if (kcal != null) await habitudes.definirKcalRepas(idRepas, kcal);
                  },
                  child: const Text('Corriger'),
                ),
              ],
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
