import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/profil.dart';
import '../providers/profil_provider.dart';
import '../services/validation_profil.dart';
import '../widgets/avatar_profil.dart';
import '../widgets/carte_douce.dart';
import '../widgets/carte_objectif_calorique.dart';
import '../widgets/format.dart';
import '../widgets/logo_kira.dart';

/// Accueil du tout premier lancement : plusieurs pages illustrées
/// pour faire connaissance et créer le profil, étape par étape.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _nombrePages = 6;

  final _pages = PageController();
  int _page = 0;

  /// Un formulaire par page de saisie (pages 1 à 3).
  final _formulaires = List.generate(_nombrePages, (_) => GlobalKey<FormState>());

  final _prenom = TextEditingController();
  final _age = TextEditingController();
  final _taille = TextEditingController();
  final _poidsDepart = TextEditingController();
  final _poidsObjectif = TextEditingController();
  Sexe _sexe = Sexe.nonPrecise;
  NiveauActivite _niveau = NiveauActivite.leger;
  bool _objectifTropBas = false;

  /// Photo de profil facultative (base64), choisie sur la page « Faisons connaissance ».
  String? _photo;

  @override
  void dispose() {
    _pages.dispose();
    for (final c in [_prenom, _age, _taille, _poidsDepart, _poidsObjectif]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Profil construit à partir des réponses (utilisé sur la page récapitulatif).
  Profil get _profil => Profil(
    prenom: _prenom.text.trim(),
    age: lireDecimal(_age.text)!.round(),
    tailleCm: lireDecimal(_taille.text)!,
    poidsDepartKg: lireDecimal(_poidsDepart.text)!,
    poidsObjectifKg: lireDecimal(_poidsObjectif.text)!,
    niveauActivite: _niveau,
    sexe: _sexe,
    photoBase64: _photo,
  );

  void _verifierObjectif() {
    final tropBas = ValidationProfil.objectifTropBas(_taille.text, _poidsObjectif.text);
    if (tropBas != _objectifTropBas) setState(() => _objectifTropBas = tropBas);
  }

  Future<void> _suivant() async {
    FocusScope.of(context).unfocus();
    // On valide la page actuelle avant d'avancer.
    final formulaire = _formulaires[_page].currentState;
    if (formulaire != null && !formulaire.validate()) return;
    if (_page == 3) {
      _verifierObjectif();
      if (_objectifTropBas) return;
    }

    if (_page == _nombrePages - 1) {
      // Dernière page : on enregistre. L'application bascule alors
      // automatiquement vers l'écran principal.
      await context.read<ProfilProvider>().enregistrer(_profil);
      return;
    }
    _allerA(_page + 1);
  }

  void _allerA(int page) {
    setState(() => _page = page);
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final derniere = _page == _nombrePages - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Indicateur de progression (points).
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _Points(nombre: _nombrePages, actif: _page),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    // On avance uniquement avec les boutons (validation).
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _pageBienvenue(theme),
                      _pagePrenom(),
                      _pageCorps(theme),
                      _pageObjectif(theme),
                      _pageActivite(theme),
                      _pageRecap(theme),
                    ],
                  ),
                ),
                // Boutons de navigation.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _page == 0 ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: TextButton.icon(
                          onPressed: _page == 0 ? null : () => _allerA(_page - 1),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Retour'),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('bouton_suivant'),
                        onPressed: _suivant,
                        icon: Icon(derniere ? Icons.favorite_rounded : Icons.arrow_forward_rounded),
                        label: Text(
                          _page == 0
                              ? 'Commencer'
                              : derniere
                              ? 'C\'est parti !'
                              : 'Suivant',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Pages

  Widget _pageBienvenue(ThemeData theme) {
    return _PageOnboarding(
      illustration: const LogoKira(taille: 120),
      titre: 'Bienvenue dans Kira\'s FAT',
      texte: 'Une app pour prendre soin de toi, à ton rythme, sans pression.',
      enfants: const [
        _Atout(emoji: '💧', texte: 'Des petites habitudes qui font du bien'),
        _Atout(emoji: '🌱', texte: 'Une plante qui grandit avec toi'),
        _Atout(emoji: '💗', texte: 'Jamais de culpabilité, que des encouragements'),
      ],
    );
  }

  Widget _pagePrenom() {
    return Form(
      key: _formulaires[1],
      child: _PageOnboarding(
        // Rond à toucher pour ajouter sa photo (facultatif).
        illustration: AvatarProfil(
          key: const Key('avatar_onboarding'),
          photoBase64: _photo,
          prenom: _prenom.text,
          taille: 120,
          badgeAppareilPhoto: true,
          onTap: () async {
            final photo = await choisirPhotoProfil(context);
            if (photo != null) setState(() => _photo = photo);
          },
        ),
        titre: 'Faisons connaissance',
        texte:
            'Touche le rond pour ajouter ta photo (facultatif). '
            'Tes réponses restent sur ton appareil.',
        enfants: [
          TextFormField(
            key: const Key('champ_prenom'),
            controller: _prenom,
            decoration: const InputDecoration(
              labelText: 'Ton prénom',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textCapitalization: TextCapitalization.words,
            validator: ValidationProfil.prenom,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('champ_age'),
            controller: _age,
            decoration: const InputDecoration(
              labelText: 'Ton âge',
              suffixText: 'ans',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: ValidationProfil.age,
          ),
        ],
      ),
    );
  }

  Widget _pageCorps(ThemeData theme) {
    return Form(
      key: _formulaires[2],
      child: _PageOnboarding(
        emoji: '📏',
        titre: 'Un peu sur toi',
        texte: 'Pour calculer des repères adaptés à ton corps.',
        enfants: [
          Text('Sexe (utilisé seulement pour le calcul)', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in Sexe.values)
                ChoiceChip(
                  label: Text(s.libelle),
                  selected: _sexe == s,
                  onSelected: (_) => setState(() => _sexe = s),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('champ_taille'),
            controller: _taille,
            decoration: const InputDecoration(
              labelText: 'Ta taille',
              suffixText: 'cm',
              prefixIcon: Icon(Icons.height_rounded),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: ValidationProfil.taille,
          ),
        ],
      ),
    );
  }

  Widget _pageObjectif(ThemeData theme) {
    return Form(
      key: _formulaires[3],
      child: _PageOnboarding(
        emoji: '🎯',
        titre: 'Ton objectif',
        texte:
            'Pas d\'urgence : perdre 0,25 à 0,5 kg par semaine, '
            'c\'est idéal pour durer.',
        enfants: [
          TextFormField(
            key: const Key('champ_poids_depart'),
            controller: _poidsDepart,
            decoration: const InputDecoration(
              labelText: 'Ton poids actuel',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: ValidationProfil.poids,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('champ_poids_objectif'),
            controller: _poidsObjectif,
            decoration: const InputDecoration(
              labelText: 'Le poids que tu vises',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _verifierObjectif(),
            validator: (t) => ValidationProfil.objectif(t, _poidsDepart.text),
          ),
          if (_objectifTropBas) ...[
            const SizedBox(height: 12),
            CarteImcTropBas(tailleCm: lireDecimal(_taille.text)!)
                .animate()
                .fadeIn()
                .shake(hz: 2, offset: const Offset(2, 0)),
          ],
        ],
      ),
    );
  }

  Widget _pageActivite(ThemeData theme) {
    const emojis = ['🛋️', '🚶', '🚴', '🏃', '🏋️'];
    return _PageOnboarding(
      emoji: '☀️',
      titre: 'Ton quotidien',
      texte: 'Choisis ce qui te ressemble le plus en ce moment.',
      enfants: [
        for (final n in NiveauActivite.values)
          _CarteChoix(
            emoji: emojis[n.index],
            titre: n.libelle,
            sousTitre: n.description,
            choisi: _niveau == n,
            onTap: () => setState(() => _niveau = n),
          ),
      ],
    );
  }

  Widget _pageRecap(ThemeData theme) {
    // Cette page n'est construite qu'une fois les pages précédentes validées.
    if (_page < _nombrePages - 1) return const SizedBox.shrink();
    final profil = _profil;
    return _PageOnboarding(
      emoji: '🎉',
      titre: 'Tout est prêt, ${profil.prenom} !',
      texte:
          'Voici ton premier repère. Tu pourras tout modifier '
          'dans l\'onglet Profil.',
      enfants: [CarteObjectifCalorique(profil: profil)],
    );
  }
}

// ------------------------------------------------------------- Composants

/// Mise en page commune : grande illustration emoji, titre, texte, contenu.
/// Les éléments apparaissent en cascade.
class _PageOnboarding extends StatelessWidget {
  const _PageOnboarding({
    this.emoji = '',
    this.illustration,
    required this.titre,
    required this.texte,
    required this.enfants,
  });

  final String emoji;

  /// Illustration à la place de l'emoji (par exemple le logo).
  final Widget? illustration;
  final String titre;
  final String texte;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      children: [
        Center(
          child:
              (illustration ??
                      Container(
                        width: 120,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 56)),
                      ))
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),
        ),
        const SizedBox(height: 24),
        ...[
              Text(
                titre,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                texte,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              ...enfants,
            ]
            .animate(interval: 70.ms, delay: 150.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOutCubic),
      ],
    );
  }
}

/// Ligne « emoji + texte » de la page de bienvenue.
class _Atout extends StatelessWidget {
  const _Atout({required this.emoji, required this.texte});

  final String emoji;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(texte),
      ),
    );
  }
}

/// Carte sélectionnable (niveau d'activité).
class _CarteChoix extends StatelessWidget {
  const _CarteChoix({
    required this.emoji,
    required this.titre,
    required this.sousTitre,
    required this.choisi,
    required this.onTap,
  });

  final String emoji;
  final String titre;
  final String sousTitre;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: choisi ? 1.02 : 1,
      duration: const Duration(milliseconds: 200),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: choisi ? couleurs.primary : Colors.transparent, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Text(emoji, style: const TextStyle(fontSize: 28)),
          title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(sousTitre),
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: choisi
                ? Icon(
                    Icons.check_circle_rounded,
                    key: const ValueKey(true),
                    color: couleurs.primary,
                  )
                : const SizedBox(key: ValueKey(false), width: 24),
          ),
        ),
      ),
    );
  }
}

/// Points de progression : le point actif s'allonge.
class _Points extends StatelessWidget {
  const _Points({required this.nombre, required this.actif});

  final int nombre;
  final int actif;

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < nombre; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == actif ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= actif ? couleurs.primary : couleurs.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
