import 'package:flutter/foundation.dart';

import '../models/activite.dart';
import '../models/ingredient.dart';
import '../models/jour_habitudes.dart';
import '../models/plat.dart';
import '../models/recette.dart';
import '../models/repas_photo.dart';
import '../services/calories_service.dart';
import '../services/ingredients_service.dart';
import '../services/plats_service.dart';
import '../services/stockage_service.dart';

/// Gère le journal des habitudes (eau, sommeil, repas, ressentis),
/// la liste des activités physiques et les repas notés avec leur assiette.
class HabitudesProvider extends ChangeNotifier {
  HabitudesProvider(this._stockage)
    : _journal = _stockage.chargerJournal(),
      _activites = _stockage.chargerActivites(),
      _repasPhotos = _stockage.chargerRepasPhotos(),
      _platsPerso = _stockage.chargerPlatsPerso() {
    // Si des photos ont été retirées pour faire de la place, on se resynchronise.
    _stockage.alerte.addListener(_surAlerteStockage);
  }

  final StockageService _stockage;
  final Map<String, JourHabitudes> _journal;

  /// Activités, de la plus récente à la plus ancienne.
  final List<Activite> _activites;

  /// Repas notés avec leur assiette, du plus récent au plus ancien.
  final List<RepasPhoto> _repasPhotos;

  /// Plats ajoutés par l'utilisatrice.
  final List<Plat> _platsPerso;

  /// Nombre de photos conservées : le navigateur n'offre qu'environ 5 Mo,
  /// les photos plus anciennes sont retirées (l'assiette, elle, est gardée).
  static const photosConservees = 20;

  // ------------------------------------------------------ Repas notés

  List<RepasPhoto> get repasPhotos => List.unmodifiable(_repasPhotos);

  List<RepasPhoto> repasPhotosDu(DateTime date) {
    final cle = cleDuJour(date);
    return _repasPhotos.where((r) => cleDuJour(r.date) == cle).toList();
  }

  /// Enregistre un repas dans le journal des repas, et coche ce repas
  /// dans les habitudes du jour. Renvoie le repas créé.
  Future<RepasPhoto> ajouterRepas({
    required DateTime date,
    required Repas repas,
    required Portions portions,
    String? photoBase64,
    String? nomPlat,
    String? emojiPlat,
    TaillePortion taille = TaillePortion.moyenne,
    Map<RessentiRepas, int> ressentis = const {},
    int? kcalManuel,
    List<Composant> composition = const [],
  }) async {
    final nouveau = RepasPhoto(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: date,
      repas: repas,
      portions: portions,
      photoBase64: photoBase64,
      nomPlat: nomPlat,
      emojiPlat: emojiPlat,
      taille: taille,
      ressentis: ressentis,
      kcalManuel: kcalManuel,
      composition: composition,
    );
    _repasPhotos
      ..insert(0, nouveau)
      ..sort((a, b) => b.date.compareTo(a.date));
    // On ne garde que les photos les plus récentes.
    var photos = 0;
    for (var i = 0; i < _repasPhotos.length; i++) {
      if (_repasPhotos[i].photoBase64 == null) continue;
      photos++;
      if (photos > photosConservees) _repasPhotos[i] = _repasPhotos[i].sansPhoto();
    }
    _remplacerRepas(await _stockage.enregistrerRepasPhotos(_repasPhotos));
    // Coche le repas dans le journal (sans le décocher s'il l'est déjà).
    if (!jour(date).repas.contains(repas)) {
      await basculerRepas(date, repas);
    } else {
      notifyListeners();
    }
    return nouveau;
  }

  /// Plats notés le plus souvent ces 60 derniers jours (au moins 2 fois),
  /// du plus fréquent au moins fréquent. Chaque plat est représenté par
  /// sa note la plus récente.
  List<RepasPhoto> platsFavoris({int nombre = 6, DateTime? maintenant}) {
    final limite = (maintenant ?? DateTime.now()).subtract(const Duration(days: 60));
    final compte = <String, int>{};
    final modele = <String, RepasPhoto>{};
    for (final r in _repasPhotos) {
      if (r.nomPlat == null || r.date.isBefore(limite)) continue;
      final cle = r.nomPlat!.trim().toLowerCase();
      compte[cle] = (compte[cle] ?? 0) + 1;
      modele.putIfAbsent(cle, () => r); // liste triée du plus récent au plus ancien
    }
    final cles = compte.keys.where((c) => compte[c]! >= 2).toList()
      ..sort((a, b) {
        final ecart = compte[b]!.compareTo(compte[a]!);
        return ecart != 0 ? ecart : modele[b]!.date.compareTo(modele[a]!.date);
      });
    return [for (final c in cles.take(nombre)) modele[c]!];
  }

  /// Le même repas (petit-déjeuner, déjeuner…) noté la veille de [date], s'il existe.
  RepasPhoto? memeRepasVeille(DateTime date, Repas moment) {
    final veille = DateTime(date.year, date.month, date.day - 1);
    for (final r in repasPhotosDu(veille)) {
      if (r.repas == moment && r.nomPlat != null) return r;
    }
    return null;
  }

