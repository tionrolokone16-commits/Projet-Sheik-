import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/activite.dart';
import '../models/exercice.dart';
import '../providers/habitudes_provider.dart';
import '../providers/recompenses_provider.dart';
import '../services/exercices_service.dart';
import '../widgets/figure_exercice.dart';

/// Type d'une phase de la séance.
enum _TypePhase { pret, effort, repos }

class _Phase {
  const _Phase(this.type, this.exercice, this.secondes);
  final _TypePhase type;

  /// Exercice en cours (effort) ou à venir (prêt, repos).
  final Exercice exercice;
  final int secondes;
}

/// Séance guidée : chaque exercice avec sa figurine animée et un minuteur,
/// des temps de repos, et une célébration à la fin.
class SeanceScreen extends StatefulWidget {
  const SeanceScreen({super.key, required this.seance});

  final Seance seance;

  /// Durée de la phase « Prépare-toi ».
  static const secondesPreparation = 5;

  @override
  State<SeanceScreen> createState() => _SeanceScreenState();
}

class _SeanceScreenState extends State<SeanceScreen> with SingleTickerProviderStateMixin {
  late final List<_Phase> _phases = [
    _Phase(_TypePhase.pret, widget.seance.etapes.first.exercice, SeanceScreen.secondesPreparation),
    for (final (i, etape) in widget.seance.etapes.indexed) ...[
      _Phase(_TypePhase.effort, etape.exercice, etape.secondes),
      if (i < widget.seance.etapes.length - 1 && widget.seance.reposSecondes > 0)
        _Phase(_TypePhase.repos, widget.seance.etapes[i + 1].exercice, widget.seance.reposSecondes),
    ],
  ];

  late final AnimationController _minuteur = AnimationController(vsync: this)
    ..addStatusListener((statut) {
      if (statut == AnimationStatus.completed) _suivante();
    });

  int _index = 0;
  bool _enPause = false;
  bool _terminee = false;

  /// Temps d'effort réellement fait (en secondes), pour l'activité enregistrée.
  double _secondesEffort = 0;

  _Phase get _phase => _phases[_index];

  @override
  void initState() {
    super.initState();
    _demarrerPhase();
  }

  @override
  void dispose() {
    _minuteur.dispose();
    super.dispose();
  }

  void _demarrerPhase() {
    _minuteur
      ..duration = Duration(seconds: _phase.secondes)
      ..forward(from: 0);
  }

  void _suivante() {
    if (_phase.type == _TypePhase.effort) {
      _secondesEffort += _minuteur.value * _phase.secondes;
    }
    if (_index >= _phases.length - 1) {
      _terminer();
      return;
    }
    setState(() {
      _index++;
      _enPause = false;
    });
    _demarrerPhase();
  }

  void _basculerPause() {
    setState(() => _enPause = !_enPause);
    _enPause ? _minuteur.stop() : _minuteur.forward();
  }

  Future<void> _terminer() async {
    _minuteur.stop();
    setState(() => _terminee = true);
    final minutes = (_secondesEffort / 60).round().clamp(1, 999);
    // La séance compte comme moment de mouvement (et pour la plante).
    final etirements = widget.seance.etapes.every((e) =>
        e.exercice == ExercicesService.brasCiel || e.exercice == ExercicesService.cerclesBras);
    final habitudes = context.read<HabitudesProvider>();
    final recompenses = context.read<RecompensesProvider>();
    await habitudes.ajouterActivite(
      date: DateTime.now(),
      type: etirements ? TypeActivite.yoga : TypeActivite.renforcement,
      dureeMinutes: minutes,
      note: 'Séance « ${widget.seance.nom} »',
    );
    await recompenses.celebrerSeance(widget.seance.nom, minutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.seance.emoji} ${widget.seance.nom}'),
        leading: IconButton(
          key: const Key('fermer_seance'),
          tooltip: 'Fermer',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _terminee ? _fin(theme) : _enCours(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _enCours(ThemeData theme) {
    final phase = _phase;
    final effort = phase.type == _TypePhase.effort;
    final titre = switch (phase.type) {
      _TypePhase.pret => 'Prépare-toi',
      _TypePhase.effort => phase.exercice.nom,
      _TypePhase.repos => 'Repos 🌬️',
    };
    final sousTitre = switch (phase.type) {
      _TypePhase.pret => 'On commence par : ${phase.exercice.nom}',
      _TypePhase.effort => phase.exercice.conseil,
      _TypePhase.repos => 'Ensuite : ${phase.exercice.nom}',
    };

    return ListView(
      key: const ValueKey('en_cours'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: _index / _phases.length, minHeight: 8),
        ),
        const SizedBox(height: 20),
        Text(
          titre,
          key: const Key('titre_phase'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(sousTitre, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Center(
          child: AnimatedOpacity(
            opacity: effort ? 1 : 0.45,
            duration: const Duration(milliseconds: 300),
            child: FigureExercice(
              key: ValueKey('figure_$_index'),
              exercice: phase.exercice,
              taille: 200,
              // La figurine bouge pendant l'effort, et s'arrête en pause.
              anime: effort && !_enPause,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Minuteur circulaire.
        Center(
          child: AnimatedBuilder(
            animation: _minuteur,
            builder: (context, _) {
              final restant = (phase.secondes * (1 - _minuteur.value)).ceil();
              return SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1 - _minuteur.value,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.outlineVariant,
                        color: effort ? theme.colorScheme.primary : theme.colorScheme.tertiary,
                      ),
                    ),
                    Text('$restant',
                        key: const Key('secondes_restantes'),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.tonalIcon(
              key: const Key('pause_seance'),
              onPressed: _basculerPause,
              icon: Icon(_enPause ? Icons.play_arrow_rounded : Icons.pause_rounded),
              label: Text(_enPause ? 'Reprendre' : 'Pause'),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              key: const Key('passer_phase'),
              onPressed: _suivante,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Passer'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Écoute ton corps : tu peux ralentir ou faire une pause à tout moment.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _fin(ThemeData theme) {
    final minutes = (_secondesEffort / 60).round().clamp(1, 999);
    return Center(
      key: const ValueKey('fin'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72))
                .animate()
                .scale(begin: const Offset(0.4, 0.4), duration: 700.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text('Bravo ✨',
                key: const Key('fin_seance'),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              '$minutes ${minutes > 1 ? 'minutes' : 'minute'} rien que pour toi. '
              'Elles comptent comme un moment de mouvement pour ta plante 🌸',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('terminer_seance'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Terminer'),
            ),
          ],
        ),
      ),
    );
  }
}
