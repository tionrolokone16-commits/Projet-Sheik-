import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/repas_photo.dart';
import 'habitudes_service.dart';

/// Une recommandation : un emoji, un titre court et un conseil concret.
typedef Recommandation = ({String emoji, String titre, String texte});

/// Ce qui manque encore pour que la journée soit complète.
enum InfoManquante {
  repas('🍽️', 'tes repas'),
  eau('💧', 'ton eau'),
  nuit('🌙', 'ta nuit'),
  energie('⚡', 'ton énergie');

  const InfoManquante(this.emoji, this.libelle);
  final String emoji;
  final String libelle;
}

/// Recommandations de fin de journée, à partir de ce qui a été noté.
/// Ton bienveillant : des conseils concrets, jamais de reproche.
class RecommandationsService {
  RecommandationsService._();

  /// Nombre de repas notés pour considérer la journée complète.
  static const repasPourCompleter = 3;

  /// Nombre maximum de recommandations affichées.
  static const maximum = 5;

  /// Ce qui manque pour que la journée soit complète (vide : journée complète).
  static List<InfoManquante> manquantes({
    required JourHabitudes jour,
    required List<RepasPhoto> repasDuJour,
  }) {
    final repas = repasDuJour.isNotEmpty ? repasDuJour.length : jour.repas.length;
    return [
      if (repas < repasPourCompleter) InfoManquante.repas,
      if (jour.verres == 0) InfoManquante.eau,
      if (jour.sommeilHeures == null) InfoManquante.nuit,
      if (!jour.ressentis.containsKey(Ressenti.energie)) InfoManquante.energie,
    ];
  }

