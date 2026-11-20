import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/ingredient.dart';
import '../models/jour_habitudes.dart';
import '../providers/habitudes_provider.dart';
import '../services/assiette_service.dart';
import '../services/calories_service.dart';
import '../services/ingredients_service.dart';
import '../widgets/dialogue_nombre.dart';

/// Composer un plat au gramme près : chaque ingrédient avec son poids,
/// et le total des calories calculé en direct.
///
/// Sans [idRepas] : un nouveau repas est noté à [date].
/// Avec [idRepas] : la composition de ce repas est modifiée.
class ComposerPlatScreen extends StatefulWidget {
  const ComposerPlatScreen({
    super.key,
    required this.date,
    this.moment,
    this.idRepas,
    this.nomInitial,
    this.emojiInitial,
    this.ingredientsDuPlat = const [],
  });

  final DateTime date;
  final Repas? moment;
  final String? idRepas;

  /// Plat choisi dans la bibliothèque, le plan ou « Mes plats » : son nom
  /// et ses ingrédients principaux (pour proposer les ingrédients habituels).
  final String? nomInitial;
  final String? emojiInitial;
  final List<String> ingredientsDuPlat;

  @override
  State<ComposerPlatScreen> createState() => _ComposerPlatScreenState();
}

class _ComposerPlatScreenState extends State<ComposerPlatScreen> {
  final List<Composant> _composition = [];
  final _nom = TextEditingController();
  late Repas _moment = widget.moment ?? AssietteService.repasSelonHeure(DateTime.now());

  /// Ingrédients habituels du plat, proposés en une touche (sans poids).
  List<Ingredient> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _nom.text = widget.nomInitial ?? '';
    var nomPlat = widget.nomInitial ?? '';
    // Modification d'un repas existant : on repart de sa composition.
    final id = widget.idRepas;
    if (id != null) {
      final repas = context.read<HabitudesProvider>().repasParId(id);
      if (repas != null) {
        _composition.addAll(repas.composition);
        _nom.text = repas.nomPlat ?? '';
        nomPlat = repas.nomPlat ?? '';
        _moment = repas.repas;
      }
    }
    _suggestions = nomPlat.isEmpty
        ? const []
        : IngredientsService.suggestionsPour(nomPlat, widget.ingredientsDuPlat);
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  DateTime get _horodatage {
    final n = DateTime.now();
    if (DateUtils.isSameDay(widget.date, n)) return n;
    final heure = switch (_moment) {
      Repas.petitDejeuner => 8,
      Repas.dejeuner => 13,
      Repas.collation => 16,
      Repas.diner => 20,
    };
    return DateTime(widget.date.year, widget.date.month, widget.date.day, heure);
  }

