import 'dart:ui';

import '../models/jour_habitudes.dart';

/// « Ton » d'une journée, déduit uniquement des ressentis notés
/// (énergie, stress, sommeil). Jamais du poids ni des calories.
///
/// Les couleurs sont toutes douces : aucune journée n'est « mauvaise ».
enum TonJour {
  cocooning('Journée à cocooner 🫶', Color(0xFFE3D7F7), Color(0xFF4B3D6B)),
  tranquille('Journée tranquille 🌸', Color(0xFFFAD1E0), Color(0xFF6B2E4A)),
  lumineuse('Journée lumineuse ✨', Color(0xFFFBE3A6), Color(0xFF6B5523));

  const TonJour(this.libelle, this.couleurClaire, this.couleurSombre);
  final String libelle;
  final Color couleurClaire;
  final Color couleurSombre;

  Color couleur(Brightness luminosite) =>
      luminosite == Brightness.dark ? couleurSombre : couleurClaire;
}

class JournalService {
  JournalService._();

  /// Humeur moyenne de 1 à 5 (5 = très agréable), ou `null` si rien n'est noté.
  /// Pour le stress, l'échelle est inversée (peu de stress = agréable).
  static double? humeur(JourHabitudes jour) {
    if (jour.ressentis.isEmpty) return null;
    final valeurs = jour.ressentis.entries
        .map((e) => e.key.hautEstAgreable ? e.value : 6 - e.value)
        .toList();
    return valeurs.reduce((a, b) => a + b) / valeurs.length;
  }

  /// Ton de la journée, ou `null` si aucun ressenti n'est noté.
  static TonJour? ton(JourHabitudes jour) {
    final h = humeur(jour);
    if (h == null) return null;
    if (h < 2.5) return TonJour.cocooning;
    if (h < 3.6) return TonJour.tranquille;
    return TonJour.lumineuse;
  }

  /// « Aujourd'hui », « Hier » ou rien (la date complète est alors affichée).
  static String? nomRelatif(DateTime date, {DateTime? maintenant}) {
    final n = maintenant ?? DateTime.now();
    final aujourdhui = DateTime(n.year, n.month, n.day);
    final jour = DateTime(date.year, date.month, date.day);
    final ecart = aujourdhui.difference(jour).inHours / 24;
    if (ecart.round() == 0) return 'Aujourd\'hui';
    if (ecart.round() == 1) return 'Hier';
    return null;
  }
}
