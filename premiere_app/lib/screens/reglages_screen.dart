import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/reglages.dart';
import '../providers/habitudes_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/calculs_service.dart';
import '../services/rappels_service.dart';
import '../services/stockage_service.dart';
import '../widgets/logo_kira.dart';

/// Réglages : affichage du poids, objectif d'eau, thème, effacement des données.
class ReglagesScreen extends StatelessWidget {
  const ReglagesScreen({super.key});

  /// Bornes de l'objectif d'eau, en verres par jour.
  static const verresMin = 4;
  static const verresMax = 15;

  Future<void> _toutEffacer(BuildContext context) async {
    final stockage = context.read<StockageService>();
    // Confirmation dans l'application (les fenêtres du navigateur sont bloquées).
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('🌱', style: TextStyle(fontSize: 40)),
        title: const Text('Tout recommencer ?'),
        content: const Text(
          'Ton profil, tes pesées, ton journal, tes repas, tes badges et ta '
          'plante seront effacés de cet appareil. Cette action ne peut pas '
          'être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder mes données'),
          ),
          FilledButton(
            key: const Key('confirmer_effacement'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;
    await stockage.toutEffacer();
    if (!context.mounted) return;
    // On referme les écrans ouverts puis on repart de zéro (onboarding).
    Navigator.of(context).popUntil((route) => route.isFirst);
    FormeDouceApp.redemarrer(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ReglagesProvider>();
    final r = provider.reglages;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children:
                  [
                        // ----- Affichage -----
                        _Section(
                          titre: 'Affichage',
                          enfants: [
                            SwitchListTile(
                              key: const Key('interrupteur_masquer_poids'),
                              secondary: const Text('🙈', style: TextStyle(fontSize: 24)),
                              title: const Text('Masquer le poids sur l\'accueil'),
                              subtitle: const Text(
                                'Pour te concentrer sur tes habitudes. '
                                'Il reste visible dans l\'onglet Poids.',
                              ),
                              value: r.masquerPoidsAccueil,
                              onChanged: (v) =>
                                  provider.modifier(r.copyWith(masquerPoidsAccueil: v)),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🎨 Thème', style: theme.textTheme.titleSmall),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: SegmentedButton<ThemeChoisi>(
                                      segments: const [
                                        ButtonSegment(
                                          value: ThemeChoisi.clair,
                                          icon: Icon(Icons.light_mode_rounded),
                                          label: Text('Clair'),
                                        ),
                                        ButtonSegment(
                                          value: ThemeChoisi.sombre,
                                          icon: Icon(Icons.dark_mode_rounded),
                                          label: Text('Sombre'),
                                        ),
                                        ButtonSegment(
                                          value: ThemeChoisi.systeme,
                                          icon: Icon(Icons.phone_iphone_rounded),
                                          label: Text('Auto'),
                                        ),
                                      ],
                                      selected: {r.theme},
                                      showSelectedIcon: false,
                                      onSelectionChanged: (s) =>
                                          provider.modifier(r.copyWith(theme: s.first)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '« Auto » suit le réglage de ton appareil.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ----- Habitudes -----
                        _Section(
                          titre: 'Habitudes',
                          enfants: [
                            ListTile(
                              leading: const Text('💧', style: TextStyle(fontSize: 24)),
                              title: const Text('Objectif d\'eau'),
                              subtitle: Text(
                                '${r.objectifVerres} verres par jour '
                                '(environ ${(r.objectifVerres * 0.25).toStringAsFixed(1).replaceAll('.', ',')} L)',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: 'Un verre de moins',
                                    onPressed: r.objectifVerres > verresMin
                                        ? () => provider.modifier(
                                            r.copyWith(objectifVerres: r.objectifVerres - 1),
                                          )
                                        : null,
                                    icon: const Icon(Icons.remove_rounded),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      '${r.objectifVerres}',
                                      key: const Key('valeur_objectif_eau'),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    key: const Key('plus_verre_objectif'),
                                    tooltip: 'Un verre de plus',
                                    onPressed: r.objectifVerres < verresMax
                                        ? () => provider.modifier(
                                            r.copyWith(objectifVerres: r.objectifVerres + 1),
                                          )
                                        : null,
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ----- Cycle (facultatif) -----
                        _Section(
                          titre: 'Mon cycle',
                          enfants: [
                            SwitchListTile(
                              key: const Key('interrupteur_cycle'),
                              secondary: const Text('🩸', style: TextStyle(fontSize: 24)),
                              title: const Text('Suivi de cycle'),
                              subtitle: const Text(
                                'Noter tes jours de règles dans le journal et les voir dans le calendrier. '
                                'Reste uniquement sur ton appareil.',
                              ),
                              value: r.suiviCycle,
                              onChanged: (v) => provider.modifier(r.copyWith(suiviCycle: v)),
                            ),
                          ],
                        ),

                        // ----- Rappels -----
                        _Section(
                          titre: 'Rappels',
                          enfants: [
                            SwitchListTile(
                              key: const Key('interrupteur_rappels'),
                              secondary: const Text('🔔', style: TextStyle(fontSize: 24)),
                              title: const Text('Rappels de repas'),
                              subtitle: const Text(
                                'Une invitation douce sur l\'accueil, aux heures '
                                'de repas, si le repas n\'est pas encore noté. Toujours facultative.',
                              ),
                              value: r.rappelsRepas,
                              onChanged: (v) => provider.modifier(r.copyWith(rappelsRepas: v)),
                            ),
                            if (r.rappelsRepas)
                              for (final (cle, emoji, libelle, minutes, modifier) in [
                                (
                                  'heure_petit_dejeuner',
                                  '🥐',
                                  'Petit-déjeuner',
                                  r.heurePetitDejeuner,
                                  (int m) => r.copyWith(heurePetitDejeuner: m),
                                ),
                                (
                                  'heure_dejeuner',
                                  '🍲',
                                  'Déjeuner',
                                  r.heureDejeuner,
                                  (int m) => r.copyWith(heureDejeuner: m),
                                ),
                                (
                                  'heure_diner',
                                  '🍽️',
                                  'Dîner',
                                  r.heureDiner,
                                  (int m) => r.copyWith(heureDiner: m),
                                ),
                              ])
                                ListTile(
                                  key: Key(cle),
                                  leading: Text(emoji, style: const TextStyle(fontSize: 22)),
                                  title: Text(libelle),
                                  trailing: Text(
                                    RappelsService.formaterHeure(minutes),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  onTap: () async {
                                    final choisie = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: minutes ~/ 60,
                                        minute: minutes % 60,
                                      ),
                                      helpText: 'Heure du rappel : ${libelle.toLowerCase()}',
                                      // Affichage sur 24 heures, comme en France et en Côte d'Ivoire.
                                      builder: (context, enfant) => MediaQuery(
                                        data: MediaQuery.of(context)
                                            .copyWith(alwaysUse24HourFormat: true),
                                        child: enfant!,
                                      ),
                                    );
                                    if (choisie != null) {
                                      await provider.modifier(
                                        modifier(choisie.hour * 60 + choisie.minute),
                                      );
                                    }
                                  },
                                ),
                            SwitchListTile(
                              key: const Key('interrupteur_bilan_soir'),
                              secondary: const Text('🌙', style: TextStyle(fontSize: 24)),
                              title: const Text('Bilan du soir'),
                              subtitle: const Text(
                                'Un bravo pour ce que tu as fait dans la journée, '
                                'sur l\'accueil à partir de l\'heure choisie.',
                              ),
                              value: r.bilanSoir,
                              onChanged: (v) => provider.modifier(r.copyWith(bilanSoir: v)),
                            ),
                            if (r.bilanSoir)
                              ListTile(
                                key: const Key('heure_bilan_soir'),
                                leading: const Text('🕘', style: TextStyle(fontSize: 22)),
                                title: const Text('Heure du bilan'),
                                trailing: Text(
                                  RappelsService.formaterHeure(r.heureBilanSoir),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onTap: () async {
                                  final choisie = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: r.heureBilanSoir ~/ 60,
                                      minute: r.heureBilanSoir % 60,
                                    ),
                                    helpText: 'Heure du bilan du soir',
                                    builder: (context, enfant) => MediaQuery(
                                      data: MediaQuery.of(context)
                                          .copyWith(alwaysUse24HourFormat: true),
                                      child: enfant!,
                                    ),
                                  );
                                  if (choisie != null) {
                                    await provider.modifier(
                                      r.copyWith(
                                        heureBilanSoir: choisie.hour * 60 + choisie.minute,
                                      ),
                                    );
                                  }
                                },
                              ),
                            const ListTile(
                              dense: true,
                              leading: Icon(Icons.info_outline_rounded),
                              title: Text(
                                'Les rappels apparaissent quand tu ouvres l\'appli : '
                                'une appli web ne peut pas envoyer de notification quand elle '
                                'est fermée.',
                              ),
                            ),
                          ],
                        ),

                        // ----- Mes données -----
                        _Section(
                          titre: 'Mes données',
                          enfants: [
                            const ListTile(
                              leading: Text('🔒', style: TextStyle(fontSize: 24)),
                              title: Text('Tout reste sur ton appareil'),
                              subtitle: Text(
                                'Rien n\'est envoyé sur internet. Les données '
                                'sont gardées dans ce navigateur : si tu effaces les données '
                                'du navigateur, elles disparaissent aussi.',
                              ),
                            ),
                            const Divider(height: 1),
                            // Espace utilisé dans le navigateur (environ 5 Mo disponibles).
                            const _EspaceUtilise(),
                            const Divider(height: 1),
                            ListTile(
                              key: const Key('bouton_tout_effacer'),
                              leading: Icon(
                                Icons.restart_alt_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              title: const Text('Tout effacer et recommencer'),
                              onTap: () => _toutEffacer(context),
                            ),
                          ],
                        ),

                        // ----- À propos -----
                        _Section(
                          titre: 'À propos',
                          enfants: [
                            ListTile(
                              leading: const LogoKira(taille: 40),
                              title: const Text('Kira\'s FAT · version 1.0'),
                              subtitle: Text(
                                'Une app pour prendre soin de soi, à son rythme.\n'
                                '${CalculsService.mentionMedicale} En cas de doute, ou si tu '
                                'suis un traitement, parles-en à un professionnel de santé.',
                              ),
                              isThreeLine: true,
                            ),
                          ],
                        ),
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

/// Titre de section + carte regroupant ses réglages.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.enfants});

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Text(
              titre,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(children: enfants),
          ),
        ],
      ),
    );
  }
}

/// Espace utilisé par l'application et bouton pour retirer les photos
/// de repas (les repas, eux, restent notés).
class _EspaceUtilise extends StatelessWidget {
  const _EspaceUtilise();

  Future<void> _retirerPhotos(BuildContext context) async {
    final habitudes = context.read<HabitudesProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('📸', style: TextStyle(fontSize: 36)),
        title: const Text('Retirer les photos de repas ?'),
        content: const Text(
          'Tes repas restent notés (plat, portion, ressentis) : '
          'seules les photos sont retirées, pour libérer de la place.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder'),
          ),
          FilledButton(
            key: const Key('confirmer_retrait_photos'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer les photos'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final nombre = await habitudes.retirerToutesLesPhotos();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nombre == 0
              ? 'Il n\'y avait aucune photo à retirer.'
              : '$nombre ${nombre > 1 ? 'photos retirées' : 'photo retirée'}. '
                    'Tes repas restent notés 🌸',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Se met à jour quand les repas (et leurs photos) changent.
    final photos = context
        .watch<HabitudesProvider>()
        .repasPhotos
        .where((r) => r.photoBase64 != null)
        .length;
    final stockage = context.read<StockageService>();
    final utilise = stockage.espaceUtiliseOctets();
    final part = (utilise / StockageService.placeDisponibleOctets).clamp(0.0, 1.0);
    String enMo(int octets) => (octets / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Espace utilisé : ${enMo(utilise)} Mo sur environ '
                  '${enMo(StockageService.placeDisponibleOctets)} Mo',
                  key: const Key('espace_utilise'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: part, minHeight: 8),
          ),
          const SizedBox(height: 6),
          Text(
            'Les photos de repas prennent le plus de place ($photos '
            '${photos > 1 ? 'photos' : 'photo'}). S\'il en manque, les plus anciennes '
            'sont retirées automatiquement : les repas, eux, restent notés.',
            style: theme.textTheme.bodySmall,
          ),
          if (photos > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('bouton_retirer_photos'),
                onPressed: () => _retirerPhotos(context),
                icon: const Icon(Icons.hide_image_outlined),
                label: const Text('Retirer les photos de repas'),
              ),
            ),
        ],
      ),
    );
  }
}
