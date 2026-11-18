import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/recette.dart';
import '../theme.dart';
import 'assiette.dart';

/// Carte recette qui se retourne en 3D quand on la touche :
/// - recto : le plat d'origine ;
/// - verso : la version plus équilibrée, avec son assiette.
class CarteRecette extends StatefulWidget {
  const CarteRecette({super.key, required this.recette, required this.onCuisinee});

  final Recette recette;

  /// Appelé quand on touche « Je l'ai cuisinée ».
  final VoidCallback onCuisinee;

  static const hauteur = 470.0;

  @override
  State<CarteRecette> createState() => _CarteRecetteState();
}

class _CarteRecetteState extends State<CarteRecette> with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  bool get _verso => _rotation.value >= 0.5;

  void _retourner() {
    if (_rotation.status == AnimationStatus.completed ||
        _rotation.status == AnimationStatus.forward) {
      _rotation.reverse();
    } else {
      _rotation.forward();
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.recette.nom}. Toucher pour retourner la carte.',
      child: GestureDetector(
        key: Key('recette_${widget.recette.id}'),
        onTap: _retourner,
        child: AnimatedBuilder(
          animation: _rotation,
          builder: (context, _) {
            final angle = Curves.easeInOutCubic.transform(_rotation.value) * math.pi;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012) // perspective
                ..rotateY(angle),
              child: _verso
                  // Le verso est retourné une 2e fois pour ne pas être en miroir.
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _Verso(recette: widget.recette, onCuisinee: widget.onCuisinee),
                    )
                  : _Recto(recette: widget.recette),
            );
          },
        ),
      ),
    );
  }
}

/// Cadre commun aux deux faces.
class _Face extends StatelessWidget {
  const _Face({required this.child, this.degrade});

  final Widget child;
  final Gradient? degrade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CarteRecette.hauteur,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: degrade),
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

class _Recto extends StatelessWidget {
  const _Recto({required this.recette});

  final Recette recette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sombre = theme.colorScheme.brightness == Brightness.dark;
    return _Face(
      degrade: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: sombre
            ? [Palette.pruneCarte, const Color(0xFF4D2A22)]
            : [Colors.white, const Color(0xFFFFE3DC)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Chip(
            avatar: const Text('❤️'),
            label: const Text('Le plat d\'origine'),
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
          // Le grand emoji prend la place libre, et rétrécit si le texte est long.
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(recette.emoji, style: const TextStyle(fontSize: 84)),
              ),
            ),
          ),
          Text(recette.nom,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(recette.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Il a toute sa place dans ta vie 💗',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Touche pour découvrir la version revisitée',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Verso extends StatelessWidget {
  const _Verso({required this.recette, required this.onCuisinee});

  final Recette recette;
  final VoidCallback onCuisinee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Face(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(recette.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Version revisitée',
                  key: Key('verso_${recette.id}'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.flip_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Assiette(portions: recette.portions, taille: 96),
              const SizedBox(width: 12),
              Expanded(child: LegendeAssiette(portions: recette.portions)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final astuce in recette.astuces)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🌸 '),
                          Expanded(child: Text(astuce, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: Key('cuisinee_${recette.id}'),
              onPressed: onCuisinee,
              icon: const Text('🍳'),
              label: const Text('Je l\'ai cuisinée'),
            ),
          ),
        ],
      ),
    );
  }
}
