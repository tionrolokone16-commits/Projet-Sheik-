import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/recompenses_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/bilan_service.dart';
import '../services/bilan_soir_service.dart';
import '../services/calories_service.dart';
import '../services/encouragements_service.dart';
import '../services/habitudes_service.dart';
import '../services/messages_service.dart';
import '../services/plante_service.dart';
import '../services/recompenses_service.dart';
import '../widgets/avatar_profil.dart';
import '../widgets/carte_rappel_repas.dart';
import '../widgets/energie.dart';
import '../widgets/plante.dart';
import 'ajouter_repas_screen.dart';
import 'bilan_screen.dart';
import 'bilan_soir_screen.dart';
import 'calendrier_onglet_screen.dart';
import 'chemin_screen.dart';
import 'exercices_screen.dart';
import 'mon_plan_screen.dart';
import 'recettes_screen.dart';
import 'recompenses_screen.dart';
import 'reglages_screen.dart';
import 'respiration_screen.dart';

/// Tableau de bord, organisé du plus utile au moins urgent :
/// 1. salutation et mot du jour ;
/// 2. actions rapides : noter un repas, +1 verre, fringale ;
/// 3. ce qui concerne aujourd'hui (rappel, plan, bilan, idées) s'il y a lieu ;
/// 4. la plante et le chemin (masquable) ;
/// 5. « Explorer » : bouger, défis & badges, recettes.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key, this.onAllerOnglet});

  /// Pour ouvrir un autre onglet (1 = Poids, 2 = Habitudes, 3 = Calendrier, 4 = Profil).
  final ValueChanged<int>? onAllerOnglet;

  void _ouvrir(BuildContext context, Widget ecran) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profil = context.watch<ProfilProvider>().profil;
    final reglages = context.watch<ReglagesProvider>().reglages;
    final habitudes = context.watch<HabitudesProvider>();
    final recompenses = context.watch<RecompensesProvider>();
    final poids = context.watch<PoidsProvider>();
    final plan = context.watch<PlanProvider>().plan;

    final maintenant = DateTime.now();
    final jour = habitudes.jour(maintenant);
    final tenues = HabitudesService.tenues(
      jour,
      activitesDuJour: habitudes.activitesDu(maintenant),
      objectifVerres: reglages.objectifVerres,
    );
    final gouttes = PlanteService.gouttes(
      journal: habitudes.journal,
      activites: habitudes.activites,
      objectifVerres: reglages.objectifVerres,
    );
    final stade = PlanteService.stade(gouttes);
    final idees = recompenses.ideesDe(RecompensesService.debutSemaine(maintenant));
    final ideesDuJour = [
      for (final nom in recompenses.ideesDuJour(maintenant)) ?IdeeDemain.depuisNom(nom),
    ];
    final objectif = objectifActuel(context);
    final consomme = habitudes.kcalConsommees(maintenant);
    final derniere = habitudes.derniereActivite;
    final badges = recompenses.progres.badges.length;
    final defis = recompenses.defisDeLaSemaine(maintenant).length;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children:
                  [
                        // ----- 1. Salutation et mot du jour -----
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              AvatarProfil(
                                key: const Key('avatar_accueil'),
                                photoBase64: profil?.photoBase64,
                                prenom: profil?.prenom ?? '',
                                taille: 60,
                                onTap: () => onAllerOnglet?.call(4),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      EncouragementsService.salutation(profil?.prenom ?? ''),
                                      key: const Key('salutation'),
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      toBeginningOfSentenceCase(
                                        DateFormat('EEEE d MMMM', 'fr_FR').format(maintenant),
                                      ),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const Key('bouton_reglages_accueil'),
                                tooltip: 'Réglages',
                                icon: const Icon(Icons.settings_rounded),
                                onPressed: () => _ouvrir(context, const ReglagesScreen()),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
                          child: Text(
                            '✨ ${EncouragementsService.messageDuJour()}',
                            key: const Key('mot_du_jour'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                        // ----- 2. Actions rapides -----
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _TuileAction(
                                cle: const Key('accueil_noter_repas'),
                                emoji: '🍽️',
                                titre: 'Noter un repas',
                                principale: true,
                                onTap: () =>
                                    _ouvrir(context, AjouterRepasScreen(date: DateTime.now())),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _TuileAction(
                                cle: const Key('accueil_plus_verre'),
                                emoji: '💧',
                                titre: '+1 verre',
                                sousTitre: '${jour.verres} / ${reglages.objectifVerres} verres',
                                cleSousTitre: const Key('accueil_verres'),
                                onTap: () => habitudes.ajouterVerre(DateTime.now()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: _TuileAction(
                                cle: const Key('bouton_fringale'),
                                emoji: '🍫',
                                titre: 'Fringale',
                                sousTitre: 'Une pause',
                                onTap: () {
                                  // On note le moment (pour les constats du bilan), sans commentaire.
                                  context.read<RecompensesProvider>().noterFringale();
                                  _ouvrir(context, const RespirationScreen());
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ----- 3. Aujourd'hui (seulement s'il y a lieu) -----
                        // ----- Objectif calorique du jour -----
                        if (objectif != null)
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: const Key('accueil_objectif_kcal'),
                              onTap: () => _ouvrir(context, JourScreen(date: maintenant)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎯 Mon objectif du jour',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${CaloriesService.formater(consomme)} '
                                      'sur ${CaloriesService.formater(objectif.kcalParJour)}',
                                      key: const Key('accueil_kcal_consomme'),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (consomme / objectif.kcalParJour).clamp(0.0, 1.0),
                                        minHeight: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      texteReste(consomme, objectif.kcalParJour),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const CarteRappelRepas(),
                        if (BilanSoirService.aAfficher(
                          maintenant: maintenant,
                          reglages: reglages,
                          dejaVu: recompenses.bilanSoirVu(maintenant),
                        ))
                          Card(
                            color: theme.colorScheme.primaryContainer,
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              key: const Key('carte_bilan_soir'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              onTap: () => _ouvrir(context, const BilanSoirScreen()),
                              leading: const Text('🌙', style: TextStyle(fontSize: 30)),
                              title: Text(
                                'Ton bilan du soir',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              subtitle: Text(
                                'Un bravo pour ta journée, en une minute',
                                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        if (ideesDuJour.isNotEmpty)
                          Card(
                            key: const Key('carte_idees_du_jour'),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🌱 Mes idées pour aujourd\'hui',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  for (final idee in ideesDuJour)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text('${idee.emoji}  ${idee.texte}'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (plan != null)
                          CarteMenuDuJour(
                            key: const Key('accueil_plan_du_jour'),
                            plan: plan,
                            onTap: () => _ouvrir(context, const MonPlanScreen()),
                          ),
                        if (maintenant.weekday == DateTime.sunday ||
                            maintenant.weekday == DateTime.monday)
                          Card(
                            color: theme.colorScheme.primaryContainer,
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              key: const Key('carte_bilan'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              onTap: () => _ouvrir(context, const BilanScreen()),
                              leading: const Text('📊', style: TextStyle(fontSize: 30)),
                              title: Text(
                                'Ton bilan de la semaine est prêt',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              subtitle: Text(
                                'Ce qui s\'est bien passé, et tes idées pour la suite',
                                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                            ),
                          ),
                        if (idees.isNotEmpty)
                          Card(
                            key: const Key('carte_idees_semaine'),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '✨ Mes idées de la semaine',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  for (final nom in idees)
                                    if (IdeeSemaine.depuisNom(nom) case final idee?)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text('${idee.emoji}  ${idee.texte}'),
                                      ),
                                ],
                              ),
                            ),
                          ),

                        // ----- 4. Ma plante -----
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Ma plante',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  PlanteService.message(
                                    gouttes,
                                    habitudesAujourdhui: tenues.length,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ----- Mon chemin (masquable dans les réglages) -----
                        if (profil != null && !reglages.masquerPoidsAccueil)
                          Card(
                            key: const Key('carte_progression'),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => poids.derniere == null
                                  ? onAllerOnglet?.call(1)
                                  : _ouvrir(context, const CheminScreen()),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Mon chemin',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (poids.derniere == null)
                                      const Text(
                                        'Quand tu le souhaites, ajoute ta première '
                                        'pesée pour suivre ton chemin 🌱',
                                      )
                                    else ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: MessagesService.fractionParcourue(
                                            profil,
                                            poids.derniere!.poidsKg,
                                          ),
                                          minHeight: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        MessagesService.progression(
                                          profil,
                                          poids.derniere!.poidsKg,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // ----- 5. Explorer -----
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                          child: Text(
                            'Explorer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _TuileAction(
                                cle: const Key('carte_exercices'),
                                emoji: '💃🏾',
                                titre: 'Bouger',
                                sousTitre: derniere == null
                                    ? 'Séances guidées'
                                    : 'Dernière : ${derniere.type.emoji} '
                                          '${HabitudesService.formaterMinutes(derniere.dureeMinutes)}',
                                onTap: () => _ouvrir(context, const ExercicesScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TuileAction(
                                cle: const Key('carte_recompenses'),
                                emoji: '🏆',
                                titre: 'Défis',
                                sousTitre: defis > 0
                                    ? '$defis ${defis > 1 ? 'défis' : 'défi'} en cours'
                                    : '$badges ${badges > 1 ? 'badges' : 'badge'}',
                                onTap: () => _ouvrir(context, const RecompensesScreen()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TuileAction(
                                cle: const Key('carte_recettes'),
                                emoji: '🍲',
                                titre: 'Recettes',
                                sousTitre: 'De chez nous',
                                onTap: () => _ouvrir(context, const RecettesScreen()),
                              ),
                            ),
                          ],
                        ),
                      ]
                      .animate(interval: 60.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.06, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile d'action compacte : emoji, titre, petit sous-titre facultatif.
/// La tuile « principale » est en couleur pleine pour attirer l'œil.
class _TuileAction extends StatelessWidget {
  const _TuileAction({
    required this.cle,
    required this.emoji,
    required this.titre,
    required this.onTap,
    this.sousTitre,
    this.cleSousTitre,
    this.principale = false,
  });

  final Key cle;
  final String emoji;
  final String titre;
  final String? sousTitre;
  final Key? cleSousTitre;
  final VoidCallback onTap;
  final bool principale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final couleurTexte = principale ? couleurs.onPrimary : couleurs.onSurface;
    return Semantics(
      button: true,
      label: sousTitre == null ? titre : '$titre, $sousTitre',
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: principale ? couleurs.primary : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: cle,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 6),
                  // Le texte rétrécit un peu si la place manque (petit téléphone).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      titre,
                      maxLines: 1,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: couleurTexte,
                      ),
                    ),
                  ),
                  if (sousTitre != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        sousTitre!,
                        key: cleSousTitre,
                        maxLines: 1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: principale ? couleurs.onPrimary : couleurs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
