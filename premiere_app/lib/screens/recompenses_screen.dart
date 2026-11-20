import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/progres.dart';
import '../providers/habitudes_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/recompenses_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/recompenses_service.dart';

/// Défis doux de la semaine, victoires hors balance et collection de badges.
class RecompensesScreen extends StatelessWidget {
  const RecompensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recompenses = context.watch<RecompensesProvider>();
    final habitudes = context.watch<HabitudesProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;
    final profil = context.watch<ProfilProvider>().profil;

    final maintenant = DateTime.now();
    final lundi = RecompensesService.debutSemaine(maintenant);
    final dimanche = DateTime(lundi.year, lundi.month, lundi.day + 6);
    final defis = recompenses.defisDeLaSemaine(maintenant);
    final catalogue = RecompensesService.catalogue(profil);
    final badges = recompenses.progres.badges;

    int progresDe(Defi d) => RecompensesService.progresDefi(
      d,
      lundi: lundi,
      journal: habitudes.journal,
      activites: habitudes.activites,
      progres: recompenses.progres,
      objectifVerres: objectifVerres,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Défis & badges')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children:
                  [
                        // ----------------------------------------------- Défis
                        _Titre(
                          'Mes défis de la semaine',
                          'Du ${DateFormat('d MMMM', 'fr_FR').format(lundi)} '
                              'au ${DateFormat('d MMMM', 'fr_FR').format(dimanche)} · '
                              'jusqu\'à ${RecompensesService.defisMax} défis, à ton rythme',
                        ),
                        if (defis.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Choisis un petit défi qui te fait envie cette '
                                'semaine. Aucun n\'est obligatoire 💗',
                              ),
                            ),
                          ),
                        for (final d in defis)
                          _CarteDefi(
                            defi: d,
                            progres: progresDe(d),
                            onRetirer: () => recompenses.retirerDefi(maintenant, d),
                            onAjuster: (delta) => recompenses.ajusterDefi(maintenant, d, delta),
                          ),
                        if (defis.length < RecompensesService.defisMax)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: OutlinedButton.icon(
                              key: const Key('bouton_choisir_defi'),
                              onPressed: () => _choisirDefi(context, defis),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Choisir un défi'),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // -------------------------------------------- Victoires
                        const _Titre(
                          'Mes victoires hors balance',
                          'Énergie, sommeil, vêtements, humeur… elles comptent toutes.',
                        ),
                        FilledButton.icon(
                          key: const Key('bouton_noter_victoire'),
                          onPressed: () => _noterVictoire(context),
                          icon: const Text('🏆', style: TextStyle(fontSize: 18)),
                          label: const Text('Noter une victoire'),
                        ),
                        const SizedBox(height: 8),
                        for (final v in recompenses.progres.victoires.take(10))
                          Card(
                            child: ListTile(
                              leading: Text(
                                v.categorie.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              title: Text(
                                v.texte?.isNotEmpty == true ? v.texte! : v.categorie.libelle,
                              ),
                              subtitle: Text(DateFormat('EEEE d MMMM', 'fr_FR').format(v.date)),
                              trailing: IconButton(
                                tooltip: 'Supprimer',
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => recompenses.supprimerVictoire(v.id),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // ----------------------------------------------- Badges
                        _Titre(
                          'Ma collection de badges',
                          '${badges.length} sur ${catalogue.length} · les autres sont à découvrir',
                        ),
                        GridView.extent(
                          maxCrossAxisExtent: 130,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.78,
                          children: [
                            for (final b in catalogue) _Badge(info: b, obtenuLe: badges[b.id]),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun badge ne récompense le fait de manger moins : '
                          'ils célèbrent les habitudes qui te font du bien.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ]
                      .animate(interval: 40.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _choisirDefi(BuildContext context, List<Defi> dejaChoisis) async {
    final recompenses = context.read<RecompensesProvider>();
    final choisi = await showModalBottomSheet<Defi>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, defilement) => ListView(
          controller: defilement,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Choisis un défi doux', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final d in Defi.values.where((d) => !dejaChoisis.contains(d)))
              Card(
                child: ListTile(
                  leading: Text(d.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(d.titre, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${d.description}\nBadge : ${d.nomBadge}'),
                  isThreeLine: true,
                  onTap: () => Navigator.of(context).pop(d),
                ),
              ),
          ],
        ),
      ),
    );
    if (choisi != null) await recompenses.choisirDefi(DateTime.now(), choisi);
  }

  Future<void> _noterVictoire(BuildContext context) async {
    final recompenses = context.read<RecompensesProvider>();
    final resultat = await showModalBottomSheet<(CategorieVictoire, String)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _PanneauVictoire(),
    );
    if (resultat != null) await recompenses.ajouterVictoire(resultat.$1, resultat.$2);
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.titre, this.sousTitre);
  final String titre;
  final String sousTitre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(sousTitre, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Un défi choisi, avec sa barre de progression.
class _CarteDefi extends StatelessWidget {
  const _CarteDefi({
    required this.defi,
    required this.progres,
    required this.onRetirer,
    required this.onAjuster,
  });

  final Defi defi;
  final int progres;
  final VoidCallback onRetirer;
  final ValueChanged<int> onAjuster;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reussi = progres >= defi.cible;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(defi.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    defi.titre,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (reussi) const Text('✅', style: TextStyle(fontSize: 20)),
                IconButton(
                  tooltip: 'Retirer ce défi',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onRetirer,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: (progres / defi.cible).clamp(0, 1)),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) =>
                            LinearProgressIndicator(value: v, minHeight: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${progres.clamp(0, defi.cible)} / ${defi.cible}',
                    style: theme.textTheme.titleSmall,
                  ),
                  // Défis notés à la main : boutons − et +.
                  if (defi.manuel) ...[
                    IconButton(
                      tooltip: 'Retirer 1',
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: progres > 0 ? () => onAjuster(-1) : null,
                    ),
                    IconButton(
                      key: Key('plus_${defi.name}'),
                      tooltip: 'Ajouter 1',
                      icon: const Icon(Icons.add_circle_rounded),
                      onPressed: reussi ? null : () => onAjuster(1),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              defi.manuel
                  ? 'Touche + à chaque fois que c\'est fait.'
                  : 'Se remplit tout seul avec ton journal.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Un badge : en couleur s'il est obtenu, en douce silhouette sinon.
class _Badge extends StatelessWidget {
  const _Badge({required this.info, required this.obtenuLe});

  final InfoBadge info;
  final DateTime? obtenuLe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final obtenu = obtenuLe != null;
    return Tooltip(
      message: info.description,
      child: Semantics(
        label: '${info.nom} : ${obtenu ? 'obtenu' : 'à découvrir'}. ${info.description}',
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: obtenu
                    ? LinearGradient(
                        colors: [couleurs.primaryContainer, couleurs.tertiaryContainer],
                      )
                    : null,
                color: obtenu ? null : couleurs.surfaceContainerHigh,
                border: Border.all(
                  color: obtenu ? couleurs.primary : couleurs.outlineVariant,
                  width: 2,
                ),
              ),
              child: obtenu
                  ? Text(info.emoji, style: const TextStyle(fontSize: 32))
                  : Icon(Icons.lock_outline_rounded, color: couleurs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              info.nom,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: obtenu ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (obtenu)
              Text(
                DateFormat('d MMM', 'fr_FR').format(obtenuLe!),
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// Panneau pour noter une victoire hors balance.
class _PanneauVictoire extends StatefulWidget {
  const _PanneauVictoire();

  @override
  State<_PanneauVictoire> createState() => _PanneauVictoireState();
}

class _PanneauVictoireState extends State<_PanneauVictoire> {
  CategorieVictoire _categorie = CategorieVictoire.energie;
  final _texte = TextEditingController();

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Une victoire à fêter ?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in CategorieVictoire.values)
                  ChoiceChip(
                    avatar: Text(c.emoji),
                    label: Text(c.libelle),
                    selected: _categorie == c,
                    onSelected: (_) => setState(() => _categorie = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _texte,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Raconte-la en quelques mots (facultatif)',
                hintText: 'J\'ai monté les escaliers sans m\'essouffler…',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('bouton_valider_victoire'),
                onPressed: () => Navigator.of(context).pop((_categorie, _texte.text)),
                icon: const Text('🎉'),
                label: const Text('Célébrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
