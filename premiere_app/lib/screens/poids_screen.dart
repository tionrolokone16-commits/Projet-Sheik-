import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/pesee.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../services/messages_service.dart';
import '../widgets/dialogue_pesee.dart';
import '../widgets/format.dart';
import '../widgets/graphique_poids.dart';
import 'chemin_screen.dart';

/// Écran de suivi du poids : résumé, courbe et historique.
class PoidsScreen extends StatefulWidget {
  const PoidsScreen({super.key});

  @override
  State<PoidsScreen> createState() => _PoidsScreenState();
}

class _PoidsScreenState extends State<PoidsScreen> {
  PeriodeGraphique _periode = PeriodeGraphique.troisMois;

  Future<void> _ajouterPesee() async {
    final poids = context.read<PoidsProvider>();
    final saisie = await afficherDialoguePesee(
      context,
      poidsPropose: poids.derniere?.poidsKg ??
          context.read<ProfilProvider>().profil?.poidsDepartKg,
    );
    if (saisie == null) return;
    await poids.ajouter(saisie.date, saisie.poidsKg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesée enregistrée, merci de prendre ce temps pour toi 🌿')),
    );
  }

  Future<void> _supprimer(Pesee pesee) async {
    final poids = context.read<PoidsProvider>();
    final supprimee = await poids.supprimer(pesee.id);
    if (supprimee == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pesée supprimée'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => poids.restaurer(supprimee),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poids = context.watch<PoidsProvider>();
    final profil = context.watch<ProfilProvider>().profil;
    final theme = Theme.of(context);
    final derniere = poids.derniere;
    final historique = poids.pesees.reversed.toList(); // Plus récente en haut.

    return Scaffold(
      appBar: AppBar(title: const Text('Mon poids')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('bouton_ajouter_pesee'),
        // Étiquette unique : plusieurs onglets ont un bouton flottant.
        heroTag: 'fab_poids',
        onPressed: _ajouterPesee,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une pesée'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              // Marge en bas pour ne pas cacher la liste sous le bouton.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                // ----- Résumé -----
                if (derniere == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucune pesée pour l\'instant. Quand tu le souhaites, '
                        'ajoute ta première pesée avec le bouton en bas 🌱\n\n'
                        'Astuce : se peser le matin, au réveil, donne des '
                        'mesures plus faciles à comparer.',
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dernière pesée', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${formaterDecimal(derniere.poidsKg)} kg',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE d MMMM', 'fr_FR').format(derniere.date),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(MessagesService.variation(
                            poids.avantDerniere == null
                                ? null
                                : derniere.poidsKg - poids.avantDerniere!.poidsKg,
                          )),
                          if (profil != null) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: MessagesService.fractionParcourue(
                                    profil, derniere.poidsKg),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              MessagesService.progression(profil, derniere.poidsKg),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              key: const Key('bouton_chemin_poids'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CheminScreen()),
                              ),
                              icon: const Icon(Icons.route_rounded),
                              label: const Text('Voir mon chemin des paliers'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // ----- Graphique -----
                if (poids.pesees.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Évolution', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          SegmentedButton<PeriodeGraphique>(
                            segments: [
                              for (final p in PeriodeGraphique.values)
                                ButtonSegment(value: p, label: Text(p.libelle)),
                            ],
                            selected: {_periode},
                            showSelectedIcon: false,
                            onSelectionChanged: (s) =>
                                setState(() => _periode = s.first),
                          ),
                          const SizedBox(height: 16),
                          GraphiquePoids(
                            pesees: poids.pesees,
                            periode: _periode,
                            poidsObjectifKg: profil?.poidsObjectifKg,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Trait plein : tes pesées · pointillés : ta tendance '
                            'sur 7 jours, plus fidèle que les variations du quotidien.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // ----- Historique -----
                if (historique.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text('Historique', style: theme.textTheme.titleMedium),
                  ),
                  Card(
                    child: Column(
                      children: [
                        for (final p in historique)
                          ListTile(
                            leading: const Icon(Icons.monitor_weight_outlined),
                            title: Text('${formaterDecimal(p.poidsKg)} kg'),
                            subtitle: Text(
                                DateFormat('EEEE d MMMM y', 'fr_FR').format(p.date)),
                            trailing: IconButton(
                              tooltip: 'Supprimer',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _supprimer(p),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ]
                  .animate(interval: 60.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.05, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}
