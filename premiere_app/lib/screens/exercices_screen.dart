import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/exercice.dart';
import '../providers/habitudes_provider.dart';
import '../services/calories_service.dart';
import '../services/equilibre_service.dart';
import '../services/exercices_service.dart';
import '../services/habitudes_service.dart';
import '../widgets/energie.dart';
import '../widgets/figure_exercice.dart';
import 'seance_screen.dart';

/// Bouger : les séances guidées et les exercices n'apparaissent que lorsque
/// les calories du jour dépassent l'objectif, avec ce qu'il faut brûler
/// pour retrouver l'équilibre. Sans profil, tout reste affiché.
class ExercicesScreen extends StatelessWidget {
  const ExercicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (:connu, :equilibre) = equilibreDu(context, DateTime.now());
    final seancesVisibles = !connu || (equilibre != null && !equilibre.repos);

    return Scaffold(
      appBar: AppBar(title: const Text('Bouger')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children:
                  [
                        // ----- Dans l'objectif : pas de séance à faire -----
                        if (connu && equilibre == null)
                          Card(
                            key: const Key('carte_dans_objectif'),
                            color: theme.colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                '🌸 Tu es dans ton objectif calorique aujourd\'hui, bravo ! '
                                'Les séances apparaîtront ici si tu le dépasses.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),

                        // ----- Au-dessus de l'objectif : retrouver l'équilibre -----
                        if (equilibre != null) const CarteEquilibre(),

                        if (seancesVisibles) ...[
                          const SizedBox(height: 8),
                          // ----- Séances guidées -----
                          Text(
                            'Séances guidées',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          for (final s in ExercicesService.seances)
                            _CarteSeance(seance: s, cle: Key('seance_${s.id}')),
                          const SizedBox(height: 16),

                          // ----- Exercices -----
                          Text(
                            'Exercices',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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
                              for (final e in ExercicesService.exercices)
                                _CarteExercice(exercice: e),
                            ],
                          ),
                        ],
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

/// « Retrouver l'équilibre » : affichée seulement au-dessus de l'objectif du jour.
/// Chaque idée se note d'une touche une fois faite.
class CarteEquilibre extends StatelessWidget {
  const CarteEquilibre({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final (connu: _, :equilibre) = equilibreDu(context, DateTime.now());
    if (equilibre == null) return const SizedBox.shrink();
    final habitudes = context.read<HabitudesProvider>();

    return Card(
      key: const Key('carte_equilibre'),
      color: couleurs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equilibre.repos ? '🌙 Place au repos' : '⚖️ Retrouver l\'équilibre',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: couleurs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              EquilibreService.message(equilibre),
              key: const Key('message_equilibre'),
              style: TextStyle(color: couleurs.onPrimaryContainer),
            ),
            for (final idee in equilibre.idees)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text(idee.type.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${idee.type.libelle} '
                        '${HabitudesService.formaterMinutes(idee.minutes)} · '
                        '${CaloriesService.formater(idee.kcal)}',
                        key: Key('idee_equilibre_${idee.type.name}'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: couleurs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: Key('fait_${idee.type.name}'),
                      onPressed: () async {
                        await habitudes.ajouterActivite(
                          date: DateTime.now(),
                          type: idee.type,
                          dureeMinutes: idee.minutes,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${idee.type.emoji} Bravo, c\'est noté !')),
                        );
                      },
                      child: const Text('C\'est fait'),
                    ),
                  ],
                ),
              ),
            if (equilibre.seance case final seance?) ...[
              const SizedBox(height: 12),
              Text(
                'Ou une séance guidée, selon ton énergie :',
                style: TextStyle(color: couleurs.onPrimaryContainer),
              ),
              const SizedBox(height: 6),
              _CarteSeance(seance: seance, cle: const Key('seance_proposee')),
            ],
          ],
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
