import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/plan_nutrition.dart';
import '../providers/plan_provider.dart';
import '../services/plan_service.dart';

/// « Mon plan » : le plan nutritionnel établi par la diététicienne,
/// importé en collant un texte. Il reste uniquement sur l'appareil.
class MonPlanScreen extends StatefulWidget {
  const MonPlanScreen({super.key});

  @override
  State<MonPlanScreen> createState() => _MonPlanScreenState();
}

class _MonPlanScreenState extends State<MonPlanScreen> {
  /// Vrai pendant le remplacement d'un plan existant.
  bool _remplacement = false;

  Future<void> _supprimer() async {
    final provider = context.read<PlanProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce plan ?'),
        content: const Text('Il sera effacé de cet appareil. Tu pourras le recoller '
            'à tout moment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder'),
          ),
          FilledButton(
            key: const Key('confirmer_retrait_plan'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok == true) await provider.supprimer();
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>().plan;
    final afficherImport = plan == null || _remplacement;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon plan'),
        actions: [
          if (plan != null && !_remplacement)
            PopupMenuButton<String>(
              key: const Key('menu_plan'),
              tooltip: 'Options du plan',
              onSelected: (choix) {
                if (choix == 'remplacer') setState(() => _remplacement = true);
                if (choix == 'retirer') _supprimer();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'remplacer', child: Text('Remplacer par un nouveau plan')),
                PopupMenuItem(value: 'retirer', child: Text('Retirer le plan')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: afficherImport
                ? _Import(
                    onImporte: () => setState(() => _remplacement = false),
                    onAnnuler: plan == null ? null : () => setState(() => _remplacement = false),
                  )
                : _VuePlan(plan: plan),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- Import

class _Import extends StatefulWidget {
  const _Import({required this.onImporte, this.onAnnuler});

  final VoidCallback onImporte;
  final VoidCallback? onAnnuler;

  @override
  State<_Import> createState() => _ImportState();
}

class _ImportState extends State<_Import> {
  final _texte = TextEditingController();
  String? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _coller() async {
    final donnees = await Clipboard.getData(Clipboard.kTextPlain);
    if (donnees?.text != null) setState(() => _texte.text = donnees!.text!);
  }

  Future<void> _importer() async {
    try {
      await context.read<PlanProvider>().importer(_texte.text);
      if (!mounted) return;
      widget.onImporte();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ton plan est en place 📋 Il reste uniquement sur cet appareil.'),
      ));
    } on ErreurPlan catch (e) {
      setState(() => _erreur = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Le plan de ta diététicienne',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    )),
                const SizedBox(height: 8),
                Text(
                  'Colle ci-dessous le texte de ton plan, préparé pour toi. '
                  'Il sera gardé uniquement sur cet appareil 🔒 : il n\'est jamais '
                  'envoyé sur internet.',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('champ_plan'),
          controller: _texte,
          minLines: 6,
          maxLines: 12,
          onChanged: (_) {
            if (_erreur != null) setState(() => _erreur = null);
          },
          decoration: InputDecoration(
            hintText: '[[Kira\'s FAT · plan]]\n# titre: …\n== Conseils\n- …',
            errorText: _erreur,
            errorMaxLines: 4,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _coller,
              icon: const Icon(Icons.content_paste_rounded),
              label: const Text('Coller'),
            ),
            FilledButton.icon(
              key: const Key('bouton_importer_plan'),
              onPressed: _importer,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Importer mon plan'),
            ),
            if (widget.onAnnuler != null)
              TextButton(onPressed: widget.onAnnuler, child: const Text('Annuler')),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- Affichage

class _VuePlan extends StatelessWidget {
  const _VuePlan({required this.plan});

  final PlanNutrition plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aujourdhui = plan.menuDu(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // En-tête.
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.titre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    )),
                if (plan.sousTitre != null) ...[
                  const SizedBox(height: 4),
                  Text(plan.sousTitre!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                ],
                const SizedBox(height: 8),
                Text('🔒 Uniquement sur cet appareil',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
              ],
            ),
          ),
        ),

        // Aujourd'hui.
        if (aujourdhui != null || plan.petitDejeuner != null)
          CarteMenuDuJour(plan: plan, cle: const Key('plan_aujourdhui')),

        for (final section in plan.sections)
          if (section.type == TypeSection.menu)
            _CarteMenuSemaine(menu: section.menu, titre: section.titre)
          else if (section != plan.petitDejeuner)
            _CarteSection(section: section),
      ]
          .animate(interval: 50.ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.05, curve: Curves.easeOutCubic),
    );
  }
}

/// Menu du jour selon le plan (réutilisée sur l'accueil).
class CarteMenuDuJour extends StatelessWidget {
  const CarteMenuDuJour({super.key, required this.plan, this.cle, this.onTap});

  final PlanNutrition plan;
  final Key? cle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jour = plan.menuDu(DateTime.now());
    final petitDej = plan.petitDejeuner;
    Widget ligne(String emoji, String moment, String contenu) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '$moment : ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: contenu),
                ])),
              ),
            ],
          ),
        );

    return Card(
      key: cle,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mon plan · ${DateFormat('EEEE', 'fr_FR').format(DateTime.now())}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right_rounded),
                ],
              ),
              if (petitDej != null)
                ligne('🥐', 'Petit-déjeuner', petitDej.groupes.expand((g) => g.elements).join(' · ')),
              if (jour != null) ...[
                ligne('☀️', 'Midi', jour.midi),
                ligne('🌙', 'Soir', jour.soir),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteMenuSemaine extends StatelessWidget {
  const _CarteMenuSemaine({required this.menu, required this.titre});

  final List<JourMenu> menu;
  final String titre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aujourdhui = DateFormat('EEEE', 'fr_FR').format(DateTime.now()).toLowerCase();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Text('🗓️', style: TextStyle(fontSize: 22)),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
        shape: const Border(),
        children: [
          for (final j in menu)
            Container(
              width: double.infinity,
              color: j.jour.toLowerCase() == aujourdhui ? theme.colorScheme.primaryContainer : null,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(j.jour, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('☀️ ${j.midi}'),
                  Text('🌙 ${j.soir}'),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CarteSection extends StatelessWidget {
  const _CarteSection({required this.section});

  final SectionPlan section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (emoji, ouverte) = switch (section.type) {
      TypeSection.eviter => ('✋', false),
      TypeSection.conseille => ('✅', false),
      _ => (_emojiPour(section.titre), true),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: ouverte,
        leading: Text(emoji, style: const TextStyle(fontSize: 22)),
        title: Text(section.titre, style: const TextStyle(fontWeight: FontWeight.w700)),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in section.groupes) ...[
            if (g.titre != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Text(g.titre!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.secondary,
                    )),
              ),
            for (final e in g.elements)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(e)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _emojiPour(String titre) {
    final t = PlanService.normaliser(titre);
    if (t.contains('conseil') || t.contains('recommand')) return '💡';
    if (t.contains('remarque')) return '📝';
    if (t.contains('contact') || t.contains('dieteti') || t.contains('nutrition')) return '👩🏾‍⚕️';
    return '📌';
  }
}
