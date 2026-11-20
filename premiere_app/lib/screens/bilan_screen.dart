import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/habitudes_provider.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/recompenses_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/bilan_service.dart';
import '../widgets/graphique_semaine.dart';

/// Écran « Mon bilan » (depuis l'accueil ou le profil).
class BilanScreen extends StatelessWidget {
  const BilanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon bilan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: VueSemaine(lundiInitial: BilanService.semaineParDefaut(DateTime.now())),
          ),
        ),
      ),
    );
  }
}

/// Vue d'une semaine : graphique des habitudes, ce qui s'est bien passé,
/// quelques constats sans jugement, 1 ou 2 idées à choisir, et un résumé
/// à partager avec sa ou son nutritionniste.
///
/// Utilisée par « Mon bilan » et par la vue Semaine du calendrier.
class VueSemaine extends StatefulWidget {
  const VueSemaine({super.key, required this.lundiInitial});

  /// Lundi de la semaine affichée au départ.
  final DateTime lundiInitial;

  @override
  State<VueSemaine> createState() => _VueSemaineState();
}

class _VueSemaineState extends State<VueSemaine> {
  late DateTime _lundi = widget.lundiInitial;

  /// Le partage n'inclut les pesées que si on le demande.
  bool _inclurePesees = false;

  bool get _estSemaineActuelle {
    final n = DateTime.now();
    final lundiActuel = DateTime(n.year, n.month, n.day - (n.weekday - 1));
    return !_lundi.isBefore(lundiActuel);
  }

  void _changerSemaine(int delta) {
    if (delta > 0 && _estSemaineActuelle) return;
    setState(() => _lundi = DateTime(_lundi.year, _lundi.month, _lundi.day + 7 * delta));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitudes = context.watch<HabitudesProvider>();
    final recompenses = context.watch<RecompensesProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;
    final prenom = context.watch<ProfilProvider>().profil?.prenom ?? '';
    final pesees = context.watch<PoidsProvider>().pesees;

    final bilan = BilanService.calculer(
      lundi: _lundi,
      journal: habitudes.journal,
      activites: habitudes.activites,
      repasPhotos: habitudes.repasPhotos,
      progres: recompenses.progres,
      objectifVerres: objectifVerres,
    );
    // Les idées choisies valent pour la semaine suivante.
    final lundiSuivant = DateTime(_lundi.year, _lundi.month, _lundi.day + 7);
    final ideesChoisies = [
      for (final nom in recompenses.ideesDe(lundiSuivant)) ?IdeeSemaine.depuisNom(nom),
    ];
    final texte = BilanService.texteAPartager(
      bilan: bilan,
      prenom: prenom,
      ideesChoisies: ideesChoisies,
      pesees: _inclurePesees ? pesees : const [],
    );
    final format = DateFormat('d MMMM', 'fr_FR');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children:
          [
                // ----- Choix de la semaine -----
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Semaine précédente',
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _changerSemaine(-1),
                    ),
                    Expanded(
                      child: Text(
                        'Du ${format.format(bilan.lundi)} au ${format.format(bilan.dimanche)}',
                        key: const Key('semaine_bilan'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Semaine suivante',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _estSemaineActuelle ? null : () => _changerSemaine(1),
                    ),
                  ],
                ),

                // ----- Mot d'accueil -----
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prenom.isEmpty ? 'Ta semaine 🌸' : 'Ta semaine, $prenom 🌸',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bilan.estVide
                              ? 'Une semaine toute douce. Chaque nouvelle semaine est une '
                                    'page blanche 🌱'
                              : 'Merci d\'avoir pris soin de toi cette semaine. Voici ce '
                                    'que tes notes racontent 💗',
                          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ),

                // ----- Graphique des habitudes -----
                Card(
                  key: const Key('graphique_semaine'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Mes habitudes jour par jour',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GraphiqueSemaine(habitudesParJour: bilan.habitudesParJour),
                      ],
                    ),
                  ),
                ),

                // ----- Ce qui s'est bien passé -----
                if (!bilan.estVide)
                  _CarteLignes(
                    cle: const Key('bilan_reussites'),
                    titre: 'Ce qui s\'est bien passé',
                    lignes: bilan.reussites,
                  ),

                // ----- Constats -----
                _CarteLignes(
                  cle: const Key('bilan_constats'),
                  titre: 'Ce que j\'observe',
                  intro: bilan.constats.isEmpty
                      ? 'Pas assez de notes pour observer des tendances cette semaine, '
                            'et c\'est très bien comme ça.'
                      : 'De simples constats, sans jugement :',
                  lignes: bilan.constats,
                ),

                // ----- Idées pour la semaine suivante -----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes idées pour la semaine prochaine',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choisis-en 1 ou 2, si tu en as envie. Elles s\'afficheront '
                          'sur ton accueil la semaine prochaine.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        for (final idee in bilan.ideesProposees.take(6))
                          CheckboxListTile(
                            key: Key('idee_${idee.name}'),
                            contentPadding: EdgeInsets.zero,
                            value: ideesChoisies.contains(idee),
                            onChanged:
                                !ideesChoisies.contains(idee) &&
                                    ideesChoisies.length >= RecompensesProvider.ideesMax
                                ? null
                                : (_) => recompenses.basculerIdee(lundiSuivant, idee.name),
                            secondary: Text(idee.emoji, style: const TextStyle(fontSize: 24)),
                            title: Text(idee.texte),
                            subtitle: bilan.ideesSuggerees.contains(idee)
                                ? const Text('✨ En lien avec ta semaine')
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),

                // ----- Partage -----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Partager avec mon nutritionniste',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Un résumé de la semaine : habitudes, constats et journal des repas.',
                          style: theme.textTheme.bodySmall,
                        ),
                        SwitchListTile(
                          key: const Key('inclure_pesees'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Inclure mes pesées'),
                          value: _inclurePesees,
                          onChanged: (v) => setState(() => _inclurePesees = v),
                        ),
                        FilledButton.icon(
                          key: const Key('bouton_partager_bilan'),
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(text: texte, subject: 'Mon bilan de la semaine'),
                          ),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Partager'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('bouton_copier_bilan'),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: texte));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Résumé copié 📋 Tu peux le coller dans un message.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copier le texte'),
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Voir le résumé'),
                          shape: const Border(),
                          children: [
                            SelectableText(
                              texte,
                              key: const Key('texte_bilan'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]
              .animate(interval: 60.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.05, curve: Curves.easeOutCubic),
    );
  }
}

/// Carte avec un titre et une liste « emoji + phrase ».
class _CarteLignes extends StatelessWidget {
  const _CarteLignes({required this.cle, required this.titre, required this.lignes, this.intro});

  final Key cle;
  final String titre;
  final String? intro;
  final List<LigneBilan> lignes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: cle,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (intro != null) ...[
              const SizedBox(height: 4),
              Text(intro!, style: theme.textTheme.bodySmall),
            ],
            for (final l in lignes)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.texte, style: theme.textTheme.bodyLarge)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
