import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/jour_habitudes.dart';
import '../models/plat.dart';
import '../models/repas_photo.dart';
import '../providers/habitudes_provider.dart';
import '../providers/plan_provider.dart';
import '../services/assiette_service.dart';
import '../services/plats_service.dart';
import '../widgets/panneau_ressenti_repas.dart';
import 'composer_plat_screen.dart';
import 'repas_photo_screen.dart';

/// Noter un repas en 2 touches : on ouvre cet écran, on touche un plat.
/// Le repas est enregistré tout de suite ; les détails sont facultatifs.
///
/// Choisir un plat ouvre sa composition : les calories viennent des ingrédients et des grammes.
class AjouterRepasScreen extends StatefulWidget {
  const AjouterRepasScreen({super.key, required this.date, this.moment});

  /// Jour auquel rattacher le repas.
  final DateTime date;

  /// Moment du repas présélectionné (par exemple depuis un rappel).
  final Repas? moment;

  @override
  State<AjouterRepasScreen> createState() => _AjouterRepasScreenState();
}

class _AjouterRepasScreenState extends State<AjouterRepasScreen> {
  late Repas _moment = widget.moment ?? AssietteService.repasSelonHeure(DateTime.now());
  PaysPlat? _pays;
  CategoriePlat? _categorie;
  String _recherche = '';

  bool get _aujourdhui => DateUtils.isSameDay(widget.date, DateTime.now());

  /// Heure enregistrée : maintenant pour aujourd'hui, sinon une heure
  /// typique du moment choisi (utile pour le bilan de la semaine).
  DateTime _horodatage(Repas moment) {
    if (_aujourdhui) return DateTime.now();
    final heure = switch (moment) {
      Repas.petitDejeuner => 8,
      Repas.dejeuner => 13,
      Repas.collation => 16,
      Repas.diner => 20,
    };
    return DateTime(widget.date.year, widget.date.month, widget.date.day, heure);
  }

