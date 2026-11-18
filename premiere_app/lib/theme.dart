import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Palette de Kira's FAT : rose poudré, framboise, corail et doré.
///
/// Contraste (lisibilité) : le framboise vif #E91E63 n'atteint pas le
/// minimum recommandé de 4,5:1 pour du petit texte sur fond clair. On le
/// réserve donc aux grands éléments décoratifs, et on utilise des nuances
/// un peu plus foncées pour les boutons et le texte (voir test/theme_test.dart).
class Palette {
  Palette._();

  // ----- Mode clair -----
  /// Fond principal : rose poudré très clair.
  static const rosePoudre = Color(0xFFFFF0F5);

  /// Accent vif, pour les grands éléments décoratifs (icônes, barres, plante…).
  static const framboise = Color(0xFFE91E63);

  /// Framboise des boutons : texte blanc lisible dessus (contraste ≈ 5,3:1),
  /// et lisible aussi en texte sur le fond rose poudré (≈ 4,8:1).
  static const framboiseBouton = Color(0xFFD01A5E);

  /// Framboise pour le texte accentué sur fond clair (contraste ≈ 5,9:1).
  static const framboiseTexte = Color(0xFFC2185B);

  /// Rose pâle des pastilles et sélections.
  static const roseTendre = Color(0xFFFCE4EC);

  // ----- Petites célébrations -----
  static const corail = Color(0xFFFF8A7A);
  static const dore = Color(0xFFF6C453);

  // ----- Mode sombre -----
  /// Fond prune foncé.
  static const prune = Color(0xFF241019);

  /// Cartes du mode sombre.
  static const pruneCarte = Color(0xFF341A29);

  /// Rose clair des accents en mode sombre.
  static const roseSombre = Color(0xFFF48FB1);

  /// Couleurs des confettis.
  static const confettis = [framboise, corail, dore, roseSombre, Color(0xFFFFFFFF)];
}

/// Construction des thèmes clair et sombre.
class ThemeFormeDouce {
  ThemeFormeDouce._();

  /// Mettre à `false` dans les tests : la police ne peut pas être téléchargée
  /// sans connexion internet.
  static bool utiliserGoogleFonts = true;

  /// Rayon des coins arrondis des cartes.
  static const rayon = 24.0;

  static ThemeData clair() {
    final couleurs = ColorScheme.fromSeed(
      seedColor: Palette.framboise,
      brightness: Brightness.light,
    ).copyWith(
      primary: Palette.framboiseBouton,
      onPrimary: Colors.white,
      primaryContainer: Palette.roseTendre,
      onPrimaryContainer: const Color(0xFF5C0A2B),
      secondary: Palette.framboiseTexte,
      tertiary: const Color(0xFFB4462F), // corail foncé, lisible
      tertiaryContainer: const Color(0xFFFFE3DC),
      onTertiaryContainer: const Color(0xFF5A1A0C),
      surface: Palette.rosePoudre,
      onSurface: const Color(0xFF2B1620),
      onSurfaceVariant: const Color(0xFF6B4D5A),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Colors.white,
      surfaceContainerHigh: const Color(0xFFFFF7FA),
      outlineVariant: const Color(0xFFF3CFDC),
    );
    return _construire(couleurs, carte: Colors.white);
  }

  static ThemeData sombre() {
    final couleurs = ColorScheme.fromSeed(
      seedColor: Palette.framboise,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Palette.roseSombre,
      onPrimary: const Color(0xFF4A0D26),
      primaryContainer: const Color(0xFF5C1F3C),
      onPrimaryContainer: const Color(0xFFFFD9E4),
      secondary: const Color(0xFFF8BBD0),
      tertiary: Palette.corail,
      tertiaryContainer: const Color(0xFF4D2A22),
      onTertiaryContainer: const Color(0xFFFFDAD2),
      surface: Palette.prune,
      onSurface: const Color(0xFFFBE9F0),
      onSurfaceVariant: const Color(0xFFD9BCC8),
      surfaceContainerLowest: const Color(0xFF1E0D15),
      surfaceContainerLow: Palette.pruneCarte,
      surfaceContainer: Palette.pruneCarte,
      surfaceContainerHigh: const Color(0xFF412233),
      outlineVariant: const Color(0xFF5A3647),
    );
    return _construire(couleurs, carte: Palette.pruneCarte);
  }

  static ThemeData _construire(ColorScheme couleurs, {required Color carte}) {
    final base = ThemeData(colorScheme: couleurs);
    final arrondi = BorderRadius.circular(rayon);
    final ombre = couleurs.brightness == Brightness.light
        ? Palette.framboise.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.5);

    return base.copyWith(
      scaffoldBackgroundColor: couleurs.surface,
      // Police ronde et moderne.
      textTheme: utiliserGoogleFonts
          ? GoogleFonts.nunitoTextTheme(base.textTheme)
          : base.textTheme,
      // Transitions en fondu entre les écrans.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: const FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: couleurs.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: base.textTheme.headlineSmall?.copyWith(
          fontFamily: utiliserGoogleFonts ? GoogleFonts.nunito().fontFamily : null,
          fontWeight: FontWeight.w800,
          color: couleurs.onSurface,
        ),
      ),
      // Cartes blanches, coins de 24 px, ombre douce.
      cardTheme: CardThemeData(
        color: carte,
        elevation: 4,
        shadowColor: ombre,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: arrondi),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: carte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: couleurs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: couleurs.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: couleurs.primary,
        foregroundColor: couleurs.onPrimary,
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: carte,
        indicatorColor: couleurs.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: ombre,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: carte,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: arrondi),
      ),
    );
  }
}
