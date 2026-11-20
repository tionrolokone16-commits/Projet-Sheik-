import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/habitudes_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/recompenses_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/bilan_soir_service.dart';
import '../widgets/carte_recommandations.dart';

/// Bilan du soir : un bravo pour ce qui a été fait aujourd'hui.
/// « Ma journée a été compliquée » : du réconfort, puis 1 ou 2 idées
/// à choisir pour demain, si on en a envie.
class BilanSoirScreen extends StatefulWidget {
  const BilanSoirScreen({super.key});

  @override
  State<BilanSoirScreen> createState() => _BilanSoirScreenState();
}

class _BilanSoirScreenState extends State<BilanSoirScreen> {
  final DateTime _aujourdhui = DateTime.now();
  bool _compliquee = false;

  DateTime get _demain => DateTime(_aujourdhui.year, _aujourdhui.month, _aujourdhui.day + 1);

  @override
  void initState() {
    super.initState();
    // Une fois ouvert, le bilan ne revient plus sur l'accueil aujourd'hui.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<RecompensesProvider>().marquerBilanSoirVu(_aujourdhui),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final habitudes = context.watch<HabitudesProvider>();
    final recompenses = context.watch<RecompensesProvider>();
    final objectifVerres = context.watch<ReglagesProvider>().reglages.objectifVerres;
    final prenom = context.watch<ProfilProvider>().profil?.prenom ?? '';
    final bravos = BilanSoirService.bravos(
      jour: habitudes.jour(_aujourdhui),
      activitesDuJour: habitudes.activitesDu(_aujourdhui),
      repasDuJour: habitudes.repasPhotosDu(_aujourdhui),
      objectifVerres: objectifVerres,
    );
    final choisies = recompenses.ideesDuJour(_demain);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon bilan du soir')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                // ----- Bravo -----
                Card(
                  key: const Key('bilan_soir_bravos'),
                  color: couleurs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prenom.isEmpty ? 'Bravo 🌙' : 'Bravo, $prenom 🌙',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: couleurs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          BilanSoirService.introduction(bravos.length),
                          style: TextStyle(color: couleurs.onPrimaryContainer),
                        ),
                        for (final (i, l) in bravos.indexed)
                          Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    Text(l.emoji, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l.texte,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: couleurs.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(delay: (120 * i).ms)
                              .fadeIn(duration: 350.ms)
                              .slideX(begin: 0.05),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                CarteRecommandations(date: _aujourdhui, seulementSiComplete: true),
                const SizedBox(height: 8),
                // ----- Journée compliquée -----
                if (!_compliquee)
                  OutlinedButton.icon(
                    key: const Key('bouton_journee_compliquee'),
                    onPressed: () => setState(() => _compliquee = true),
                    icon: const Text('🫂', style: TextStyle(fontSize: 20)),
                    label: const Text('Ma journée a été compliquée'),
                  )
                else
                  Card(
                    key: const Key('carte_reconfort'),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🫂 Je suis là',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(BilanSoirService.reconfort, style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 16),
                          Text(
                            'Pour demain, choisis 1 ou 2 petites idées si tu en as envie. '
                            'Elles t\'attendront sur l\'accueil.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          for (final idee in IdeeDemain.values)
                            CheckboxListTile(
                              key: Key('idee_demain_${idee.name}'),
                              contentPadding: EdgeInsets.zero,
                              value: choisies.contains(idee.name),
                              onChanged:
                                  !choisies.contains(idee.name) &&
                                      choisies.length >= RecompensesProvider.ideesMax
                                  ? null
                                  : (_) => recompenses.basculerIdeeDuJour(_demain, idee.name),
                              secondary: Text(idee.emoji, style: const TextStyle(fontSize: 24)),
                              title: Text(idee.texte),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('bouton_bonne_nuit'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Bonne nuit 🌙'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
