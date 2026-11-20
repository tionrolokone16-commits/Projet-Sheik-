import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../providers/habitudes_provider.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/calories_service.dart';
import '../services/depense_service.dart';
import '../services/habitudes_service.dart';
import '../services/stockage_service.dart';
import '../models/repas_photo.dart';
import '../screens/ajouter_repas_screen.dart';
import '../screens/exercices_screen.dart';
import 'assiette.dart';
import 'bouteille_eau.dart';
import 'panneau_ressenti_repas.dart';
import 'dialogue_activite.dart';
import 'energie.dart';
import 'selecteur_ressenti.dart';

/// Toutes les habitudes d'une journée, sous forme de cartes :
/// résumé, eau, humeur, sommeil, repas et activité.
///
/// Réutilisée par le journal pour afficher n'importe quel jour.
class VueJourHabitudes extends StatelessWidget {
  const VueJourHabitudes({super.key, required this.date});

  final DateTime date;

  bool get _estAujourdhui {
    final n = DateTime.now();
    return n.year == date.year && n.month == date.month && n.day == date.day;
  }

  /// Date à enregistrer pour une activité : maintenant si c'est aujourd'hui,
  /// sinon midi du jour affiché.
  DateTime get _dateActivite =>
      _estAujourdhui ? DateTime.now() : DateTime(date.year, date.month, date.day, 12);

  /// Premier repas principal pas encore noté ce jour-là (le dîner sinon).
  static Repas _premierRepasManquant(JourHabitudes jour) =>
      Repas.principaux.firstWhere((r) => !jour.repas.contains(r), orElse: () => Repas.diner);

