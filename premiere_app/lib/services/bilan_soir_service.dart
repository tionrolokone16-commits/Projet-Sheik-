import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/reglages.dart';
import '../models/repas_photo.dart';
import 'bilan_service.dart';
import 'habitudes_service.dart';

/// Petites idées pour le lendemain d'une journée compliquée.
/// Des gestes de douceur : jamais une restriction, jamais une compensation.
enum IdeeDemain {
  coucherTot('😴', 'Me coucher un peu plus tôt ce soir'),
  petitDej('🥐', 'Préparer de quoi prendre un bon petit-déjeuner'),
  eau('💧', 'Garder une bouteille d\'eau près de moi'),
  air('🌳', 'Prendre l\'air 10 minutes, tranquillement'),
  respirer('🫁', 'M\'offrir une minute pour respirer'),
  moment('💗', 'M\'accorder un moment rien que pour moi'),
  proche('📞', 'Parler à quelqu\'un qui me fait du bien');

  const IdeeDemain(this.emoji, this.texte);
  final String emoji;
  final String texte;

  static IdeeDemain? depuisNom(String nom) {
    for (final i in values) {
      if (i.name == nom) return i;
    }
    return null;
  }
}

/// Bilan du soir : un bravo pour ce qui a été FAIT dans la journée.
/// Rien n'est jamais présenté comme manqué.
class BilanSoirService {
  BilanSoirService._();

  /// Vrai si le bilan du soir doit apparaître sur l'accueil :
  /// activé, l'heure est passée, et il n'a pas encore été ouvert aujourd'hui.
  static bool aAfficher({
    required DateTime maintenant,
    required Reglages reglages,
    required bool dejaVu,
  }) {
    if (!reglages.bilanSoir || dejaVu) return false;
    return maintenant.hour * 60 + maintenant.minute >= reglages.heureBilanSoir;
  }

  /// Ce qui a été fait dans la journée, en phrases positives.
  static List<LigneBilan> bravos({
    required JourHabitudes jour,
    required List<Activite> activitesDuJour,
    required List<RepasPhoto> repasDuJour,
    required int objectifVerres,
  }) {
    String pluriel(int n, String un, String plusieurs) => n > 1 ? plusieurs : un;
    final repas = repasDuJour.isNotEmpty ? repasDuJour.length : jour.repas.length;
    final minutes = activitesDuJour.fold<int>(0, (s, a) => s + a.dureeMinutes);
    return [
      if (repas > 0) (emoji: '🍽️', texte: 'Tu as noté $repas repas'),
      if (jour.verres >= objectifVerres)
        (emoji: '💧', texte: '${jour.verres} verres d\'eau : objectif atteint ✨')
      else if (jour.verres > 0)
        (emoji: '💧', texte: '${jour.verres} ${pluriel(jour.verres, 'verre', 'verres')} d\'eau'),
      if (minutes > 0)
        (emoji: '🚶', texte: '${HabitudesService.formaterMinutes(minutes)} de mouvement'),
      if (jour.seanceFaite) (emoji: '✅', texte: 'Ta séance est faite'),
      if (jour.pas != null && jour.pas! > 0)
        (emoji: '👣', texte: '${HabitudesService.formaterPas(jour.pas!)} pas'),
      if (jour.sommeilHeures != null) (emoji: '🌙', texte: 'Tu as pris le temps de noter ta nuit'),
      if (jour.ressentis.isNotEmpty || jour.digestion != null)
        (emoji: '💭', texte: 'Tu as écouté comment tu te sentais'),
      if (jour.note != null && jour.note!.trim().isNotEmpty)
        (emoji: '📝', texte: 'Tu t\'es écrit un petit mot'),
    ];
  }

  /// Phrase d'introduction du bilan du soir.
  static String introduction(int nombreBravos) => nombreBravos == 0
      ? 'Une journée toute douce. Te reposer compte aussi 🌙'
      : 'Regarde tout ce que tu as fait aujourd\'hui 💗';

  /// Mot de réconfort après une journée compliquée.
  static const reconfort =
      'Merci de me le dire 💗 Les journées compliquées font partie du chemin, '
      'elles n\'effacent rien de ce que tu as construit. Tu as fait de ton mieux, '
      'et c\'est assez. Demain est une nouvelle page.';
}
