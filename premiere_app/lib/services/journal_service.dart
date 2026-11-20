import '../models/jour_habitudes.dart';

/// Outils du journal : humeur d'une journée et noms relatifs des jours.
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