  Future<void> _noterActivite(BuildContext context) async {
    final habitudes = context.read<HabitudesProvider>();
    final saisie = await afficherDialogueActivite(context);
    if (saisie == null) return;
    await habitudes.ajouterActivite(
      date: _dateActivite,
      type: saisie.type,
      dureeMinutes: saisie.dureeMinutes,
      note: saisie.note,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${saisie.type.emoji} Bravo, ton corps te remercie !')));
  }

  Future<void> _supprimerActivite(BuildContext context, Activite activite) async {
    final habitudes = context.read<HabitudesProvider>();
    final supprimee = await habitudes.supprimerActivite(activite.id);
    if (supprimee == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Activité supprimée'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => habitudes.restaurerActivite(supprimee),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitudes = context.watch<HabitudesProvider>();
    final reglages = context.watch<ReglagesProvider>().reglages;
    final objectifVerres = reglages.objectifVerres;
    final jour = habitudes.jour(date);
    final activitesDuJour = habitudes.activitesDu(date);
    final tenues = HabitudesService.tenues(
      jour,
      activitesDuJour: activitesDuJour,
      objectifVerres: objectifVerres,
    );

    // Séances guidées : seulement au-dessus de l'objectif (ou sans profil).
    final (:connu, :equilibre) = equilibreDu(context, DateTime.now());
    final seancesVisibles = !connu || (equilibre != null && !equilibre.repos);

    // Calories dépensées : il faut le profil (taille, âge…) et un poids.
    final profil = context.watch<ProfilProvider>().profil;
    final poids = profil == null
        ? null
        : context.watch<PoidsProvider>().derniere?.poidsKg ?? profil.poidsDepartKg;
    final depense = profil == null || poids == null
        ? null
        : DepenseService.calculer(
            profil: profil,
            poidsKg: poids,
            jour: jour,
            activitesDuJour: activitesDuJour,
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children:
          [
                _CarteResume(tenues: tenues, aujourdhui: _estAujourdhui),
                if (depense != null)
                  _CarteEnergie(
                    depense: depense,
                    consomme: habitudes.kcalConsommees(date),
                    objectif: objectifActuel(context)?.kcalParJour,
                    aujourdhui: _estAujourdhui,
                  ),
                _CarteEau(
                  verres: jour.verres,
                  objectif: objectifVerres,
                  aujourdhui: _estAujourdhui,
                  onAjouter: () => habitudes.ajouterVerre(date),
                  onRetirer: () => habitudes.retirerVerre(date),
                ),
                _Carte(
                  emoji: '💭',
                  titre: 'Comment te sens-tu ?',
                  enfant: Column(
                    children: [
                      for (final r in Ressenti.values) ...[
                        SelecteurRessenti(
                          ressenti: r,
                          valeur: jour.ressentis[r],
                          onChoisir: (v) => habitudes.definirRessenti(date, r, v),
                        ),
                        const SizedBox(height: 14),
                      ],
                      // La digestion est notée à part : elle ne change pas l'humeur.
                      SelecteurRessenti(
                        key: const Key('selecteur_digestion'),
                        ressenti: Digestion.digestion,
                        valeur: jour.digestion,
                        onChoisir: (v) => habitudes.definirDigestion(date, v),
                      ),
                    ],
                  ),
                ),
                // Suivi de cycle : seulement s'il est activé dans les réglages.
                if (reglages.suiviCycle)
                  _Carte(
                    emoji: '🩸',
                    titre: 'Mon cycle',
                    enfant: FilterChip(
                      key: const Key('puce_regles'),
                      label: const Text('Jour de règles'),
                      selected: jour.regles,
                      onSelected: (_) => habitudes.basculerRegles(date),
                    ),
                  ),
                _CarteSommeil(
                  heures: jour.sommeilHeures,
                  kcalNuit: depense == null || jour.sommeilHeures == null ? null : depense.sommeil,
                  onChanger: (h) => habitudes.definirSommeil(date, h),
                ),
                _Carte(
                  emoji: '🍽️',
                  titre: 'Mes repas',
                  enfant: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in Repas.values)
                            FilterChip(
                              avatar: Text(r.emoji),
                              label: Text(r.libelle),
                              selected: jour.repas.contains(r),
                              showCheckmark: false,
                              onSelected: (_) => habitudes.basculerRepas(date, r),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prendre des repas réguliers aide ton corps à trouver son équilibre.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      // Repas notés avec leur assiette ce jour-là.
                      for (final r in habitudes.repasPhotosDu(date))
                        _LigneRepasPhoto(
                          repas: r,
                          kcal: habitudes.kcalRepas(r),
                          onSupprimer: () => habitudes.supprimerRepasPhoto(r.id),
                        ),
                      if (habitudes.repasPhotosDu(date).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '🔥 ${CaloriesService.formater(habitudes.kcalConsommees(date))} '
                            '${_estAujourdhui ? 'aujourd\'hui' : 'ce jour-là'} (estimation)',
                            key: const Key('total_kcal_jour'),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      if (!_estAujourdhui) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Un repas oublié ? Tu peux encore le noter ici, '
                          'il rejoindra ce jour-là 💗',
                          key: const Key('aide_repas_oublie'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('bouton_noter_repas'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AjouterRepasScreen(
                              date: date,
                              // Pour un jour passé : le premier repas pas encore noté.
                              moment: _estAujourdhui ? null : _premierRepasManquant(jour),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.restaurant_rounded),
                        label: const Text('Noter un repas'),
                      ),
                    ],
                  ),
                ),
                _CartePas(
                  pas: jour.pas,
                  kcal: poids == null || jour.pas == null
                      ? null
                      : DepenseService.kcalPas(jour.pas!, poids),
                  onChanger: (p) => habitudes.definirPas(date, p),
                ),
                _CarteActivite(
                  activitesDuJour: activitesDuJour,
                  kcalDe: poids == null
                      ? null
                      : (a) => DepenseService.kcalActivite(a.type, a.dureeMinutes, poids),
                  seanceFaite: jour.seanceFaite,
                  onBasculerSeance: () => habitudes.basculerSeanceFaite(date),
                  derniere: habitudes.derniereActivite,
                  onAjouter: () => _noterActivite(context),
                  onSupprimer: (a) => _supprimerActivite(context, a),
                  seancesVisibles: seancesVisibles,
                ),
                // Au-dessus de l'objectif calorique : de quoi retrouver l'équilibre.
                if (_estAujourdhui) const CarteEquilibre(),
                _CarteNote(
                  key: ValueKey('note-${cleDuJour(date)}'),
                  note: jour.note ?? '',
                  onChanger: (texte) => habitudes.definirNote(date, texte),
                ),
              ]
              .animate(interval: 60.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
    );
  }
}

// ------------------------------------------------------------- Cartes

/// Carte générique : emoji + titre + contenu.
class _Carte extends StatelessWidget {
  const _Carte({required this.emoji, required this.titre, required this.enfant});

  final String emoji;
  final String titre;
  final Widget enfant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titre,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            enfant,
          ],
        ),
      ),
    );
  }
}

/// Résumé : les 4 habitudes, allumées quand elles sont tenues.
/// Une habitude non tenue reste simplement neutre (jamais rouge).
class _CarteResume extends StatelessWidget {
  const _CarteResume({required this.tenues, required this.aujourdhui});

