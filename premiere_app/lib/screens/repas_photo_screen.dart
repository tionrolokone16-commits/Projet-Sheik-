import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/jour_habitudes.dart';
import '../models/recette.dart';
import '../providers/habitudes_provider.dart';
import '../providers/recompenses_provider.dart';
import '../services/assiette_service.dart';
import '../services/recompenses_service.dart';
import '../widgets/assiette.dart';

/// Noter un repas : photo (facultative), puis la personne indique elle-même
/// les portions. L'assiette colorée se dessine au fur et à mesure.
///
/// L'application n'analyse PAS la photo : elle reste sur l'appareil et sert
/// de souvenir. L'animation n'est qu'une transition, pas une fausse analyse.
class RepasPhotoScreen extends StatefulWidget {
  const RepasPhotoScreen({super.key, required this.date});

  /// Jour auquel rattacher le repas.
  final DateTime date;

  @override
  State<RepasPhotoScreen> createState() => _RepasPhotoScreenState();
}

/// Les trois étapes de l'écran.
enum _Etape { photo, preparation, portions }

class _RepasPhotoScreenState extends State<RepasPhotoScreen> {
  _Etape _etape = _Etape.photo;
  Uint8List? _photo;
  late Repas _repas = AssietteService.repasSelonHeure(DateTime.now());

  // Quantités choisies (0 à 4) pour chaque famille.
  int _legumes = 1;
  int _proteines = 1;
  int _feculents = 1;

  Portions get _portions => Portions.normalisees(
      _legumes.toDouble(), _proteines.toDouble(), _feculents.toDouble());

