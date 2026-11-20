import 'package:flutter/foundation.dart';

import '../models/progres.dart';
import '../services/recompenses_service.dart';
import '../services/stockage_service.dart';

/// Une célébration à afficher (confettis + bannière).
class Celebration {
  const Celebration({required this.emoji, required this.titre, required this.message});
  final String emoji;
  final String titre;
  final String message;
}

/// Gère les badges, défis, victoires et la file des célébrations.
class RecompensesProvider extends ChangeNotifier {
  RecompensesProvider(this._stockage) : _progres = _stockage.chargerProgres();

  final StockageService _stockage;
  final Progres _progres;

  /// Célébrations en attente d'affichage.
  final List<Celebration> _file = [];

  Progres get progres => _progres;

  bool get aDesCelebrations => _file.isNotEmpty;

  /// Retire et renvoie la prochaine célébration à afficher.
  Celebration? prendreCelebration() => _file.isEmpty ? null : _file.removeAt(0);

  /// Événements de la liste qui n'ont pas encore été célébrés.
  List<Evenement> nouveaux(List<Evenement> evenements) =>
      evenements.where((e) => !_progres.celebrations.contains(e.cle)).toList();

  /// Célèbre les événements nouveaux et attribue les badges correspondants.
  Future<void> celebrer(List<Evenement> evenements, {String? prenom}) async {
    var change = false;
    for (final e in nouveaux(evenements)) {
      _progres.celebrations.add(e.cle);
      change = true;
      var titre = e.titre;
      if (e.idBadge != null && !_progres.badges.containsKey(e.idBadge)) {
        _progres.badges[e.idBadge!] = DateTime.now();
        titre = '$titre\n🏅 Nouveau badge !';
      }
      _file.add(Celebration(emoji: e.emoji, titre: titre, message: e.message));
    }
    if (change) await _sauver();
  }

  // ------------------------------------------------------------- Défis

  /// Défis choisis pour la semaine de [date].
  List<Defi> defisDeLaSemaine(DateTime date) => [
    for (final id in (_progres.defis[RecompensesService.cleSemaine(date)] ?? const {}).keys)
      ?Defi.depuisNom(id), // ignoré si le défi n'existe plus
  ];

  Future<void> choisirDefi(DateTime date, Defi defi) async {
    final semaine = _progres.defis.putIfAbsent(RecompensesService.cleSemaine(date), () => {});
    if (semaine.length >= RecompensesService.defisMax || semaine.containsKey(defi.name)) return;
    semaine[defi.name] = 0;
    await _sauver();
  }

  Future<void> retirerDefi(DateTime date, Defi defi) async {
    _progres.defis[RecompensesService.cleSemaine(date)]?.remove(defi.name);
    await _sauver();
  }

  /// Pour les défis notés à la main : +1 ou −1.
  Future<void> ajusterDefi(DateTime date, Defi defi, int delta) async {
    final semaine = _progres.defis[RecompensesService.cleSemaine(date)];
    if (semaine == null || !semaine.containsKey(defi.name)) return;
    semaine[defi.name] = (semaine[defi.name]! + delta).clamp(0, defi.cible);
    await _sauver();
  }

  // --------------------------------------------------------- Victoires

  Future<void> ajouterVictoire(CategorieVictoire categorie, String? texte) async {
    _progres.victoires.insert(
      0,
      Victoire(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: DateTime.now(),
        categorie: categorie,
        texte: texte?.trim(),
      ),
    );
    // Chaque victoire mérite ses confettis.
    _file.add(
      Celebration(
        emoji: categorie.emoji,
        titre: 'Bravo pour cette victoire !',
        message: categorie.libelle,
      ),
    );
    await _sauver();
  }

  Future<void> supprimerVictoire(String id) async {
    _progres.victoires.removeWhere((v) => v.id == id);
    await _sauver();
  }

  // ------------------------------------------------------- Respiration

  Future<void> noterRespiration() async {
    _progres.respirations.add(DateTime.now());
    await _sauver();
  }

  /// Fin d'une séance guidée : confettis, et badge « Première séance »
  /// la première fois.
  Future<void> celebrerSeance(String nomSeance, int minutes) async {
    var titre = 'Séance « $nomSeance » terminée !';
    if (!_progres.badges.containsKey('premiereSeance')) {
      _progres.badges['premiereSeance'] = DateTime.now();
      titre = '$titre\n🏅 Nouveau badge !';
    }
    _file.add(
      Celebration(
        emoji: '🎉',
        titre: titre,
        message:
            '$minutes ${minutes > 1 ? 'minutes' : 'minute'} rien que pour toi. '
            'Ton corps te remercie 💗',
      ),
    );
    await _sauver();
  }

  /// Note le moment d'une fringale (bouton « J'ai une fringale »).
  /// Sert seulement aux constats du bilan : jamais à un reproche.
  Future<void> noterFringale() async {
    _progres.fringales.add(DateTime.now());
    await _sauver();
  }

  // ---------------------------------------------------- Idées du bilan

  /// Nombre maximum d'idées choisies pour une semaine.
  static const ideesMax = 2;

  /// Idées choisies pour la semaine qui commence le [lundi].
  List<String> ideesDe(DateTime lundi) =>
      List.unmodifiable(_progres.idees[cleDuJour(lundi)] ?? const []);

  /// Choisit (ou retire) une idée pour la semaine qui commence le [lundi].
  Future<void> basculerIdee(DateTime lundi, String idee) async {
    final liste = _progres.idees.putIfAbsent(cleDuJour(lundi), () => []);
    if (!liste.remove(idee)) {
      if (liste.length >= ideesMax) return;
      liste.add(idee);
    }
    await _sauver();
  }

  // ------------------------------------------------- Bilan du soir

  static String _cleIdeesDuJour(DateTime date) => 'demain:${cleDuJour(date)}';

  /// Idées choisies la veille (« journée compliquée ») pour la journée [date].
  List<String> ideesDuJour(DateTime date) =>
      List.unmodifiable(_progres.idees[_cleIdeesDuJour(date)] ?? const []);

  /// Choisit (ou retire) une idée pour la journée [date] (2 au plus).
  Future<void> basculerIdeeDuJour(DateTime date, String idee) async {
    final liste = _progres.idees.putIfAbsent(_cleIdeesDuJour(date), () => []);
    if (!liste.remove(idee)) {
      if (liste.length >= ideesMax) return;
      liste.add(idee);
    }
    await _sauver();
  }

  /// Vrai si le bilan du soir de [date] a déjà été ouvert.
  bool bilanSoirVu(DateTime date) => _progres.celebrations.contains('bilanSoir:${cleDuJour(date)}');

  Future<void> marquerBilanSoirVu(DateTime date) async {
    if (_progres.celebrations.add('bilanSoir:${cleDuJour(date)}')) await _sauver();
  }

  Future<void> _sauver() async {
    notifyListeners();
    await _stockage.enregistrerProgres(_progres);
  }
}
