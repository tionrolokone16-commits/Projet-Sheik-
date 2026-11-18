import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/theme.dart';

/// Vérifie la lisibilité : contraste d'au moins 4,5:1 (norme WCAG AA)
/// pour toutes les associations texte / fond importantes.
void main() {
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (clair, fonce) = la > lb ? (la, lb) : (lb, la);
    return (clair + 0.05) / (fonce + 0.05);
  }

  ThemeFormeDouce.utiliserGoogleFonts = false; // pas d'internet en test

  for (final (nom, theme) in [
    ('clair', ThemeFormeDouce.clair()),
    ('sombre', ThemeFormeDouce.sombre()),
  ]) {
    final c = theme.colorScheme;
    final carte = theme.cardTheme.color!;
    final paires = {
      'texte sur fond': (c.onSurface, c.surface),
      'texte sur carte': (c.onSurface, carte),
      'texte secondaire sur fond': (c.onSurfaceVariant, c.surface),
      'texte secondaire sur carte': (c.onSurfaceVariant, carte),
      'bouton': (c.onPrimary, c.primary),
      'accent sur carte': (c.primary, carte),
      'accent sur fond': (c.primary, c.surface),
      'pastille': (c.onPrimaryContainer, c.primaryContainer),
      'encadré doux': (c.onTertiaryContainer, c.tertiaryContainer),
    };
    paires.forEach((libelle, couleurs) {
      test('thème $nom : $libelle', () {
        expect(contraste(couleurs.$1, couleurs.$2), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('framboise texte lisible sur rose poudré', () {
    expect(contraste(Palette.framboiseTexte, Palette.rosePoudre),
        greaterThanOrEqualTo(4.5));
  });
}