  final bool aujourdhui;

  final Set<Habitude> tenues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    return Card(
      color: couleurs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              HabitudesService.message(tenues.length, aujourdhui: aujourdhui),
              style: theme.textTheme.titleMedium?.copyWith(
                color: couleurs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Largeur partagée à égalité : ça tient aussi sur petit écran.
                for (final h in Habitude.values)
                  Expanded(
                    child: _PastilleHabitude(habitude: h, tenue: tenues.contains(h)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PastilleHabitude extends StatelessWidget {
  const _PastilleHabitude({required this.habitude, required this.tenue});

  final Habitude habitude;
  final bool tenue;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final pastille = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tenue ? couleurs.surfaceContainerLowest : Colors.transparent,
        border: Border.all(
          color: tenue ? couleurs.primary : couleurs.onPrimaryContainer.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: AnimatedOpacity(
        opacity: tenue ? 1 : 0.5,
        duration: const Duration(milliseconds: 400),
        child: Text(habitude.emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
    return Semantics(
      label: '${habitude.libelle} : ${tenue ? 'pris en soin' : 'pas encore'}',
      child: Column(
        children: [
          // Petit « pop » quand une habitude s'allume.
          tenue
              ? pastille
                    .animate(key: ValueKey('${habitude.name}-tenue'))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
              : pastille,
          const SizedBox(height: 6),
          // Le texte rétrécit un peu si la place manque.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              habitude.libelle,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: couleurs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Énergie de la journée : calories dépensées (détaillées) et consommées.
class _CarteEnergie extends StatelessWidget {
  const _CarteEnergie({
    required this.depense,
    required this.consomme,
    required this.objectif,
    required this.aujourdhui,
  });

  final DepenseJour depense;
  final int consomme;

  /// Objectif calorique du jour (`null` sans profil).
  final int? objectif;
  final bool aujourdhui;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    Widget ligne(String emoji, String libelle, int kcal, {Key? cle}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text(emoji, style: const TextStyle(fontSize: 18))),
          Expanded(child: Text(libelle, style: theme.textTheme.bodyMedium)),
          Text(
            CaloriesService.formater(kcal),
            key: cle,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    return _Carte(
      emoji: '🔥',
      titre: 'Mon énergie ${aujourdhui ? 'du jour' : 'ce jour-là'}',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ChiffreEnergie(
                  libelle: 'Dépensé',
                  kcal: depense.total,
                  cle: const Key('kcal_depense'),
                  couleur: couleurs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChiffreEnergie(
                  libelle: 'Consommé',
                  kcal: consomme,
                  cle: const Key('kcal_consomme'),
                  couleur: couleurs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ligne('😴', 'Ton corps au repos (24 h, nuit comprise)', depense.base),
          ligne('🏠', 'Vie quotidienne', depense.quotidien),
          ligne('🚶', 'Activités et séance', depense.activites, cle: const Key('kcal_activites')),
          ligne('👣', 'Pas', depense.pas),
          if (objectif != null) ...[
            const Divider(height: 20),
            ligne('🎯', 'Mon objectif du jour', objectif!, cle: const Key('kcal_objectif_jour')),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                texteReste(consomme, objectif!),
                key: const Key('kcal_reste'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: couleurs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Estimations, à partir de ton profil et de ta dernière pesée.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ChiffreEnergie extends StatelessWidget {
  const _ChiffreEnergie({
    required this.libelle,
    required this.kcal,
    required this.cle,
    required this.couleur,
  });

  final String libelle;
  final int kcal;
  final Key cle;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(libelle, style: theme.textTheme.labelLarge),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CaloriesService.formater(kcal),
              key: cle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: couleur,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de l'eau, avec la bouteille animée.
class _CarteEau extends StatelessWidget {
  const _CarteEau({
    required this.verres,
    required this.objectif,
    required this.aujourdhui,
    required this.onAjouter,
    required this.onRetirer,
  });

  final int verres;
  final int objectif;
  final bool aujourdhui;
  final VoidCallback onAjouter;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atteint = verres >= objectif;
    return _Carte(
      emoji: '💧',
      titre: 'Mon hydratation',
      enfant: Row(
        children: [
          BouteilleEau(verres: verres, objectif: objectif, onAjouter: onAjouter),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$verres / $objectif',
                  key: const Key('compteur_verres'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  aujourdhui ? 'verres aujourd\'hui' : 'verres ce jour-là',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    atteint
                        ? 'Objectif atteint, ton corps te dit merci 💧✨'
                        : 'Touche la bouteille pour ajouter un verre.',
                    key: ValueKey(atteint),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: verres > 0 ? onRetirer : null,
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Retirer un verre'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte du sommeil : un curseur de 0 à 12 heures.
class _CarteSommeil extends StatefulWidget {
  const _CarteSommeil({required this.heures, required this.kcalNuit, required this.onChanger});

  /// Calories utilisées pendant la nuit (`null` si inconnues).
  final int? kcalNuit;

  final double? heures;
  final ValueChanged<double?> onChanger;

  @override
  State<_CarteSommeil> createState() => _CarteSommeilState();
}

class _CarteSommeilState extends State<_CarteSommeil> {
  /// Valeur pendant que le doigt glisse (enregistrée au relâchement).
  double? _enCours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valeur = _enCours ?? widget.heures;
    return _Carte(
      emoji: '🌙',
      titre: 'Ma nuit',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                valeur == null ? 'Pas encore notée' : HabitudesService.formaterHeures(valeur),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (widget.heures != null)
                TextButton(onPressed: () => widget.onChanger(null), child: const Text('Effacer')),
            ],
          ),
          Slider(
            value: valeur ?? 7,
            min: 0,
            max: 12,
            divisions: 24,
            label: HabitudesService.formaterHeures(valeur ?? 7),
            onChanged: (v) => setState(() => _enCours = v),
            onChangeEnd: (v) {
              setState(() => _enCours = null);
              widget.onChanger(v);
            },
          ),
          Text(HabitudesService.messageSommeil(widget.heures), style: theme.textTheme.bodySmall),
          if (widget.kcalNuit != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '🔥 Pendant ta nuit, ton corps a utilisé ${CaloriesService.formater(widget.kcalNuit!)}',
                key: const Key('kcal_nuit'),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fenêtre de saisie du nombre de pas (elle gère elle-même son champ).
class _DialoguePas extends StatefulWidget {
  const _DialoguePas({required this.initial});

  final int? initial;

  @override
  State<_DialoguePas> createState() => _DialoguePasState();
}

class _DialoguePasState extends State<_DialoguePas> {
  late final _champ = TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  void _valider() {
    final n = int.tryParse(_champ.text);
    if (n != null) Navigator.of(context).pop(n.clamp(0, 100000));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('👣 Mes pas'),
      content: TextField(
        key: const Key('champ_pas'),
        controller: _champ,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: 'Par exemple 6500'),
        onSubmitted: (_) => _valider(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(
          key: const Key('valider_pas'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Carte des pas : le nombre est recopié depuis le téléphone
/// (Safari ne peut pas lire le podomètre).
class _CartePas extends StatelessWidget {
  const _CartePas({required this.pas, required this.kcal, required this.onChanger});

  /// Calories des pas (`null` si inconnues).
  final int? kcal;

  final int? pas;
  final ValueChanged<int?> onChanger;

  Future<void> _saisir(BuildContext context) async {
    final resultat = await showDialog<int>(
      context: context,
      builder: (_) => _DialoguePas(initial: pas),
    );
    if (resultat != null) onChanger(resultat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Carte(
      emoji: '👣',
      titre: 'Mes pas',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                pas == null ? 'Pas encore notés' : HabitudesService.formaterPas(pas!),
                key: const Key('compteur_pas'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (pas != null)
                TextButton(onPressed: () => onChanger(null), child: const Text('Effacer')),
            ],
          ),
          const SizedBox(height: 4),
          Text(HabitudesService.messagePas(pas), style: theme.textTheme.bodySmall),
          if (kcal != null)
            Text(
              '🔥 ${CaloriesService.formater(kcal!)} dépensées en marchant',
              key: const Key('kcal_pas'),
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('bouton_noter_pas'),
            onPressed: () => _saisir(context),
            icon: const Icon(Icons.directions_walk_rounded),
            label: Text(pas == null ? 'Noter mes pas' : 'Modifier'),
          ),
        ],
      ),
    );
  }
}

/// Carte des activités du jour (ou rappel de la dernière activité).
class _CarteActivite extends StatelessWidget {
  const _CarteActivite({
    required this.activitesDuJour,
    required this.seanceFaite,
    required this.onBasculerSeance,
    required this.derniere,
    required this.onAjouter,
    required this.onSupprimer,
    required this.seancesVisibles,
    this.kcalDe,
  });

  /// Les séances guidées ne sont proposées qu'au-dessus de l'objectif du jour.
  final bool seancesVisibles;

  final List<Activite> activitesDuJour;

  /// Calories d'une activité (`null` si le profil manque).
  final int Function(Activite)? kcalDe;
  final bool seanceFaite;
  final VoidCallback onBasculerSeance;
  final Activite? derniere;
  final VoidCallback onAjouter;
  final ValueChanged<Activite> onSupprimer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = activitesDuJour.fold<int>(0, (s, a) => s + a.dureeMinutes);
    return _Carte(
      emoji: '🚶',
      titre: 'Je bouge',
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activitesDuJour.isEmpty)
            Text(
              derniere == null
                  ? 'Une marche, quelques étirements, une danse dans le salon… '
                        'tout compte !'
                  : 'Dernière activité : ${derniere!.type.emoji} '
                        '${derniere!.type.libelle} · '
                        '${HabitudesService.formaterMinutes(derniere!.dureeMinutes)} · '
                        '${DateFormat('EEEE d MMMM', 'fr_FR').format(derniere!.date)}',
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Text(
              '${HabitudesService.formaterMinutes(total)} de mouvement 💪',
              style: theme.textTheme.titleSmall,
            ),
            for (final a in activitesDuJour)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(a.type.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(a.type.libelle),
                subtitle: Text(
                  [
                    HabitudesService.formaterMinutes(a.dureeMinutes),
                    if (kcalDe != null) CaloriesService.formater(kcalDe!(a)),
                    if (a.note != null) a.note!,
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => onSupprimer(a),
                ),
              ),
          ],
          const SizedBox(height: 12),
          // Un seul geste pour dire « c'est fait ».
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              key: const Key('puce_seance_faite'),
              avatar: const Text('✅'),
              label: Text(seanceFaite ? 'Séance faite, bravo !' : 'J\'ai fait ma séance'),
              selected: seanceFaite,
              showCheckmark: false,
              onSelected: (_) => onBasculerSeance(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('bouton_noter_activite'),
            onPressed: onAjouter,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Noter une activité'),
          ),
          if (seancesVisibles) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('bouton_seances'),
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ExercicesScreen())),
              icon: const Icon(Icons.play_circle_rounded),
              label: const Text('Séances guidées'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Petit mot libre du journal. Enregistré automatiquement pendant la saisie.
class _CarteNote extends StatefulWidget {
  const _CarteNote({super.key, required this.note, required this.onChanger});

  final String note;
  final ValueChanged<String> onChanger;

  @override
  State<_CarteNote> createState() => _CarteNoteState();
}

class _CarteNoteState extends State<_CarteNote> {
  late final TextEditingController _texte = TextEditingController(text: widget.note);

  /// Délai avant d'enregistrer : on attend une petite pause dans la frappe.
  Timer? _attente;

  void _surChangement(String texte) {
    _attente?.cancel();
    _attente = Timer(const Duration(milliseconds: 600), () => widget.onChanger(texte));
  }

  @override
  void dispose() {
    // On enregistre ce qui n'a pas encore eu le temps de l'être.
    if (_attente?.isActive ?? false) {
      _attente!.cancel();
      widget.onChanger(_texte.text);
    }
    _texte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Carte(
      emoji: '📝',
      titre: 'Mon petit mot',
      enfant: TextField(
        key: const Key('champ_note_journal'),
        controller: _texte,
        onChanged: _surChangement,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText:
              'Une victoire, un moment doux, une pensée… '
              'Écris ce qui te fait du bien.',
        ),
      ),
    );
  }
}

/// Un repas noté : photo (ou mini-assiette), type de repas et heure.
class _LigneRepasPhoto extends StatelessWidget {
  const _LigneRepasPhoto({required this.repas, required this.kcal, required this.onSupprimer});

  final RepasPhoto repas;
  final int kcal;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final photo = repas.photoBase64;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // Toucher un repas : compléter ou modifier ses détails.
      onTap: () => afficherPanneauRessentiRepas(context, repas.id),
      leading: photo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(photo),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          : Assiette(portions: repas.portions, taille: 48),
      title: Text(
        '${repas.emojiPlat ?? '📸'} ${repas.titre}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          '${repas.repas.emoji} ${repas.repas.libelle}',
          'Portion ${repas.taille.libelle.toLowerCase()}',
          CaloriesService.formater(kcal),
          // Ressentis notés, en emojis.
          for (final e in repas.ressentis.entries) e.key.emojis[e.value - 1],
        ].join(' · '),
      ),
      trailing: IconButton(
        tooltip: 'Supprimer',
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: onSupprimer,
      ),
    );
  }
}