  /// Note à nouveau un plat déjà noté (favori, « comme hier »), sans la photo
  /// ni les ressentis, qui appartiennent au repas d'origine.
  Future<RepasPhoto> renoterRepas(
    RepasPhoto modele, {
    required DateTime date,
    required Repas moment,
  }) => ajouterRepas(
    date: date,
    repas: moment,
    portions: modele.portions,
    nomPlat: modele.nomPlat,
    emojiPlat: modele.emojiPlat,
    taille: modele.taille,
    // Un plat composé garde ses ingrédients et ses calories.
    kcalManuel: modele.composition.isEmpty ? null : modele.kcalManuel,
    composition: modele.composition,
  );

  /// Remplace la composition d'un repas (ingrédients pesés) : ses calories
  /// et son assiette en découlent.
  Future<void> modifierComposition(
    String id,
    List<Composant> composition, {
    String? nomPlat,
  }) async {
    final index = _repasPhotos.indexWhere((r) => r.id == id);
    if (index < 0) return;
    _repasPhotos[index] = _repasPhotos[index].copyWith(
      composition: composition,
      kcalManuel: IngredientsService.kcal(composition),
      portions: IngredientsService.portions(composition),
      nomPlat: nomPlat,
    );
    notifyListeners();
    _remplacerRepas(await _stockage.enregistrerRepasPhotos(_repasPhotos));
  }

  /// Modifie un repas noté (moment, taille de portion, ressentis).
  Future<void> modifierRepas(
    String id, {
    Repas? repas,
    TaillePortion? taille,
    Map<RessentiRepas, int>? ressentis,
  }) async {
    final index = _repasPhotos.indexWhere((r) => r.id == id);
    if (index < 0) return;
    _repasPhotos[index] = _repasPhotos[index].copyWith(
      repas: repas,
      taille: taille,
      ressentis: ressentis,
    );
    notifyListeners();
    _remplacerRepas(await _stockage.enregistrerRepasPhotos(_repasPhotos));
  }

  // ------------------------------------------------------- Calories

  /// Calories estimées d'un repas (ou la valeur saisie à la main).
  int kcalRepas(RepasPhoto r) =>
      CaloriesService.kcalRepas(r, [..._platsPerso, ...PlatsService.catalogue]);

  /// Total des calories consommées un jour donné (repas notés).
  int kcalConsommees(DateTime date) => repasPhotosDu(date).fold<int>(0, (s, r) => s + kcalRepas(r));

  /// Corrige à la main les calories d'un repas (`null` : retour à l'estimation).
  Future<void> definirKcalRepas(String id, int? kcal) async {
    final index = _repasPhotos.indexWhere((r) => r.id == id);
    if (index < 0) return;
    _repasPhotos[index] = _repasPhotos[index].copyWith(kcalManuel: kcal, effacerKcal: kcal == null);
    notifyListeners();
    _remplacerRepas(await _stockage.enregistrerRepasPhotos(_repasPhotos));
  }

  RepasPhoto? repasParId(String id) {
    for (final r in _repasPhotos) {
      if (r.id == id) return r;
    }
    return null;
  }

  // ---------------------------------------------------- Plats personnels

  /// Plats ajoutés par l'utilisatrice à sa bibliothèque.
  List<Plat> get platsPerso => List.unmodifiable(_platsPerso);

  Future<Plat> ajouterPlatPerso({
    required String nom,
    required String emoji,
    required CategoriePlat categorie,
  }) async {
    final plat = Plat(
      id: 'perso_${DateTime.now().microsecondsSinceEpoch}',
      nom: nom.trim(),
      emoji: emoji,
      pays: PaysPlat.mesPlats,
      categorie: categorie,
      portions: PlatsService.estimerPortions(nom),
    );
    _platsPerso.add(plat);
    notifyListeners();
    await _stockage.enregistrerPlatsPerso(_platsPerso);
    return plat;
  }

  Future<void> supprimerPlatPerso(String id) async {
    _platsPerso.removeWhere((p) => p.id == id);
    notifyListeners();
    await _stockage.enregistrerPlatsPerso(_platsPerso);
  }

  Future<RepasPhoto?> supprimerRepasPhoto(String id) async {
    final index = _repasPhotos.indexWhere((r) => r.id == id);
    if (index < 0) return null;
    final supprime = _repasPhotos.removeAt(index);
    notifyListeners();
    _remplacerRepas(await _stockage.enregistrerRepasPhotos(_repasPhotos));
    return supprime;
  }

  // ------------------------------------------------------------ Journal

  /// Toutes les journées notées, indexées par « aaaa-mm-jj ».
  Map<String, JourHabitudes> get journal => Map.unmodifiable(_journal);

  /// Habitudes d'une journée (vide si rien n'a été noté).
  JourHabitudes jour(DateTime date) => _journal[cleDuJour(date)] ?? const JourHabitudes();

  Future<void> ajouterVerre(DateTime date) =>
      _modifier(date, (j) => j.copyWith(verres: j.verres + 1));

  Future<void> retirerVerre(DateTime date) =>
      _modifier(date, (j) => j.copyWith(verres: j.verres > 0 ? j.verres - 1 : 0));

