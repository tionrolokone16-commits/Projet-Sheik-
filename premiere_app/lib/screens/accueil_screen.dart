import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/encouragements_service.dart';
import '../services/habitudes_service.dart';
import '../services/messages_service.dart';
import '../services/plante_service.dart';
import '../providers/recompenses_provider.dart';
import '../services/recompenses_service.dart';
import '../widgets/avatar_profil.dart';
import '../widgets/plante.dart';
import 'chemin_screen.dart';
import 'mon_plan_screen.dart';
import 'recettes_screen.dart';
import 'reglages_screen.dart';
import 'recompenses_screen.dart';
import 'respiration_screen.dart';

/// Tableau de bord : salutation, mot du jour, plante, eau, activité,
/// progression (masquable) et bouton « J'ai une fringale ».
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key, this.onAllerOnglet});

  /// Pour ouvrir un autre onglet (1 = Poids, 2 = Habitudes).
  final ValueChanged<int>? onAllerOnglet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profil = context.watch<ProfilProvider>().profil;
    final reglages = context.watch<ReglagesProvider>().reglages;
    final habitudes = context.watch<HabitudesProvider>();
    final poids = context.watch<PoidsProvider>();

    final maintenant = DateTime.now();
    final jour = habitudes.jour(maintenant);
    final activitesDuJour = habitudes.activitesDu(maintenant);
    final tenues = HabitudesService.tenues(
      jour,
      activitesDuJour: activitesDuJour,
      objectifVerres: reglages.objectifVerres,
    );
    final gouttes = PlanteService.gouttes(
      journal: habitudes.journal,
      activites: habitudes.activites,
      objectifVerres: reglages.objectifVerres,
    );
    final stade = PlanteService.stade(gouttes);

    final carteEau = _CarteEau(
      verres: jour.verres,
      objectif: reglages.objectifVerres,
      onAjouter: () => habitudes.ajouterVerre(maintenant),
      onOuvrir: () => onAllerOnglet?.call(2),
    );
    final carteActivite = _CarteActivite(
      texte: habitudes.derniereActivite == null
          ? 'Pas encore d\'activité notée. Tout mouvement compte 💗'
          : () {
              final a = habitudes.derniereActivite!;
              return '${a.type.emoji} ${a.type.libelle} · '
                  '${HabitudesService.formaterMinutes(a.dureeMinutes)}\n'
                  '${DateFormat('EEEE d MMMM', 'fr_FR').format(a.date)}';
            }(),
      onOuvrir: () => onAllerOnglet?.call(2),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ----- Salutation (+ accès aux réglages) -----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AvatarProfil(
                        key: const Key('avatar_accueil'),
                        photoBase64: profil?.photoBase64,
                        prenom: profil?.prenom ?? '',
                        taille: 60,
                        onTap: () => onAllerOnglet?.call(3),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              EncouragementsService.salutation(profil?.prenom ?? ''),
                              key: const Key('salutation'),
                              style: theme.textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              toBeginningOfSentenceCase(
                                  DateFormat('EEEE d MMMM', 'fr_FR').format(maintenant)),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('bouton_reglages_accueil'),
                        tooltip: 'Réglages',
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReglagesScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ----- Mot du jour -----
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Le mot du jour',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onPrimaryContainer)),
                              const SizedBox(height: 4),
                              Text(
                                EncouragementsService.messageDuJour(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ----- Mon plan du jour (si un plan est importé) -----
                if (context.watch<PlanProvider>().plan case final plan?)
                  CarteMenuDuJour(
                    key: const Key('accueil_plan_du_jour'),
                    plan: plan,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MonPlanScreen()),
                    ),
                  ),

                // ----- Plante -----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Ma plante',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                            Chip(
                              avatar: const Text('💧'),
                              label: Text('$gouttes ${gouttes > 1 ? 'gouttes' : 'goutte'}'),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Plante(
                          niveau: PlanteService.niveau(gouttes),
                          fleursBonus: PlanteService.fleursBonus(gouttes),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stade.message,
                          key: const Key('stade_plante'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PlanteService.message(gouttes,
                              habitudesAujourdhui: tenues.length),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chaque habitude prise en soin (eau, sommeil, '
                          'mouvement, repas) est une goutte pour ta plante.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                // ----- Eau et activité : côte à côte si la place le permet -----
                LayoutBuilder(
                  builder: (context, contraintes) => contraintes.maxWidth > 520
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: carteEau),
                              const SizedBox(width: 8),
                              Expanded(child: carteActivite),
                            ],
                          ),
                        )
                      : Column(children: [carteEau, carteActivite]),
                ),

                // ----- Progression (masquable dans les réglages) -----
                if (profil != null && !reglages.masquerPoidsAccueil)
                  Card(
                    key: const Key('carte_progression'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mon chemin',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          if (poids.derniere == null) ...[
                            const Text('Quand tu le souhaites, ajoute ta première '
                                'pesée pour suivre ton chemin 🌱'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => onAllerOnglet?.call(1),
                              child: const Text('Aller au suivi du poids'),
                            ),
                          ] else ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: MessagesService.fractionParcourue(
                                    profil, poids.derniere!.poidsKg),
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(MessagesService.progression(
                                profil, poids.derniere!.poidsKg)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              key: const Key('bouton_voir_chemin'),
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

                // ----- Défis & badges -----
                _CarteRecompenses(
                  onOuvrir: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecompensesScreen()),
                  ),
                ),

                // ----- Recettes -----
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    key: const Key('carte_recettes'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecettesScreen()),
                    ),
                    leading: const Text('🍲', style: TextStyle(fontSize: 30)),
                    title: Text('Recettes de chez nous',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Nos plats, en version revisitée'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),

                // ----- Fringale -----
                const SizedBox(height: 4),
                FilledButton.tonalIcon(
                  key: const Key('bouton_fringale'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RespirationScreen()),
                  ),
                  icon: const Text('🍫', style: TextStyle(fontSize: 20)),
                  label: const Text('J\'ai une fringale'),
                ),
              ]
                  .animate(interval: 80.ms)
                  .fadeIn(duration: 450.ms)
                  .slideY(begin: 0.08, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eau du jour, avec un bouton rapide « +1 verre ».
class _CarteEau extends StatelessWidget {
  const _CarteEau({
    required this.verres,
    required this.objectif,
    required this.onAjouter,
    required this.onOuvrir,
  });

  final int verres;
  final int objectif;
  final VoidCallback onAjouter;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💧 Eau du jour',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                '$verres / $objectif verres',
                key: const Key('accueil_verres'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: objectif == 0 ? 0 : (verres / objectif).clamp(0, 1)),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    color: const Color(0xFF4FB3D9),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('accueil_plus_verre'),
                onPressed: onAjouter,
                icon: const Icon(Icons.add_rounded),
                label: const Text('1 verre'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dernière activité notée.
class _CarteActivite extends StatelessWidget {
  const _CarteActivite({required this.texte, required this.onOuvrir});

  final String texte;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🚶 Dernière activité',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(texte, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raccourci vers les défis de la semaine et la collection de badges.
class _CarteRecompenses extends StatelessWidget {
  const _CarteRecompenses({required this.onOuvrir});

  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recompenses = context.watch<RecompensesProvider>();
    final defis = recompenses.defisDeLaSemaine(DateTime.now()).length;
    final badges = recompenses.progres.badges.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('carte_recompenses'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onOuvrir,
        leading: const Text('🏆', style: TextStyle(fontSize: 30)),
        title: Text('Défis & badges',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(defis == 0
            ? 'Choisis un défi doux pour cette semaine · $badges ${badges > 1 ? 'badges' : 'badge'}'
            : '$defis/${RecompensesService.defisMax} défis cette semaine · '
                '$badges ${badges > 1 ? 'badges' : 'badge'}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
