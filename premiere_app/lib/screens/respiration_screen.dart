import 'dart:math' as math;

import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/recompenses_provider.dart';

/// « J'ai une fringale » : une minute de respiration guidée
/// (un cercle qui gonfle et dégonfle), puis des suggestions douces.
///
/// Aucune interdiction : si c'est une vraie faim, manger est la bonne réponse.
class RespirationScreen extends StatefulWidget {
  const RespirationScreen({super.key});

  /// Durée totale de l'exercice.
  static const duree = Duration(seconds: 60);

  @override
  State<RespirationScreen> createState() => _RespirationScreenState();
}

class _RespirationScreenState extends State<RespirationScreen>
    with TickerProviderStateMixin {
  /// Un cycle de 10 s : 4 s pour inspirer, 6 s pour expirer.
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  /// Avancement de la minute complète.
  late final AnimationController _minute = AnimationController(
    vsync: this,
    duration: RespirationScreen.duree,
  )
    ..addStatusListener((statut) {
      if (statut == AnimationStatus.completed) {
        // Minute complète : on la compte (badge et défi « pauses respiration »).
        context.read<RecompensesProvider>().noterRespiration();
        _terminer();
      }
    })
    ..forward();

  bool _termine = false;

  static const _partInspiration = 0.4;

  void _terminer() {
    _cycle.stop();
    _minute.stop();
    setState(() => _termine = true);
  }

  @override
  void dispose() {
    _cycle.dispose();
    _minute.dispose();
    super.dispose();
  }

  /// Taille du cercle (0 = petit, 1 = grand) selon le moment du cycle.
  double _gonflement(double t) {
    if (t < _partInspiration) {
      return Curves.easeInOut.transform(t / _partInspiration);
    }
    return 1 - Curves.easeInOut.transform((t - _partInspiration) / (1 - _partInspiration));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Une pause pour toi')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _termine ? const _Suggestions() : _exercice(context),
        ),
      ),
    );
  }

  Widget _exercice(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    return Center(
      key: const ValueKey('exercice'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Avant tout, respirons ensemble une minute.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: Listenable.merge([_cycle, _minute]),
              builder: (context, _) {
                final g = _gonflement(_cycle.value);
                final inspire = _cycle.value < _partInspiration;
                final taille = 130 + 130 * g;
                final restant =
                    (RespirationScreen.duree.inSeconds * (1 - _minute.value)).ceil();
                return Column(
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Center(
                        child: Container(
                          width: taille,
                          height: taille,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              couleurs.primaryContainer,
                              couleurs.primary.withValues(alpha: 0.55 + 0.25 * g),
                            ]),
                            boxShadow: [
                              BoxShadow(
                                color: couleurs.primary.withValues(alpha: 0.25),
                                blurRadius: 30 * g + 10,
                                spreadRadius: 6 * g,
                              ),
                            ],
                          ),
                          child: Text(
                            inspire ? 'Inspire…' : 'Expire…',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: couleurs.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Anneau de progression de la minute.
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _minute.value,
                            strokeWidth: 4,
                            backgroundColor: couleurs.outlineVariant,
                          ),
                          Text('${math.max(restant, 0)}',
                              style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Inspire par le nez en gonflant le ventre,\n'
              'puis expire lentement par la bouche.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('bouton_passer_respiration'),
              onPressed: _terminer,
              child: const Text('Passer aux suggestions'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Suggestions affichées après la respiration.
class _Suggestions extends StatelessWidget {
  const _Suggestions();

  static const _idees = [
    ('💧', 'Un grand verre d\'eau', 'La soif se déguise parfois en faim.'),
    ('🍵', 'Une boisson chaude', 'Une tisane ou un thé, à savourer tranquillement.'),
    ('🍌', 'Un fruit', 'Une banane, une mangue, quelques quartiers d\'orange…'),
    ('🥜', 'Une poignée d\'arachides', 'Nature, pour tenir jusqu\'au prochain repas.'),
    ('🥛', 'Un yaourt nature', 'Avec un peu de fruit, c\'est doux et rassasiant.'),
    ('🚶', 'Quelques pas', '5 minutes dehors ou dans la maison pour changer d\'air.'),
    ('📞', 'Un appel', 'Parler à quelqu\'un qu\'on aime fait souvent du bien.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: const ValueKey('suggestions'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Bravo pour cette pause 🌸',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Si tu as vraiment faim, mange : c\'est ton corps qui parle, et c\'est '
          'très bien. Prends le temps de t\'asseoir et de savourer 💗\n\n'
          'Si c\'était plutôt une envie, voici quelques idées :',
        ),
        const SizedBox(height: 12),
        for (final (emoji, titre, texte) in _idees)
          Card(
            child: ListTile(
              leading: Text(emoji, style: const TextStyle(fontSize: 28)),
              title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(texte),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Retour à l\'accueil'),
        ),
      ]
          .animate(interval: 60.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.08, curve: Curves.easeOutCubic),
    );
  }
}