  Future<void> _ajouterIngredient() async {
    final ingredient = await showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ChoixIngredient(),
    );
    if (ingredient == null || !mounted) return;
    await _ajouter(ingredient);
  }

  /// Ajoute un ingrédient après avoir demandé son poids.
  Future<void> _ajouter(Ingredient ingredient) async {
    final grammes = await _demanderGrammes(ingredient, null);
    if (grammes == null || grammes == 0) return;
    setState(() => _composition.add(Composant(idIngredient: ingredient.id, grammes: grammes)));
  }

  Future<int?> _demanderGrammes(Ingredient i, int? initial) => demanderNombre(
    context,
    titre: '${i.emoji} ${i.nom}',
    initial: initial,
    aide:
        '${i.kcal100g} kcal pour 100 g. Combien de grammes ? '
        '(une portion habituelle fait environ ${i.portionGrammes} g)',
    unite: 'g',
    maximum: 3000,
  );

  Future<void> _modifierGrammes(int index) async {
    final c = _composition[index];
    final i = IngredientsService.parId(c.idIngredient);
    if (i == null) return;
    final g = await _demanderGrammes(i, c.grammes);
    if (g == null) return;
    setState(() => g == 0 ? _composition.removeAt(index) : _composition[index] = c.avecGrammes(g));
  }

  Future<void> _enregistrer() async {
    final habitudes = context.read<HabitudesProvider>();
    final nom = _nom.text.trim().isEmpty
        ? IngredientsService.nomPropose(_composition)
        : _nom.text.trim();
    final id = widget.idRepas;
    if (id != null) {
      await habitudes.modifierComposition(id, List.of(_composition), nomPlat: nom);
    } else {
      await habitudes.ajouterRepas(
        date: _horodatage,
        repas: _moment,
        portions: IngredientsService.portions(_composition),
        nomPlat: nom,
        emojiPlat: widget.emojiInitial ?? '⚖️',
        kcalManuel: IngredientsService.kcal(_composition),
        composition: List.of(_composition),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚖️ $nom : ${CaloriesService.formater(IngredientsService.kcal(_composition))}, noté !',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final total = IngredientsService.kcal(_composition);

    return Scaffold(
      appBar: AppBar(title: const Text('Composer mon plat')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                if (widget.idRepas == null) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final m in Repas.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Text(m.emoji),
                              label: Text(m.libelle),
                              selected: _moment == m,
                              onSelected: (_) => setState(() => _moment = m),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  key: const Key('nom_plat_compose'),
                  controller: _nom,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Nom du plat (facultatif)',
                    hintText: _composition.isEmpty
                        ? 'Par exemple : attiéké poisson'
                        : IngredientsService.nomPropose(_composition),
                  ),
                ),
                // ----- Ingrédients habituels du plat -----
                if (_suggestions.any((i) => !_composition.any((c) => c.idIngredient == i.id))) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Ingrédients habituels de ce plat : touche pour ajouter, puis indique les grammes',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in _suggestions)
                        if (!_composition.any((c) => c.idIngredient == i.id))
                          ActionChip(
                            key: Key('suggestion_${i.id}'),
                            avatar: Text(i.emoji),
                            label: Text(i.nom.split(' (').first),
                            onPressed: () => _ajouter(i),
                          ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // ----- Total -----
                Card(
                  color: couleurs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total du plat',
                                style: TextStyle(color: couleurs.onPrimaryContainer),
                              ),
                              Text(
                                CaloriesService.formater(total),
                                key: const Key('total_plat_compose'),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: couleurs.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_composition.fold<int>(0, (s, c) => s + c.grammes)} g',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: couleurs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ----- Ingrédients -----
                if (_composition.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Ajoute chaque ingrédient de ton assiette avec son poids : '
                      'riz, poisson, sauce, huile… Les calories se calculent toutes seules.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                for (final (index, c) in _composition.indexed)
                  if (IngredientsService.parId(c.idIngredient) case final i?)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        key: Key('composant_$index'),
                        onTap: () => _modifierGrammes(index),
                        leading: Text(i.emoji, style: const TextStyle(fontSize: 26)),
                        title: Text(i.nom),
                        subtitle: Text(
                          '${c.grammes} g · ${CaloriesService.formater(i.kcal(c.grammes))}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Retirer',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _composition.removeAt(index)),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('ajouter_ingredient'),
                  onPressed: _ajouterIngredient,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter un ingrédient'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('enregistrer_plat_compose'),
                  onPressed: _composition.isEmpty ? null : _enregistrer,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    widget.idRepas == null ? 'Noter ce repas' : 'Enregistrer les modifications',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Valeurs moyennes pour 100 g d\'aliment cuit. Astuce : une cuillère à soupe '
                  'd\'huile pèse environ 10 g.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste des ingrédients, avec recherche et regroupés par famille.
class _ChoixIngredient extends StatefulWidget {
  const _ChoixIngredient();

  @override
  State<_ChoixIngredient> createState() => _ChoixIngredientState();
}

class _ChoixIngredientState extends State<_ChoixIngredient> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trouves = IngredientsService.chercher(_recherche);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                key: const Key('recherche_ingredient'),
                onChanged: (t) => setState(() => _recherche = t),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Chercher (riz, poisson, huile…)',
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final g in GroupeIngredient.values)
                    if (trouves.any((i) => i.groupe == g)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${g.emoji} ${g.libelle}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final i in trouves.where((i) => i.groupe == g))
                        ListTile(
                          key: Key('ingredient_${i.id}'),
                          leading: Text(i.emoji, style: const TextStyle(fontSize: 24)),
                          title: Text(i.nom),
                          trailing: Text(
                            '${i.kcal100g} kcal / 100 g',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => Navigator.of(context).pop(i),
                        ),
                    ],
                  if (trouves.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucun ingrédient trouvé.', textAlign: TextAlign.center),
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
