import '../models/activite.dart';
import '../models/jour_habitudes.dart';

/// Les 4 habitudes suivies (elles feront grandir la plante 🌸).
/// Le poids n'en fait jamais partie.
enum Habitude {
  eau('Hydratation', '💧'),
  sommeil('Sommeil', '🌙'),
  mouvement('Mouvement', '🚶'),
  repas('Repas', '🍽️');

  const Habitude(this.libelle, this.emoji);
  final String libelle;
  final String emoji;
}

/// Règles qui décident si une habitude est « prise en soin » un jour donné.
class HabitudesService {
  HabitudesService._();

  /// Durée de sommeil à partir de laquelle la nuit compte comme réparatrice.
  static const sommeilReparateurHeures = 7.0;

  /// Nombre de pas à partir duquel la journée compte comme « en mouvement ».
  static const pasMouvement = 5000;

  /// Vrai si la journée a été en mouvement : une activité, une séance faite
  /// ou une bonne marche.
  static bool enMouvement(JourHabitudes jour, List<Activite> activitesDuJour) =>
      activitesDuJour.isNotEmpty || jour.seanceFaite || (jour.pas ?? 0) >= pasMouvement;

  /// Habitudes tenues pour une journée.
  static Set<Habitude> tenues(
    JourHabitudes jour, {
    required List<Activite> activitesDuJour,
    required int objectifVerres,
  }) {
    return {
      if (jour.verres >= objectifVerres) Habitude.eau,
      if ((jour.sommeilHeures ?? 0) >= sommeilReparateurHeures) Habitude.sommeil,
      if (enMouvement(jour, activitesDuJour)) Habitude.mouvement,
      if (jour.repas.containsAll(Repas.principaux)) Habitude.repas,
    };
  }

  /// Phrase encourageante selon le nombre d'habitudes tenues.
  /// Jamais de reproche : une journée sans rien noté est « toute neuve ».
  static String message(int nombre, {bool aujourdhui = true}) {
    final quand = aujourdhui ? 'aujourd\'hui' : 'ce jour-là';
    return switch (nombre) {
      0 when aujourdhui => 'Une journée toute neuve 🌱 Chaque petit geste compte.',
      0 => 'Une journée tout en douceur 🌱 Tu peux encore y noter ce que tu as fait.',
      1 => '1 habitude prise en soin $quand 🌸',
      4 => 'Les 4 habitudes du jour, quelle belle journée ✨',
      _ => '$nombre habitudes prises en soin $quand 🌸',
    };
  }

  /// Message doux sur le sommeil, sans jugement.
  static String messageSommeil(double? heures) {
    if (heures == null) return 'Glisse le curseur pour noter ta nuit.';
    if (heures >= sommeilReparateurHeures) return 'Belle nuit réparatrice ✨';
    return 'Chaque nuit compte. Un moment calme ce soir te fera du bien 🌙';
  }

  /// Message doux sur les pas, sans jugement.
  static String messagePas(int? pas) {
    if (pas == null) return 'Recopie le nombre affiché par ton téléphone (app Santé).';
    if (pas >= pasMouvement) return 'Belle balade, tes jambes te disent merci 👣✨';
    return 'Chaque pas compte, bravo de les avoir notés 👣';
  }

  /// Affiche un nombre de pas avec une espace insécable : 7500 → « 7 500 ».
  static String formaterPas(int pas) {
    final texte = pas.toString();
    final morceaux = <String>[];
    for (var fin = texte.length; fin > 0; fin -= 3) {
      morceaux.insert(0, texte.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
    }
    return morceaux.join('\u00a0');
  }

  /// Affiche une durée en heures : 7,5 → « 7 h 30 ».
  static String formaterHeures(double heures) {
    final h = heures.floor();
    final min = ((heures - h) * 60).round();
    return min == 0 ? '$h h' : '$h h ${min.toString().padLeft(2, '0')}';
  }

  /// Affiche une durée en minutes : 75 → « 1 h 15 ».
  static String formaterMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
  }
}
