import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/exercice.dart';
import '../models/jour_habitudes.dart';
import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/exercices_service.dart';
import '../services/journal_service.dart';
import '../widgets/figure_exercice.dart';
import '../widgets/selecteur_ressenti.dart';
import 'seance_screen.dart';

/// Bouger pour le plaisir : une séance proposée selon l'humeur du jour,
/// des séances guidées et une bibliothèque d'exercices illustrés.
class ExercicesScreen extends StatelessWidget {
  const ExercicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bouger pour le plaisir')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children:
                  [
                        Text(
                          'À ton rythme, quand tu en as envie 💃🏾',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),

                        // ----- Pour toi aujourd'hui -----
                        CartePropositionSeance(date: DateTime.now()),
                        const SizedBox(height: 8),
                        const _CartePlanning(),
                        const SizedBox(height: 8),

                        // ----- Séances guidées -----
                        Text(
                          'Séances guidées',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        for (final s in ExercicesService.seances)
                          _CarteSeance(seance: s, cle: Key('seance_${s.id}')),
                        const SizedBox(height: 16),

                        // ----- Exercices -----
                        Text(
                          'Exercices',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        GridView.extent(
                          maxCrossAxisExtent: 200,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.82,
                          children: [
                            for (final e in ExercicesService.exercices) _CarteExercice(exercice: e),
                          ],
                        ),
                      ]
                      .animate(interval: 50.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Pour toi aujourd'hui » : une séance proposée selon le planning,
/// l'énergie, le stress et l'humeur du jour. Jamais selon les repas.
class CartePropositionSeance extends StatelessWidget {
  const CartePropositionSeance({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = theme.colorScheme.onPrimaryContainer;
    final habitudes = context.watch<HabitudesProvider>();
    final joursSeance = context.watch<ReglagesProvider>().reglages.joursSeance;
    final jour = habitudes.jour(date);
    final proposition = ExercicesService.proposerDuJour(
      date: date,
      joursSeance: joursSeance,
      energie: jour.ressentis[Ressenti.energie],
      stress: jour.ressentis[Ressenti.stress],
      humeur: JournalService.humeur(jour),
      dejaBouge: jour.seanceFaite || habitudes.activitesDu(date).isNotEmpty,
    );

    return Card(
      key: const Key('carte_proposition'),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pour toi aujourd\'hui',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: couleur,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              proposition.raison,
              key: const Key('raison_proposition'),
              style: TextStyle(color: couleur),
            ),
            const SizedBox(height: 8),
            if (proposition.seance case final seance?)
              _CarteSeance(seance: seance, cle: const Key('seance_proposee'))
            else
              SelecteurRessenti(
                ressenti: Ressenti.energie,
                valeur: null,
                onChoisir: (v) => habitudes.definirRessenti(date, Ressenti.energie, v),
              ),
          ],
        ),
      ),
    );
  }
}

/// Planning de la semaine : les jours où l'on aimerait faire sa séance.
class _CartePlanning extends StatelessWidget {
  const _CartePlanning();

  static const _initiales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _noms = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reglagesProvider = context.watch<ReglagesProvider>();
    final reglages = reglagesProvider.reglages;
    final jours = reglages.joursSeance;
    return Card(
      key: const Key('carte_planning'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Mes jours de séance',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Choisis les jours qui te conviennent. Ce n\'est qu\'un repère : '
              'tu restes libre de changer d\'avis.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var j = 1; j <= 7; j++)
                  Semantics(
                    label: _noms[j - 1],
                    selected: jours.contains(j),
                    button: true,
                    excludeSemantics: true,
                    child: _PastilleJour(
                      key: Key('jour_seance_$j'),
                      lettre: _initiales[j - 1],
                      choisi: jours.contains(j),
                      onTap: () {
                        final nouveaux = {...jours};
                        if (!nouveaux.remove(j)) nouveaux.add(j);
                        reglagesProvider.modifier(reglages.copyWith(joursSeance: nouveaux));
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              jours.isEmpty
                  ? 'Aucun jour choisi : je te propose une séance selon ton énergie.'
                  : '${jours.length} séance${jours.length > 1 ? 's' : ''} par semaine, '
                        'à ton rythme 🌸',
              key: const Key('resume_planning'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Une lettre du jour, à toucher pour l'ajouter au planning.
class _PastilleJour extends StatelessWidget {
  const _PastilleJour({super.key, required this.lettre, required this.choisi, required this.onTap});

  final String lettre;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Material(
      color: choisi ? couleurs.primary : couleurs.surfaceContainerHigh,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              lettre,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: choisi ? couleurs.onPrimary : couleurs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarteSeance extends StatelessWidget {
  const _CarteSeance({required this.seance, required this.cle});

  final Seance seance;
  final Key cle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: cle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Text(seance.emoji, style: const TextStyle(fontSize: 30)),
        title: Text(seance.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${seance.dureeMinutes} min · ${seance.niveau.emoji} '
          '${seance.niveau.libelle} · ${seance.description}',
        ),
        trailing: const Icon(Icons.play_circle_rounded, size: 32),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => SeanceScreen(seance: seance))),
      ),
    );
  }
}

class _CarteExercice extends StatelessWidget {
  const _CarteExercice({required this.exercice});

  final Exercice exercice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('exercice_${exercice.id}'),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => ExerciceDetailScreen(exercice: exercice))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Immobile dans la liste ; elle s'anime dans la fiche détaillée.
              Expanded(child: FigureExercice(exercice: exercice, anime: false, taille: 120)),
              Text(
                exercice.nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${exercice.niveau.emoji} ${exercice.niveau.libelle} · ${exercice.zone}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fiche d'un exercice : figurine animée, étapes, conseil, version douce.
class ExerciceDetailScreen extends StatelessWidget {
  const ExerciceDetailScreen({super.key, required this.exercice});

  final Exercice exercice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(exercice.nom)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        FigureExercice(exercice: exercice, taille: 220),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text('${exercice.niveau.emoji} ${exercice.niveau.libelle}'),
                            ),
                            Chip(label: Text(exercice.zone)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comment faire',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        for (final (i, etape) in exercice.etapes.indexed)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(etape, style: theme.textTheme.bodyLarge)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Text('💡', style: TextStyle(fontSize: 24)),
                    title: Text(
                      exercice.conseil,
                      style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Text('🌱', style: TextStyle(fontSize: 24)),
                    title: const Text(
                      'Version plus douce',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(exercice.versionDouce),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('essayer_exercice'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SeanceScreen(seance: ExercicesService.essai(exercice)),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Essayer 30 secondes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
