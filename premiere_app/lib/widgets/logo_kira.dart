import 'package:material_ui/material_ui.dart';

/// Logo de l'application (« K. » blanc sur fond framboise), aux coins arrondis
/// comme une icône d'iPhone. Image générée par tool/generer_icones_test.dart.
class LogoKira extends StatelessWidget {
  const LogoKira({super.key, this.taille = 96});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo Kira\'s FAT',
      image: true,
      child: Container(
        width: taille,
        height: taille,
        decoration: BoxDecoration(
          // Arrondi proche de celui des icônes iOS (~22 %).
          borderRadius: BorderRadius.circular(taille * 0.22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC2185B).withValues(alpha: 0.3),
              blurRadius: taille * 0.18,
              offset: Offset(0, taille * 0.06),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(taille * 0.22),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}
