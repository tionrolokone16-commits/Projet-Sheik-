import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// Ouvre la photothèque (ou l'appareil photo) et renvoie la photo choisie,
/// réduite et encodée en texte (base64). Renvoie `null` si l'on annule.
///
/// La photo n'est jamais envoyée sur internet : elle reste sur l'appareil.
Future<String?> choisirPhotoProfil(BuildContext context) async {
  try {
    final fichier = await ImagePicker().pickImage(
      source: ImageSource.gallery, // sur iPhone : propose aussi l'appareil photo
      maxWidth: 400, // petite taille : suffisant pour un avatar, peu de place
      imageQuality: 80,
    );
    if (fichier == null) return null;
    return base64Encode(await fichier.readAsBytes());
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La photo n\'a pas pu être ouverte. Réessaie avec une autre 🌸'),
      ));
    }
    return null;
  }
}

/// Photo de profil ronde, avec un liseré framboise.
/// Sans photo : l'initiale du prénom sur fond rose.
class AvatarProfil extends StatefulWidget {
  const AvatarProfil({
    super.key,
    required this.photoBase64,
    required this.prenom,
    this.taille = 64,
    this.onTap,
    this.badgeAppareilPhoto = false,
  });

  final String? photoBase64;
  final String prenom;
  final double taille;
  final VoidCallback? onTap;

  /// Affiche une petite pastille « appareil photo » (l'avatar est modifiable).
  final bool badgeAppareilPhoto;

  @override
  State<AvatarProfil> createState() => _AvatarProfilState();
}

class _AvatarProfilState extends State<AvatarProfil> {
  /// Photo décodée une seule fois (et non à chaque affichage).
  Uint8List? _octets;

  @override
  void initState() {
    super.initState();
    _decoder();
  }

  @override
  void didUpdateWidget(AvatarProfil ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.photoBase64 != widget.photoBase64) _decoder();
  }

  void _decoder() {
    final texte = widget.photoBase64;
    try {
      _octets = texte == null ? null : base64Decode(texte);
    } catch (_) {
      _octets = null; // photo abîmée : on affiche l'initiale
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleurs = Theme.of(context).colorScheme;
    final t = widget.taille;
    final prenom = widget.prenom.trim();

    final avatar = Container(
      width: t,
      height: t,
      padding: EdgeInsets.all(t * 0.04),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFFEC407A), Color(0xFFF6C453)]),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: couleurs.primaryContainer,
          border: Border.all(color: couleurs.surface, width: t * 0.03),
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: _octets != null
            ? Image.memory(
                _octets!,
                width: t,
                height: t,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            : prenom.isEmpty
                // Pas encore de prénom : une silhouette.
                ? Icon(Icons.person_rounded, size: t * 0.5, color: couleurs.onPrimaryContainer)
                : Text(
                    prenom.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: t * 0.4,
                      fontWeight: FontWeight.w800,
                      color: couleurs.onPrimaryContainer,
                    ),
                  ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      label: _octets != null ? 'Photo de profil' : 'Ajouter une photo de profil',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            if (widget.badgeAppareilPhoto)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: t * 0.32,
                  height: t * 0.32,
                  decoration: BoxDecoration(
                    color: couleurs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: couleurs.surface, width: 2),
                  ),
                  child: Icon(Icons.photo_camera_rounded,
                      size: t * 0.17, color: couleurs.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
