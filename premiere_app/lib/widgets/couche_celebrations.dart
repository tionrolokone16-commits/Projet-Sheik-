import 'package:confetti/confetti.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/recompenses_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/recompenses_service.dart';
import '../theme.dart';

/// Couche posée au-dessus de toute l'application :
/// 1. elle repère les nouveaux moments à fêter (badge, palier, défi…) ;
/// 2. elle les affiche un par un : pluie de confettis + bannière.
class CoucheCelebrations extends StatefulWidget {
  const CoucheCelebrations({super.key, required this.child});

  final Widget child;

  /// Mettre à `false` dans les tests : les confettis suivent l'horloge réelle
  /// et ne s'arrêteraient jamais dans le temps simulé des tests.
  static bool confettisActives = true;

  @override
  State<CoucheCelebrations> createState() => _CoucheCelebrationsState();
}

class _CoucheCelebrationsState extends State<CoucheCelebrations>
    with SingleTickerProviderStateMixin {
  final _confettis = ConfettiController(duration: const Duration(milliseconds: 900));

  /// Durée d'affichage de la bannière (apparition, pause, disparition).
  late final AnimationController _banniere =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
        ..addStatusListener((statut) {
          if (statut == AnimationStatus.completed) {
            setState(() => _actuelle = null);
          }
        });

  Celebration? _actuelle;
  bool _verificationPrevue = false;

  @override
  void dispose() {
    _confettis.dispose();
    _banniere.dispose();
    super.dispose();
  }

  /// Après l'affichage : cherche les nouveaux événements et lance la suite.
  void _planifier(RecompensesProvider recompenses, List<Evenement> nouveaux, String? prenom) {
    if (_verificationPrevue) return;
    _verificationPrevue = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _verificationPrevue = false;
      if (!mounted) return;
      if (nouveaux.isNotEmpty) await recompenses.celebrer(nouveaux, prenom: prenom);
      if (mounted && _actuelle == null && recompenses.aDesCelebrations) {
        setState(() => _actuelle = recompenses.prendreCelebration());
        if (CoucheCelebrations.confettisActives) _confettis.play();
        _banniere.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recompenses = context.watch<RecompensesProvider>();
    final profilProvider = context.watch<ProfilProvider>();
    final habitudes = context.watch<HabitudesProvider>();
    final poids = context.watch<PoidsProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;

    // Pas de célébration pendant l'onboarding.
    if (profilProvider.estComplet) {
      final nouveaux = recompenses.nouveaux(
        RecompensesService.evenements(
          journal: habitudes.journal,
          activites: habitudes.activites,
          objectifVerres: objectifVerres,
          progres: recompenses.progres,
          profil: profilProvider.profil,
          pesees: poids.pesees,
        ),
      );
      if (nouveaux.isNotEmpty || (_actuelle == null && recompenses.aDesCelebrations)) {
        _planifier(recompenses, nouveaux, profilProvider.profil?.prenom);
      }
    }

    return Stack(
      children: [
        widget.child,
        // Confettis depuis le haut de l'écran.
        if (CoucheCelebrations.confettisActives)
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettis,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 24,
                emissionFrequency: 0.08,
                gravity: 0.25,
                colors: Palette.confettis,
              ),
            ),
          ),
        if (_actuelle != null) _Banniere(celebration: _actuelle!, animation: _banniere),
      ],
    );
  }
}

/// Bannière qui glisse du haut, reste un moment puis repart.
/// Un toucher la fait disparaître plus vite.
class _Banniere extends StatelessWidget {
  const _Banniere({required this.celebration, required this.animation});

  final Celebration celebration;
  final AnimationController animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Entrée sur les 12 premiers %, sortie sur les 12 derniers.
    final entree = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.12, curve: Curves.easeOutBack),
    );
    final sortie = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.88, 1, curve: Curves.easeIn),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, enfant) {
            final visible = entree.value - sortie.value;
            return Opacity(
              opacity: visible.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, -80 * (1 - visible)), child: enfant),
            );
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  key: const Key('banniere_celebration'),
                  color: theme.colorScheme.surfaceContainerLowest,
                  elevation: 10,
                  shadowColor: Palette.framboise.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    // Toucher : on passe directement à la sortie.
                    onTap: () {
                      if (animation.value < 0.88) animation.forward(from: 0.88);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Text(celebration.emoji, style: const TextStyle(fontSize: 30)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  celebration.titre,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(celebration.message, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
