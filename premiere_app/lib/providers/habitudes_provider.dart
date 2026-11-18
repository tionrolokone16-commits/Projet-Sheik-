import 'package:flutter/foundation.dart';

import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/recette.dart';
import '../models/repas_photo.dart';
import '../services/stockage_service.dart';

/// Gère le journal des habitudes (eau, sommeil, repas, ressentis),
/// la liste des activités physiques et les repas notés avec leur assiette.
class HabitudesProvider extends ChangeNotifier {
  HabitudesProvider(this._stockage)
      : _journal = _stockage.chargerJournal(),
        _activites = _stockage.chargerActivites(),
        _repasPhotos = _stockage.chargerRepasPhotos();

  final StockageService _stockage;
  final Map<String, JourHabitudes> _journal;

  /// Activités, de la plus récente à la plus ancienne.
  final List<Activite> _activites;

  /// Repas notés avec leur assiette, du plus récent au plus ancien.
  final List<RepasPhoto> _repasPhotos;

  /// Nombre de photos conservées : le navigateur n'offre qu'environ 5 Mo,
  /// les photos plus anciennes sont retirées (l'assiette, elle, est gardée).
  static const photosConservees = 20;

  // ------------------------------------------------------ Repas notés

  List<RepasPhoto> get repasPhotos => List.unmodifiable(_repasPhotos);

  List<RepasPhoto> repasPhotosDu(DateTime date) {
    final cle = cleDuJour(date);
    return _repasPhotos.where((r) => cleDuJour(r.date) == cle).toList();
  }

  /// Enregistre un repas et le coche dans le journal du jour.
  Future<void> ajouterRepasPhoto({
    required DateTime date,
    required Repas repas,
    required Portions portions,
    String? photoBase64,
  }) async {
    _repasPhotos
      ..insert(
        0,
        RepasPhoto(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          date: date,
          repas: repas,
          portions: portions,
          photoBase64: photoBase64,
        ),
      )
      ..sort((a, b) => b.date.compareTo(a.date));
    // On ne garde que les photos les plus récentes.
    var photos = 0;
    for (var i = 0; i < _repasPhotos.length; i++) {
      if (_repasPhotos[i].photoBase64 == null) continue;
      photos++;
      if (photos > photosConservees) _repasPhotos[i] = _repasPhotos[i].sansPhoto();
    }
    await _stockage.enregistrerRepasPhotos(_repasPhotos);
    // Coche le repas dans le journal (sans le décocher s'il l'est déjà).
    if (!jour(date).repas.contains(repas)) {
      await basculerRepas(date, repas);
    } else {
      notifyListeners();
    }
  }

  Future<RepasPhoto?> supprimerRepasPhoto(String id) async {
    final index = _repasPhotos.indexWhere((r) => r.id == id);
    if (index < 0) return null;
    final supprime = _repasPhotos.removeAt(index);
    notifyListeners();
    await _stockage.enregistrerRepasPhotos(_repasPhotos);
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

  Future<void> definirSommeil(DateTime date, double? heures) => _modifier(
      date, (j) => j.copyWith(sommeilHeures: heures, effacerSommeil: heures == null));

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

  Future<void> _modifier(
      DateTime date, JourHabitudes Function(JourHabitudes) changement) async {
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
      ..add(Activite(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: date,
        type: type,
        dureeMinutes: dureeMinutes,
        note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      ))
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
}
