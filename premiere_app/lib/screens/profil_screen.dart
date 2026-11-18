import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/profil.dart';
import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../services/validation_profil.dart';
import '../widgets/avatar_profil.dart';
import '../widgets/carte_douce.dart';
import '../widgets/carte_objectif_calorique.dart';
import '../widgets/format.dart';
import 'reglages_screen.dart';

/// Écran de modification du profil (le premier remplissage se fait
/// dans l'onboarding).
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formulaire = GlobalKey<FormState>();

  late final TextEditingController _prenom;
  late final TextEditingController _age;
  late final TextEditingController _taille;
  late final TextEditingController _poidsDepart;
  late final TextEditingController _poidsObjectif;
  late NiveauActivite _niveau;
  late Sexe _sexe;

  /// Vrai si le poids objectif saisi correspond à un IMC inférieur à 18,5.
  bool _objectifTropBas = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplissage avec le profil enregistré.
    final p = context.read<ProfilProvider>().profil;
    _prenom = TextEditingController(text: p?.prenom ?? '');
    _age = TextEditingController(text: p == null ? '' : '${p.age}');
    _taille = TextEditingController(text: p == null ? '' : formaterDecimal(p.tailleCm));
    _poidsDepart =
        TextEditingController(text: p == null ? '' : formaterDecimal(p.poidsDepartKg));
    _poidsObjectif =
        TextEditingController(text: p == null ? '' : formaterDecimal(p.poidsObjectifKg));
    _niveau = p?.niveauActivite ?? NiveauActivite.leger;
    _sexe = p?.sexe ?? Sexe.nonPrecise;
  }

  @override
  void dispose() {
    for (final c in [_prenom, _age, _taille, _poidsDepart, _poidsObjectif]) {
      c.dispose();
    }
    super.dispose();
  }

  void _verifierObjectif() {
    final tropBas = ValidationProfil.objectifTropBas(_taille.text, _poidsObjectif.text);
    if (tropBas != _objectifTropBas) setState(() => _objectifTropBas = tropBas);
  }

  /// Choisir, changer ou retirer la photo de profil.
  Future<void> _changerPhoto() async {
    final provider = context.read<ProfilProvider>();
    final profil = provider.profil;
    if (profil == null) return;

    // S'il y a déjà une photo, on propose aussi de la retirer.
    var action = 'choisir';
    if (profil.photoBase64 != null) {
      final choix = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choisir une autre photo'),
                onTap: () => Navigator.of(context).pop('choisir'),
              ),
              ListTile(
                key: const Key('retirer_photo'),
                leading: const Icon(Icons.hide_image_outlined),
                title: const Text('Retirer la photo'),
                onTap: () => Navigator.of(context).pop('retirer'),
              ),
            ],
          ),
        ),
      );
      if (choix == null) return;
      action = choix;
    }

    if (action == 'retirer') {
      await provider.enregistrer(profil.copyWith(retirerPhoto: true));
      return;
    }
    if (!mounted) return;
    final photo = await choisirPhotoProfil(context);
    if (photo == null) return;
    await provider.enregistrer(profil.copyWith(photoBase64: photo));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jolie photo ! Elle reste uniquement sur ton appareil 🌸')),
    );
  }

  Future<void> _enregistrer() async {
    FocusScope.of(context).unfocus();
    _verifierObjectif();
    if (!_formulaire.currentState!.validate() || _objectifTropBas) return;

    final profil = Profil(
      prenom: _prenom.text.trim(),
      age: lireDecimal(_age.text)!.round(),
      tailleCm: lireDecimal(_taille.text)!,
      poidsDepartKg: lireDecimal(_poidsDepart.text)!,
      poidsObjectifKg: lireDecimal(_poidsObjectif.text)!,
      niveauActivite: _niveau,
      sexe: _sexe,
      // On garde la photo de profil déjà choisie.
      photoBase64: context.read<ProfilProvider>().profil?.photoBase64,
    );
    await context.read<ProfilProvider>().enregistrer(profil);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('C\'est noté, ${profil.prenom} 🌸')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profil = context.watch<ProfilProvider>().profil;
    final dernierPoids = context.watch<PoidsProvider>().derniere?.poidsKg;
    final theme = Theme.of(context);
    const espace = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            key: const Key('bouton_reglages_profil'),
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReglagesScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          // Largeur limitée pour rester lisible sur iPad.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formulaire,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // En-tête : photo de profil (touchable pour la changer).
                  if (profil != null)
                    Row(
                      children: [
                        AvatarProfil(
                          key: const Key('avatar_profil'),
                          photoBase64: profil.photoBase64,
                          prenom: profil.prenom,
                          taille: 88,
                          badgeAppareilPhoto: true,
                          onTap: _changerPhoto,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour ${profil.prenom} 🌸',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                profil.photoBase64 == null
                                    ? 'Touche le rond pour ajouter ta photo'
                                    : 'Touche ta photo pour la changer',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('champ_prenom'),
                            controller: _prenom,
                            decoration: const InputDecoration(labelText: 'Prénom'),
                            textCapitalization: TextCapitalization.words,
                            validator: ValidationProfil.prenom,
                          ),
                          espace,
                          TextFormField(
                            key: const Key('champ_age'),
                            controller: _age,
                            decoration: const InputDecoration(
                                labelText: 'Âge', suffixText: 'ans'),
                            keyboardType: TextInputType.number,
                            validator: ValidationProfil.age,
                          ),
                          espace,
                          DropdownButtonFormField<Sexe>(
                            initialValue: _sexe,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Sexe',
                              helperText: 'Utilisé uniquement pour le calcul du métabolisme',
                            ),
                            items: [
                              for (final s in Sexe.values)
                                DropdownMenuItem(value: s, child: Text(s.libelle)),
                            ],
                            onChanged: (s) => setState(() => _sexe = s ?? _sexe),
                          ),
                          espace,
                          TextFormField(
                            key: const Key('champ_taille'),
                            controller: _taille,
                            decoration: const InputDecoration(
                                labelText: 'Taille', suffixText: 'cm'),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: ValidationProfil.taille,
                            onChanged: (_) => _verifierObjectif(),
                          ),
                          espace,
                          TextFormField(
                            key: const Key('champ_poids_depart'),
                            controller: _poidsDepart,
                            decoration: const InputDecoration(
                                labelText: 'Poids de départ', suffixText: 'kg'),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: ValidationProfil.poids,
                          ),
                          espace,
                          TextFormField(
                            key: const Key('champ_poids_objectif'),
                            controller: _poidsObjectif,
                            decoration: const InputDecoration(
                                labelText: 'Poids objectif', suffixText: 'kg'),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _verifierObjectif(),
                            validator: (t) =>
                                ValidationProfil.objectif(t, _poidsDepart.text),
                          ),
                          if (_objectifTropBas) ...[
                            const SizedBox(height: 12),
                            CarteImcTropBas(tailleCm: lireDecimal(_taille.text)!)
                                .animate()
                                .fadeIn(),
                          ],
                          espace,
                          DropdownButtonFormField<NiveauActivite>(
                            initialValue: _niveau,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Niveau d\'activité'),
                            // Dans le champ fermé, on n'affiche que le libellé.
                            selectedItemBuilder: (context) => [
                              for (final n in NiveauActivite.values) Text(n.libelle),
                            ],
                            items: [
                              for (final n in NiveauActivite.values)
                                DropdownMenuItem(
                                  value: n,
                                  child: Text('${n.libelle} · ${n.description}'),
                                ),
                            ],
                            onChanged: (n) => setState(() => _niveau = n ?? _niveau),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const Key('bouton_enregistrer_profil'),
                            onPressed: _enregistrer,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Enregistrer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (profil != null) ...[
                    const SizedBox(height: 12),
                    // Repère calorique basé sur la dernière pesée, si elle existe.
                    CarteObjectifCalorique(profil: profil, poidsActuelKg: dernierPoids),
                  ],
                ]
                    .animate(interval: 60.ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOutCubic),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