  /// Choisir un plat ouvre « Composer mon plat » : les calories viennent
  /// uniquement des ingrédients et des grammes indiqués.
  Future<void> _noter({
    required String nom,
    required String emoji,
    List<String> ingredients = const [],
    Repas? moment,
  }) async {
    final note = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposerPlatScreen(
          date: widget.date,
          moment: moment ?? _moment,
          nomInitial: nom,
          emojiInitial: emoji,
          ingredientsDuPlat: ingredients,
        ),
      ),
    );
    if (note == true && mounted) Navigator.of(context).pop();
  }

  /// Ajout en une touche (favori, « comme hier ») : on note, on revient,
  /// et les détails restent possibles depuis le petit message.
  Future<void> _noterRapide(RepasPhoto modele) async {
    // Sans ingrédients, on passe par la composition (pas de calories toutes faites).
    if (modele.composition.isEmpty && modele.kcalManuel == null) {
      return _noter(nom: modele.titre, emoji: modele.emojiPlat ?? '🍽️');
    }
    final habitudes = context.read<HabitudesProvider>();
    final messager = ScaffoldMessenger.of(context);
    final navigateur = Navigator.of(context);
    final note = await habitudes.renoterRepas(modele, date: _horodatage(_moment), moment: _moment);
    if (!mounted) return;
    navigateur.pop();
    messager.showSnackBar(
      SnackBar(
        content: Text('${note.emojiPlat ?? '🍽️'} ${note.titre} noté, merci 💗'),
        action: SnackBarAction(
          label: 'Détails',
          onPressed: () => afficherPanneauRessentiRepas(navigateur.context, note.id),
        ),
      ),
    );
  }

  Future<void> _ajouterPlatPerso() async {
    final habitudes = context.read<HabitudesProvider>();
    final resultat = await showDialog<(String, String, CategoriePlat)>(
      context: context,
      builder: (_) => const _DialoguePlatPerso(),
    );
    if (resultat == null) return;
    await habitudes.ajouterPlatPerso(nom: resultat.$1, emoji: resultat.$2, categorie: resultat.$3);
    setState(() {
      _pays = PaysPlat.mesPlats;
      _categorie = null;
    });
  }

  Future<void> _supprimerPlatPerso(Plat plat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retirer « ${plat.nom} » ?'),
        content: const Text('Il disparaîtra de « Mes plats ». Les repas déjà notés restent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<HabitudesProvider>().supprimerPlatPerso(plat.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitudes = context.watch<HabitudesProvider>();
    final plan = context.watch<PlanProvider>().plan;
    final menu = plan?.menuDu(widget.date);
    final petitDej = plan?.petitDejeuner?.groupes.expand((g) => g.elements).join(' · ');
    final commeHier = habitudes.memeRepasVeille(widget.date, _moment);
    final favoris = habitudes.platsFavoris(maintenant: widget.date);

    final tous = [...habitudes.platsPerso, ...PlatsService.catalogue];
    final plats = tous
        .where((p) => _pays == null || p.pays == _pays)
        .where((p) => _categorie == null || p.categorie == _categorie)
        .where((p) => PlatsService.correspond(p, _recherche))
        .toList();
    final paysDisponibles = [
      for (final p in PaysPlat.values)
        if (p != PaysPlat.mesPlats || habitudes.platsPerso.isNotEmpty) p,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Noter un repas')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                // ----- Moment du repas -----
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

                // ----- En une touche : comme hier, puis les favoris -----
                if (commeHier != null)
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: const Key('comme_hier'),
                      leading: Text(
                        commeHier.emojiPlat ?? '🔁',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        'Comme hier : ${commeHier.titre}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Même ${_moment.libelle.toLowerCase()} qu\'hier, en une touche',
                      ),
                      trailing: const Icon(Icons.replay_rounded),
                      onTap: () => _noterRapide(commeHier),
                    ),
                  ),
                if (favoris.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('⭐ Mes favoris', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, f) in favoris.indexed)
                        ActionChip(
                          key: Key('favori_$i'),
                          avatar: Text(f.emojiPlat ?? '🍽️'),
                          label: Text(f.titre),
                          onPressed: () => _noterRapide(f),
                        ),
                    ],
                  ),
                ],
                if (commeHier != null || favoris.isNotEmpty) const SizedBox(height: 16),

                // ----- Selon mon plan -----
                if (menu != null || petitDej != null) ...[
                  Text('📋 Selon mon plan', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  if (petitDej != null)
                    _TuilePlan(
                      cle: const Key('plan_petit_dej'),
                      moment: 'Petit-déjeuner',
                      texte: petitDej,
                      onTap: () => _noter(nom: petitDej, emoji: '📋', moment: Repas.petitDejeuner),
                    ),
                  if (menu != null) ...[
                    _TuilePlan(
                      cle: const Key('plan_midi'),
                      moment: 'Midi',
                      texte: menu.midi,
                      onTap: () => _noter(nom: menu.midi, emoji: '📋', moment: Repas.dejeuner),
                    ),
                    _TuilePlan(
                      cle: const Key('plan_soir'),
                      moment: 'Soir',
                      texte: menu.soir,
                      onTap: () => _noter(nom: menu.soir, emoji: '📋', moment: Repas.diner),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],

                // ----- Photo et plat personnel -----
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('bouton_repas_photo'),
                        onPressed: () async {
                          final note = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => RepasPhotoScreen(date: widget.date)),
                          );
                          // On ne ferme que si un repas a vraiment été noté.
                          if (note == true && context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('bouton_plat_perso'),
                        onPressed: _ajouterPlatPerso,
                        icon: const Icon(Icons.star_outline_rounded),
                        label: const Text('Mon plat'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ----- Composer au gramme près -----
                FilledButton.tonalIcon(
                  key: const Key('bouton_composer_plat'),
                  onPressed: () async {
                    final note = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ComposerPlatScreen(date: widget.date, moment: _moment),
                      ),
                    );
                    if (note == true && context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Text('⚖️', style: TextStyle(fontSize: 18)),
                  label: const Text('Composer mon plat en grammes'),
                ),
                const SizedBox(height: 12),

                // ----- Recherche et filtres -----
                TextField(
                  key: const Key('recherche_plat'),
                  onChanged: (t) => setState(() => _recherche = t),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Chercher un plat (garba, ndolè, jollof…)',
                  ),
                ),
                const SizedBox(height: 10),
                _RangeeFiltres<PaysPlat>(
                  valeurs: paysDisponibles,
                  choisie: _pays,
                  libelle: (p) => '${p.drapeau} ${p.libelle}',
                  onChoisir: (p) => setState(() => _pays = p),
                ),
                const SizedBox(height: 6),
                _RangeeFiltres<CategoriePlat>(
                  valeurs: CategoriePlat.values,
                  choisie: _categorie,
                  libelle: (c) => '${c.emoji} ${c.libelle}',
                  onChoisir: (c) => setState(() => _categorie = c),
                ),
                const SizedBox(height: 12),

                // ----- Plats -----
                if (plats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Aucun plat trouvé. Tu peux l\'ajouter avec « Mon plat » ⭐',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  GridView.extent(
                    maxCrossAxisExtent: 130,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: [
                      for (final p in plats)
                        _TuilePlat(
                          plat: p,
                          onTap: () =>
                              _noter(nom: p.nom, emoji: p.emoji, ingredients: p.ingredients),
                          onLongPress: p.pays == PaysPlat.mesPlats
                              ? () => _supprimerPlatPerso(p)
                              : null,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rangée de filtres qui défile horizontalement, avec « Tous » en premier.
class _RangeeFiltres<T> extends StatelessWidget {
  const _RangeeFiltres({
    required this.valeurs,
    required this.choisie,
    required this.libelle,
    required this.onChoisir,
  });

  final List<T> valeurs;
  final T? choisie;
  final String Function(T) libelle;
  final ValueChanged<T?> onChoisir;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tous'),
              selected: choisie == null,
              showCheckmark: false,
              onSelected: (_) => onChoisir(null),
            ),
          ),
          for (final v in valeurs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(libelle(v)),
                selected: choisie == v,
                showCheckmark: false,
                onSelected: (_) => onChoisir(choisie == v ? null : v),
              ),
            ),
        ],
      ),
    );
  }
}

