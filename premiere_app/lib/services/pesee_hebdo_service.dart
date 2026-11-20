import '../models/pesee.dart';
import '../models/profil.dart';
import '../widgets/format.dart';
import 'calculs_service.dart';

/// Une semaine du calendrier des pesées (du lundi au dimanche).
class SemainePesee {
  const SemainePesee({required this.lundi, required this.pesee});

  final DateTime lundi;

  /// Pesée de la semaine (la plus récente de la semaine), ou `null`.
  final Pesee? pesee;

  DateTime get dimanche => DateTime(lundi.year, lundi.month, lundi.day + 6);
}

/// Pesée hebdomadaire : calendrier par semaine et commentaires selon
/// l'objectif de poids. Toujours bienveillant : une remontée est normale.
class PeseeHebdoService {
  PeseeHebdoService._();

  static const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

  /// Nom d'un jour de la semaine (1 = lundi).
  static String nomJour(int jour) => _jours[(jour - 1).clamp(0, 6)];

  static DateTime lundiDe(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  /// Les [nombre] dernières semaines, de la plus récente à la plus ancienne.
  static List<SemainePesee> semaines({
    required int nombre,
    required DateTime maintenant,
    required List<Pesee> pesees,
  }) {
    final lundiActuel = lundiDe(maintenant);
    return [
      for (var s = 0; s < nombre; s++)
        () {
          final lundi = DateTime(lundiActuel.year, lundiActuel.month, lundiActuel.day - 7 * s);
          final fin = DateTime(lundi.year, lundi.month, lundi.day + 7);
          Pesee? pesee;
          for (final p in pesees) {
            if (!p.date.isBefore(lundi) && p.date.isBefore(fin)) {
              if (pesee == null || p.date.isAfter(pesee.date)) pesee = p;
            }
          }
          return SemainePesee(lundi: lundi, pesee: pesee);
        }(),
    ];
  }

  /// Date proposée pour la pesée d'une semaine : le jour de pesée choisi,
  /// sans dépasser aujourd'hui.
  static DateTime dateProposee(DateTime lundi, int jourPesee, DateTime maintenant) {
    final d = DateTime(lundi.year, lundi.month, lundi.day + jourPesee - 1);
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    return d.isAfter(aujourdhui) ? aujourdhui : d;
  }

  /// Vrai si c'est aujourd'hui le jour de pesée et que la semaine n'a pas encore de pesée.
  static bool rappelAujourdhui({
    required DateTime maintenant,
    required int jourPesee,
    required List<Pesee> pesees,
  }) =>
      maintenant.weekday == jourPesee &&
      semaines(nombre: 1, maintenant: maintenant, pesees: pesees).first.pesee == null;

  /// Commentaire pour une pesée, selon l'objectif de poids.
  static List<String> commentaire({
    required Profil profil,
    required List<Pesee> pesees,
    required Pesee pesee,
  }) {
    final triees = [...pesees]..sort((a, b) => a.date.compareTo(b.date));
    final avant = triees.where((p) => p.date.isBefore(pesee.date)).toList();
    final poids = pesee.poidsKg;
    final depart = profil.poidsDepartKg;
    final objectif = profil.poidsObjectifKg;
    final lignes = <String>[];

    if (poids <= objectif) {
      lignes.add('🎉 Objectif atteint : ${formaterDecimal(poids)} kg. Quel beau chemin !');
      return lignes;
    }

    // Variation depuis la pesée précédente.
    if (avant.isNotEmpty) {
      final ecart = poids - avant.last.poidsKg;
      if (ecart < -0.05) {
        lignes.add('🌿 ${formaterDecimal(-ecart)} kg de moins que la pesée précédente, bravo !');
      } else if (ecart > 0.05) {
        lignes.add(
          '🌊 Une petite remontée de ${formaterDecimal(ecart)} kg : c\'est normal (eau, cycle, '
          'sel). C\'est la tendance sur plusieurs semaines qui compte.',
        );
      } else {
        lignes.add('⚖️ Stable depuis la pesée précédente : ton corps prend ses repères.');
      }
    }

    // Chemin parcouru et restant.
    final parcouru = depart - poids;
    final restant = poids - objectif;
    if (parcouru > 0.05) {
      lignes.add(
        '🛤️ ${formaterDecimal(parcouru)} kg de chemin parcouru depuis le départ, '
        'encore ${formaterDecimal(restant)} kg jusqu\'à ${formaterDecimal(objectif)} kg.',
      );
    } else {
      lignes.add(
        '🛤️ ${formaterDecimal(restant)} kg jusqu\'à ton objectif de ${formaterDecimal(objectif)} kg.',
      );
    }

    // Rythme moyen depuis la première pesée, et arrivée estimée.
    if (avant.isNotEmpty) {
      final premiere = triees.first;
      final semaines = pesee.date.difference(premiere.date).inDays / 7;
      if (semaines >= 1) {
        final rythme = (premiere.poidsKg - poids) / semaines;
        if (rythme > 0.05) {
          final vise = CalculsService.perteHebdoMaxKg;
          final comparaison = rythme > vise + 0.3
              ? 'un peu plus rapide que les ${formaterDecimal(vise)} kg visés : '
                    'prends soin de bien te nourrir'
              : rythme >= vise - 0.15
              ? 'pile dans le rythme visé'
              : 'en douceur, et c\'est très bien';
          final semainesRestantes = (restant / rythme).ceil();
          final arrivee = pesee.date.add(Duration(days: semainesRestantes * 7));
          lignes
            ..add('📈 En moyenne ${formaterDecimal(rythme)} kg par semaine, $comparaison.')
            ..add(
              '🎯 À ce rythme, ton objectif serait atteint vers '
              '${_mois[arrivee.month - 1]} ${arrivee.year}.',
            );
        }
      }
    }
    return lignes;
  }

  static const _mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
}
