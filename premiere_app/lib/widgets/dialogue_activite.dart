import 'package:material_ui/material_ui.dart';

import '../models/activite.dart';
import '../services/habitudes_service.dart';

/// Résultat de la saisie d'une activité.
typedef SaisieActivite = ({TypeActivite type, int dureeMinutes, String? note});

/// Ouvre un panneau (par le bas) pour noter une activité.
/// Renvoie `null` si l'utilisateur ferme sans enregistrer.
Future<SaisieActivite?> afficherDialogueActivite(BuildContext context) {
  return showModalBottomSheet<SaisieActivite>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _PanneauActivite(),
  );
}

class _PanneauActivite extends StatefulWidget {
  const _PanneauActivite();

  @override
  State<_PanneauActivite> createState() => _PanneauActiviteState();
}

class _PanneauActiviteState extends State<_PanneauActivite> {
  static const _dureesRapides = [10, 20, 30, 45, 60];

  TypeActivite _type = TypeActivite.marche;
  double _duree = 30;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Laisse la place au clavier quand il s'ouvre.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Noter une activité', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Chaque mouvement compte, même 10 minutes 💗', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text('Quoi ?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in TypeActivite.values)
                  ChoiceChip(
                    avatar: Text(t.emoji),
                    label: Text(t.libelle),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Combien de temps ?', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  HabitudesService.formaterMinutes(_duree.round()),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in _dureesRapides)
                  ChoiceChip(
                    label: Text('$d min'),
                    selected: _duree.round() == d,
                    onSelected: (_) => setState(() => _duree = d.toDouble()),
                  ),
              ],
            ),
            Slider(
              value: _duree,
              min: 5,
              max: 180,
              divisions: 35,
              label: HabitudesService.formaterMinutes(_duree.round()),
              onChanged: (v) => setState(() => _duree = v),
            ),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Un petit mot ? (facultatif)',
                hintText: 'Balade au bord de la lagune…',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('bouton_valider_activite'),
                onPressed: () =>
                    Navigator.of(context)
                        .pop((type: _type, dureeMinutes: _duree.round(), note: _note.text)),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
