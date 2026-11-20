import 'dart:ui';

import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/plat.dart';
import '../models/repas_photo.dart';
import 'habitudes_service.dart';
import 'journal_service.dart';

/// Ce qu'une case du calendrier affiche pour une journée.
class ResumeJour {
  const ResumeJour({
    required this.habitudes,
    required this.repasNotes,
    required this.eau,
    required this.activite,
    required this.humeur,
    required this.plaisir,
    required this.regles,
  });

  /// Nombre d'habitudes prises en soin (0 à 4) : il donne la couleur du jour.
  final int habitudes;

  /// Pastilles : repas notés 🍽️, eau 💧, activité 🏃🏾‍♀️, humeur, plaisir 🌸, règles 🩸.
  final bool repasNotes;
  final bool eau;
  final bool activite;

  /// Emoji d'humeur (`null` si aucun ressenti n'est noté).
  final String? humeur;
  final bool plaisir;
  final bool regles;

  /// Pastilles à afficher, dans l'ordre.
  List<String> get pastilles => [
    if (repasNotes) '🍽️',
    if (eau) '💧',
    if (activite) '🏃🏾‍♀️',
    ?humeur,
    if (plaisir) '🌸',
    if (regles) '🩸',
  ];

  bool get estVide => habitudes == 0 && pastilles.isEmpty;
}

/// Règles d'affichage du calendrier.
///
/// La couleur d'un jour vient uniquement des HABITUDES tenues (eau, sommeil,
/// mouvement, repas) : jamais du poids, jamais de ce qui a été mangé.
/// Un jour vide reste neutre et doux : aucune case n'est rouge.
class CalendrierService {
  CalendrierService._();

  /// Emoji d'humeur selon l'humeur moyenne (1 à 5).
  static const emojisHumeur = ['😔', '😕', '😐', '🙂', '😊'];

  static ResumeJour resume({
    required JourHabitudes jour,
    required List<Activite> activitesDuJour,
    required List<RepasPhoto> repasDuJour,
    required int objectifVerres,
    required bool suiviCycle,
  }) {
    final humeur = JournalService.humeur(jour);
    return ResumeJour(
      habitudes: HabitudesService.tenues(
        jour,
        activitesDuJour: activitesDuJour,
        objectifVerres: objectifVerres,
      ).length,
      repasNotes: repasDuJour.isNotEmpty || jour.repas.isNotEmpty,
      eau: jour.verres > 0,
      activite: activitesDuJour.isNotEmpty,
      humeur: humeur == null ? null : emojisHumeur[(humeur.round() - 1).clamp(0, 4)],
      plaisir: repasDuJour.any((r) => (r.ressentis[RessentiRepas.plaisir] ?? 0) >= 4),
      regles: suiviCycle && jour.regles,
    );
  }

  /// Teintes de rose, de la plus pâle (1 habitude) à la plus vive (4).
  static const _rosesClairs = [
    Color(0xFFFDE7EF),
    Color(0xFFF9C4D7),
    Color(0xFFF48FB1),
    Color(0xFFE8578A),
  ];
  static const _rosesSombres = [
    Color(0xFF4A2338),
    Color(0xFF6B2E4A),
    Color(0xFF943E66),
    Color(0xFFC2185B),
  ];

  /// Couleur de fond d'un jour, ou `null` pour un jour sans habitude
  /// (la case garde alors la couleur neutre du thème).
  static Color? couleur(int habitudes, Brightness luminosite) {
    if (habitudes <= 0) return null;
    final teintes = luminosite == Brightness.dark ? _rosesSombres : _rosesClairs;
    return teintes[(habitudes - 1).clamp(0, 3)];
  }

  /// Toutes les teintes (pour la légende et les tests de lisibilité).
  static List<Color> teintes(Brightness luminosite) =>
      luminosite == Brightness.dark ? _rosesSombres : _rosesClairs;
}