class _TuilePlat extends StatelessWidget {
  const _TuilePlat({required this.plat, required this.onTap, this.onLongPress});

  final Plat plat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('plat_${plat.id}'),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(plat.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                plat.nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(plat.pays.drapeau, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raccourci « Selon mon plan » : le repas prévu, noté en une touche.
class _TuilePlan extends StatelessWidget {
  const _TuilePlan({
    required this.cle,
    required this.moment,
    required this.texte,
    required this.onTap,
  });

  final Key cle;
  final String moment;
  final String texte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Card(
      color: couleurs.primaryContainer,
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: cle,
        onTap: onTap,
        leading: const Text('📋', style: TextStyle(fontSize: 24)),
        title: Text(moment, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(texte, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.add_circle_rounded, color: couleurs.primary),
      ),
    );
  }
}

/// Ajouter un plat à « Mes plats » : nom, emoji, catégorie.
class _DialoguePlatPerso extends StatefulWidget {
  const _DialoguePlatPerso();

  @override
  State<_DialoguePlatPerso> createState() => _DialoguePlatPersoState();
}

class _DialoguePlatPersoState extends State<_DialoguePlatPerso> {
  static const _emojis = [
    '🍲',
    '🍛',
    '🍚',
    '🥘',
    '🐟',
    '🍗',
    '🥗',
    '🍝',
    '🥣',
    '🍌',
    '🥖',
    '🍰',
    '🥤',
    '☕',
    '🍊',
  ];

  final _nom = TextEditingController();
  String _emoji = _emojis.first;
  CategoriePlat _categorie = CategoriePlat.plat;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter mon plat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('champ_nom_plat'),
              controller: _nom,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nom du plat'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final e in _emojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 20)),
                    selected: _emoji == e,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _emoji = e),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in CategoriePlat.values)
                  ChoiceChip(
                    label: Text('${c.emoji} ${c.libelle}'),
                    selected: _categorie == c,
                    onSelected: (_) => setState(() => _categorie = c),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(
          key: const Key('valider_plat_perso'),
          onPressed: _nom.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((_nom.text.trim(), _emoji, _categorie)),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
