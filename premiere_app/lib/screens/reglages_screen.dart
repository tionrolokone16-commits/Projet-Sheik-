import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/reglages.dart';
import '../providers/reglages_provider.dart';
import '../services/calculs_service.dart';
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
              children: [
                // ----- Affichage -----
                _Section(
                  titre: 'Affichage',
                  enfants: [
                    SwitchListTile(
                      key: const Key('interrupteur_masquer_poids'),
                      secondary: const Text('🙈', style: TextStyle(fontSize: 24)),
                      title: const Text('Masquer le poids sur l\'accueil'),
                      subtitle: const Text('Pour te concentrer sur tes habitudes. '
                          'Il reste visible dans l\'onglet Poids.'),
                      value: r.masquerPoidsAccueil,
                      onChanged: (v) => provider.modifier(r.copyWith(masquerPoidsAccueil: v)),
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
                          Text('« Auto » suit le réglage de ton appareil.',
                              style: theme.textTheme.bodySmall),
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
                      subtitle: Text('${r.objectifVerres} verres par jour '
                          '(environ ${(r.objectifVerres * 0.25).toStringAsFixed(1).replaceAll('.', ',')} L)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Un verre de moins',
                            onPressed: r.objectifVerres > verresMin
                                ? () => provider.modifier(
                                    r.copyWith(objectifVerres: r.objectifVerres - 1))
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${r.objectifVerres}',
                              key: const Key('valeur_objectif_eau'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton.filledTonal(
                            key: const Key('plus_verre_objectif'),
                            tooltip: 'Un verre de plus',
                            onPressed: r.objectifVerres < verresMax
                                ? () => provider.modifier(
                                    r.copyWith(objectifVerres: r.objectifVerres + 1))
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
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
                      subtitle: Text('Rien n\'est envoyé sur internet. Les données '
                          'sont gardées dans ce navigateur : si tu effaces les données '
                          'du navigateur, elles disparaissent aussi.'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('bouton_tout_effacer'),
                      leading: Icon(Icons.restart_alt_rounded, color: theme.colorScheme.primary),
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