  /// Recommandations pour une journée complète, les plus utiles d'abord.
  static List<Recommandation> calculer({
    required JourHabitudes jour,
    required List<RepasPhoto> repasDuJour,
    required List<Activite> activitesDuJour,
    required int objectifVerres,
    required int consomme,
    required int? objectifKcal,
  }) {
    final liste = <Recommandation>[];

    // ----- Calories par rapport à l'objectif -----
    if (objectifKcal != null) {
      final ecart = consomme - objectifKcal;
      if (ecart > 150) {
        liste.add((
          emoji: '⚖️',
          titre: 'Retrouver l\'équilibre',
          texte:
              'Tu es ≈ $ecart kcal au-dessus de ton objectif. Une marche ou une séance '
              '(voir « Retrouver l\'équilibre ») peut aider, et demain une assiette avec '
              'plus de légumes.',
        ));
      } else if (ecart < -500) {
        liste.add((
          emoji: '🍊',
          titre: 'Bien te nourrir',
          texte:
              'Tu as mangé nettement moins que ton objectif (≈ ${-ecart} kcal de moins). '
              'Manger trop peu fatigue le corps : un en-cas équilibré (fruit, yaourt, '
              'arachides) est une bonne idée.',
        ));
      } else {
        liste.add((
          emoji: '🎯',
          titre: 'Objectif respecté',
          texte: 'Tes calories sont proches de ton objectif aujourd\'hui. Bravo, continue ainsi !',
        ));
      }
    }

    // ----- Composition des assiettes -----
    final assiettes = repasDuJour.where((r) => r.portions.total > 0).toList();
    if (assiettes.isNotEmpty) {
      double moyenne(double Function(RepasPhoto) part) =>
          assiettes.fold<double>(0, (s, r) => s + part(r)) / assiettes.length;
      final legumes = moyenne((r) => r.portions.legumes);
      final proteines = moyenne((r) => r.portions.proteines);
      final feculents = moyenne((r) => r.portions.feculents);
      if (legumes < 0.25) {
        liste.add((
          emoji: '🥗',
          titre: 'Plus de légumes',
          texte:
              'Les légumes ont été discrets aujourd\'hui. Vise une demi-assiette de légumes '
              'au prochain repas (sauce feuille, gombo, aubergine, crudités…).',
        ));
      }
      if (feculents > 0.5) {
        liste.add((
          emoji: '🍚',
          titre: 'Équilibrer les féculents',
          texte:
              'Les féculents (riz, attiéké, foutou…) ont pris beaucoup de place. Un quart '
              'd\'assiette suffit, le reste en légumes et protéines.',
        ));
      }
      if (proteines < 0.15) {
        liste.add((
          emoji: '🐟',
          titre: 'Un peu plus de protéines',
          texte:
              'Ajoute une source de protéines à tes repas : poisson, poulet, œuf, haricots '
              'ou lentilles. Elles aident à tenir jusqu\'au repas suivant.',
        ));
      }
    }

    // ----- Repas : petit-déjeuner et dîner tardif -----
    final moments = repasDuJour.isNotEmpty ? repasDuJour.map((r) => r.repas).toSet() : jour.repas;
    if (!moments.contains(Repas.petitDejeuner)) {
      liste.add((
        emoji: '🥐',
        titre: 'Le petit-déjeuner',
        texte:
            'Demain, prends un petit-déjeuner (bouillie, pain et œuf, fruit…) : il aide '
            'à éviter les fringales de la journée.',
      ));
    }
    if (repasDuJour.any((r) => r.repas == Repas.diner && r.date.hour >= 21)) {
      liste.add((
        emoji: '🕘',
        titre: 'Dîner un peu plus tôt',
        texte:
            'Ton dîner était tardif. Quand c\'est possible, dîne avant 20 h 30 pour mieux dormir.',
      ));
    }

    // ----- Eau -----
    if (jour.verres < objectifVerres) {
      final reste = objectifVerres - jour.verres;
      liste.add((
        emoji: '💧',
        titre: 'Boire un peu plus',
        texte:
            'Encore $reste verre${reste > 1 ? 's' : ''} pour ton objectif d\'eau. Garde une '
            'bouteille près de toi demain.',
      ));
    }

    // ----- Sommeil -----
    final nuit = jour.sommeilHeures!;
    if (nuit < HabitudesService.sommeilReparateurHeures) {
      liste.add((
        emoji: '😴',
        titre: 'Une nuit plus longue',
        texte:
            'Ta nuit a duré ${HabitudesService.formaterHeures(nuit)}. Ce soir, essaie de te '
            'coucher 30 minutes plus tôt : le sommeil aide aussi à perdre du poids.',
      ));
    }

    // ----- Mouvement -----
    final enMouvement = HabitudesService.enMouvement(jour, activitesDuJour);
    if (!enMouvement) {
      liste.add((
        emoji: '🚶',
        titre: 'Bouger un peu',
        texte:
            'Pas beaucoup de mouvement aujourd\'hui. Demain, une marche de 20 minutes '
            'ferait du bien à ton corps et à ton moral.',
      ));
    }

    // ----- Stress et digestion -----
    if ((jour.ressentis[Ressenti.stress] ?? 0) >= 4) {
      liste.add((
        emoji: '🫁',
        titre: 'Souffler un peu',
        texte:
            'La journée a été stressante. Une minute de respiration (bouton « Fringale » '
            'de l\'accueil) aide à relâcher la pression.',
      ));
    }
    if (jour.digestion != null && jour.digestion! <= 2) {
      liste.add((
        emoji: '🌿',
        titre: 'Ménager ta digestion',
        texte:
            'Ta digestion a été inconfortable. Mange lentement, privilégie des plats moins '
            'gras et épicés, et parles-en à ta diététicienne si ça dure.',
      ));
    }

    // Rien à améliorer : un mot positif.
    if (liste.every((r) => r.titre == 'Objectif respecté')) {
      liste.add((
        emoji: '✨',
        titre: 'Belle journée',
        texte: 'Eau, sommeil, repas : tout est bien équilibré aujourd\'hui. Merci d\'avoir tout noté !',
      ));
    }
    return liste.take(maximum).toList();
  }
}