  Future<void> definirSommeil(DateTime date, double? heures) =>
      _modifier(date, (j) => j.copyWith(sommeilHeures: heures, effacerSommeil: heures == null));

  /// Coche ou décoche un repas.
  Future<void> basculerRepas(DateTime date, Repas repas) => _modifier(date, (j) {
    final nouveaux = {...j.repas};
    if (!nouveaux.remove(repas)) nouveaux.add(repas);
    return j.copyWith(repas: nouveaux);
  });

  /// Note un ressenti de 1 à 5. Toucher à nouveau la même valeur l'efface.
  Future<void> definirRessenti(DateTime date, Ressenti ressenti, int valeur) =>
      _modifier(date, (j) {
        final nouveaux = {...j.ressentis};
        if (nouveaux[ressenti] == valeur) {
          nouveaux.remove(ressenti);
        } else {
          nouveaux[ressenti] = valeur;
        }
        return j.copyWith(ressentis: nouveaux);
      });

  Future<void> definirNote(DateTime date, String note) =>
      _modifier(date, (j) => j.copyWith(note: note));

  /// Coche ou décoche un jour de règles (suivi de cycle).
  Future<void> basculerRegles(DateTime date) =>
      _modifier(date, (j) => j.copyWith(regles: !j.regles));

  /// Note le nombre de pas (`null` l'efface).
  Future<void> definirPas(DateTime date, int? pas) =>
      _modifier(date, (j) => j.copyWith(pas: pas, effacerPas: pas == null));

  /// Note le confort digestif de 1 à 5. Toucher à nouveau la même valeur l'efface.
  Future<void> definirDigestion(DateTime date, int valeur) => _modifier(
    date,
    (j) =>
        j.digestion == valeur ? j.copyWith(effacerDigestion: true) : j.copyWith(digestion: valeur),
  );

  /// Coche ou décoche « séance faite ».
  Future<void> basculerSeanceFaite(DateTime date) =>
      _modifier(date, (j) => j.copyWith(seanceFaite: !j.seanceFaite));

  Future<void> _modifier(DateTime date, JourHabitudes Function(JourHabitudes) changement) async {
    final cle = cleDuJour(date);
    final nouveau = changement(_journal[cle] ?? const JourHabitudes());
    if (nouveau.estVide) {
      _journal.remove(cle); // On ne garde pas les journées vides.
    } else {
      _journal[cle] = nouveau;
    }
    notifyListeners();
    await _stockage.enregistrerJournal(_journal);
  }

  // ---------------------------------------------------------- Activités

  List<Activite> get activites => List.unmodifiable(_activites);

  /// Activité la plus récente, ou `null`.
  Activite? get derniereActivite => _activites.isEmpty ? null : _activites.first;

  /// Activités d'une journée donnée.
  List<Activite> activitesDu(DateTime date) {
    final cle = cleDuJour(date);
    return _activites.where((a) => cleDuJour(a.date) == cle).toList();
  }

  Future<void> ajouterActivite({
    required DateTime date,
    required TypeActivite type,
    required int dureeMinutes,
    String? note,
  }) async {
    _activites
      ..add(
        Activite(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: date,
          type: type,
          dureeMinutes: dureeMinutes,
          note: (note == null || note.trim().isEmpty) ? null : note.trim(),
        ),
      )
      ..sort((a, b) => b.date.compareTo(a.date));
    await _sauverActivites();
  }

  /// Supprime une activité et la renvoie (pour pouvoir l'annuler).
  Future<Activite?> supprimerActivite(String id) async {
    final index = _activites.indexWhere((a) => a.id == id);
    if (index < 0) return null;
    final activite = _activites.removeAt(index);
    await _sauverActivites();
    return activite;
  }

  Future<void> restaurerActivite(Activite activite) async {
    _activites
      ..add(activite)
      ..sort((a, b) => b.date.compareTo(a.date));
    await _sauverActivites();
  }

  Future<void> _sauverActivites() async {
    notifyListeners();
    await _stockage.enregistrerActivites(_activites);
  }

  // ------------------------------------------------- Place disponible

  /// Remplace la liste des repas par celle réellement enregistrée
  /// (des photos anciennes ont pu être retirées pour faire de la place).
  void _remplacerRepas(List<RepasPhoto> enregistres) {
    if (identical(enregistres, _repasPhotos)) return;
    _repasPhotos
      ..clear()
      ..addAll(enregistres)
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _surAlerteStockage() {
    if (_stockage.alerte.value?.type == TypeAlerteStockage.photosRetirees) {
      _remplacerRepas(_stockage.chargerRepasPhotos());
    }
  }

  /// Retire toutes les photos de repas (les repas restent notés).
  /// Renvoie le nombre de photos retirées.
  Future<int> retirerToutesLesPhotos() async {
    final (repas, nombre) = await _stockage.retirerToutesLesPhotos();
    _remplacerRepas(repas);
    return nombre;
  }

  @override
  void dispose() {
    _stockage.alerte.removeListener(_surAlerteStockage);
    super.dispose();
  }
}