  Future<void> _choisirPhoto() async {
    try {
      final fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery, // sur iPad : propose aussi l'appareil photo
        maxWidth: 480, // photo réduite : elle prend peu de place
        imageQuality: 60,
      );
      if (fichier == null) return; // annulé
      final octets = await fichier.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = octets;
        _etape = _Etape.preparation;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La photo n\'a pas pu être ouverte. Tu peux continuer sans 🌸'),
      ));
    }
  }

  void _sansPhoto() => setState(() => _etape = _Etape.portions);

  Future<void> _enregistrer() async {
    final habitudes = context.read<HabitudesProvider>();
    final recompenses = context.read<RecompensesProvider>();
    final portions = _portions;
    final maintenant = DateTime.now();
    final estAujourdhui = DateUtils.isSameDay(widget.date, maintenant);
    await habitudes.ajouterRepasPhoto(
      date: estAujourdhui
          ? maintenant
          : DateTime(widget.date.year, widget.date.month, widget.date.day, 12),
      repas: _repas,
      portions: portions,
      photoBase64: _photo == null ? null : base64Encode(_photo!),
    );
    // Défi « des légumes à 5 repas » : il avance tout seul si le défi est choisi.
    if (portions.legumes >= AssietteService.seuilLegumesDefi &&
        recompenses.defisDeLaSemaine(widget.date).contains(Defi.legumes)) {
      await recompenses.ajusterDefi(widget.date, Defi.legumes, 1);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_repas.emoji} Repas noté, bon appétit !')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon assiette')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: switch (_etape) {
                _Etape.photo => _ChoixPhoto(
                    key: const ValueKey('photo'),
                    onPhoto: _choisirPhoto,
                    onSansPhoto: _sansPhoto,
                  ),
                _Etape.preparation => _Preparation(
                    key: const ValueKey('preparation'),
                    photo: _photo!,
                    onTerminee: () => setState(() => _etape = _Etape.portions),
                  ),
                _Etape.portions => _portionsVue(context),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _portionsVue(BuildContext context) {
    final theme = Theme.of(context);
    final portions = _portions;
    final idee = AssietteService.idee(portions);

    Widget curseur(String emoji, String nom, Color couleur, int valeur, ValueChanged<int> onChange) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$emoji $nom', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(AssietteService.quantites[valeur], style: theme.textTheme.bodySmall),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: couleur,
              thumbColor: couleur,
              inactiveTrackColor: couleur.withValues(alpha: 0.25),
            ),
            child: Slider(
              key: Key('curseur_$nom'),
              value: valeur.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: AssietteService.quantites[valeur],
              onChanged: (v) => setState(() => onChange(v.round())),
            ),
          ),
        ],
      );
    }

    return ListView(
      key: const ValueKey('portions'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Photo (si prise) et assiette côte à côte.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_photo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(_photo!, width: 130, height: 130, fit: BoxFit.cover),
                      ),
                    Assiette(portions: portions, taille: 160),
                  ],
                ),
                const SizedBox(height: 12),
                LegendeAssiette(portions: portions),
                const SizedBox(height: 12),
                Text(
                  AssietteService.message(portions),
                  key: const Key('message_assiette'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (idee != null) ...[
                  const SizedBox(height: 6),
                  Text(idee, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qu\'y a-t-il dans ton assiette ?', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Indique simplement les quantités, à vue d\'œil.',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                curseur('🥦', 'Légumes', CouleursAssiette.legumes, _legumes, (v) => _legumes = v),
                curseur('🍗', 'Protéines', CouleursAssiette.proteines, _proteines,
                    (v) => _proteines = v),
                curseur('🍚', 'Féculents', CouleursAssiette.feculents, _feculents,
                    (v) => _feculents = v),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quel repas ?', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in Repas.values)
                      ChoiceChip(
                        avatar: Text(r.emoji),
                        label: Text(r.libelle),
                        selected: _repas == r,
                        onSelected: (_) => setState(() => _repas = r),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('bouton_enregistrer_repas'),
          onPressed: portions.total > 0 ? _enregistrer : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Enregistrer ce repas'),
        ),
        const SizedBox(height: 12),
        Text(
          'Repère : ½ légumes · ¼ protéines · ¼ féculents. C\'est un repère, '
          'pas une règle : chaque repas compte, et l\'équilibre se fait sur la semaine.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ]
          .animate(interval: 60.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.06, curve: Curves.easeOutCubic),
    );
  }
}

/// Étape 1 : prendre une photo, ou continuer sans.
class _ChoixPhoto extends StatelessWidget {
  const _ChoixPhoto({super.key, required this.onPhoto, required this.onSansPhoto});

  final VoidCallback onPhoto;
  final VoidCallback onSansPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Text('📸', style: TextStyle(fontSize: 64)),
          )
              .animate()
              .scale(begin: const Offset(0.6, 0.6), duration: 700.ms, curve: Curves.elasticOut),
        ),
        const SizedBox(height: 24),
        Text('Ton assiette en photo',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Prends ton repas en photo, puis indique toi-même ce qu\'il contient. '
          'La photo reste sur ton appareil.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          key: const Key('bouton_prendre_photo'),
          onPressed: onPhoto,
          icon: const Icon(Icons.photo_camera_rounded),
          label: const Text('Prendre ou choisir une photo'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('bouton_sans_photo'),
          onPressed: onSansPhoto,
          child: const Text('Continuer sans photo'),
        ),
      ],
    );
  }
}

/// Étape 2 : courte transition pendant que l'assiette se prépare
/// (un reflet lumineux balaie la photo). Aucune analyse n'est faite.
class _Preparation extends StatelessWidget {
  const _Preparation({super.key, required this.photo, required this.onTerminee});

  final Uint8List photo;
  final VoidCallback onTerminee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.memory(photo, width: 240, height: 240, fit: BoxFit.cover),
          )
              .animate(onComplete: (_) => onTerminee())
              .scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOut)
              .then()
              // Reflet lumineux qui balaie la photo, deux fois.
              .shimmer(duration: 700.ms, color: Colors.white.withValues(alpha: 0.7))
              .then()
              .shimmer(duration: 700.ms, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 20),
          Text('Je prépare ton assiette…', style: theme.textTheme.titleMedium)
              .animate()
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
