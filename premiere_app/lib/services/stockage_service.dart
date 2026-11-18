import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activite.dart';
import '../models/jour_habitudes.dart';
import '../models/pesee.dart';
import '../models/plat.dart';
import '../models/profil.dart';
import '../models/progres.dart';
import '../models/reglages.dart';
import '../models/repas_photo.dart';

/// Lecture et écriture des données sur l'appareil (shared_preferences).
///
/// Chaque type de donnée est enregistré en JSON sous sa propre clé.
/// Sur le web, les données sont conservées dans le navigateur.
class StockageService {
  StockageService(this._prefs);

  final SharedPreferences _prefs;

  // Clés de stockage (préfixées pour éviter tout conflit).
  static const _cleProfil = 'forme_douce.profil';
  static const _clePesees = 'forme_douce.pesees';
  static const _cleActivites = 'forme_douce.activites';
  static const _cleJournal = 'forme_douce.journal';
  static const _cleReglages = 'forme_douce.reglages';
  static const _cleProgres = 'forme_douce.progres';
  static const _cleRepasPhotos = 'forme_douce.repas_photos';
  static const _clePlan = 'forme_douce.plan';
  static const _clePlatsPerso = 'forme_douce.plats_perso';
  static const _cleRappels = 'forme_douce.rappels';

  /// Crée le service une fois shared_preferences prêt.
  static Future<StockageService> initialiser() async =>
      StockageService(await SharedPreferences.getInstance());

  // ---------- Profil ----------

  /// Renvoie le profil enregistré, ou `null` au premier lancement.
  Profil? chargerProfil() {
    final objet = _lireObjet(_cleProfil);
    return objet == null ? null : Profil.fromJson(objet);
  }

  Future<void> enregistrerProfil(Profil profil) =>
      _prefs.setString(_cleProfil, jsonEncode(profil.toJson()));

  // ---------- Pesées ----------

  /// Renvoie les pesées triées de la plus ancienne à la plus récente.
  List<Pesee> chargerPesees() {
    final liste = _lireListe(_clePesees).map(Pesee.fromJson).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return liste;
  }

  Future<void> enregistrerPesees(List<Pesee> pesees) => _prefs.setString(
      _clePesees, jsonEncode(pesees.map((p) => p.toJson()).toList()));

  // ---------- Activités ----------

  /// Renvoie les activités triées de la plus récente à la plus ancienne.
  List<Activite> chargerActivites() {
    final liste = _lireListe(_cleActivites).map(Activite.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return liste;
  }

  Future<void> enregistrerActivites(List<Activite> activites) =>
      _prefs.setString(_cleActivites,
          jsonEncode(activites.map((a) => a.toJson()).toList()));

  // ---------- Journal des habitudes ----------

  /// Habitudes de chaque journée (eau, sommeil, repas, ressentis, note),
  /// indexées par date « aaaa-mm-jj ».
  Map<String, JourHabitudes> chargerJournal() {
    final objet = _lireObjet(_cleJournal) ?? {};
    final journal = <String, JourHabitudes>{};
    objet.forEach((cle, valeur) {
      try {
        journal[cle] = JourHabitudes.fromJson(valeur as Map<String, dynamic>);
      } catch (_) {
        // Journée illisible : on l'ignore plutôt que de tout perdre.
      }
    });
    return journal;
  }

  Future<void> enregistrerJournal(Map<String, JourHabitudes> journal) =>
      _prefs.setString(_cleJournal,
          jsonEncode(journal.map((cle, jour) => MapEntry(cle, jour.toJson()))));

  // ---------- Repas photographiés ----------

  /// Repas notés avec l'assiette, du plus récent au plus ancien.
  List<RepasPhoto> chargerRepasPhotos() {
    final liste = <RepasPhoto>[];
    for (final objet in _lireListe(_cleRepasPhotos)) {
      try {
        liste.add(RepasPhoto.fromJson(objet));
      } catch (_) {
        // Repas illisible : ignoré.
      }
    }
    return liste..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> enregistrerRepasPhotos(List<RepasPhoto> repas) => _prefs.setString(
      _cleRepasPhotos, jsonEncode([for (final r in repas) r.toJson()]));

  // ---------- Plats personnels ----------

  List<Plat> chargerPlatsPerso() {
    final liste = <Plat>[];
    for (final objet in _lireListe(_clePlatsPerso)) {
      try {
        liste.add(Plat.fromJson(objet));
      } catch (_) {
        // Plat illisible : ignoré.
      }
    }
    return liste;
  }

  Future<void> enregistrerPlatsPerso(List<Plat> plats) => _prefs.setString(
      _clePlatsPerso, jsonEncode([for (final p in plats) p.toJson()]));

  // ---------- Récompenses (badges, défis, victoires) ----------

  Progres chargerProgres() {
    final objet = _lireObjet(_cleProgres);
    if (objet == null) return Progres();
    try {
      return Progres.fromJson(objet);
    } catch (_) {
      return Progres(); // Données abîmées : on repart de zéro.
    }
  }

  Future<void> enregistrerProgres(Progres progres) =>
      _prefs.setString(_cleProgres, jsonEncode(progres.toJson()));

  // ---------- Plan nutritionnel (texte importé) ----------

  /// Texte du plan importé, ou `null` s'il n'y en a pas.
  String? chargerPlanTexte() => _prefs.getString(_clePlan);

  Future<void> enregistrerPlanTexte(String? texte) =>
      texte == null ? _prefs.remove(_clePlan) : _prefs.setString(_clePlan, texte);

  // ---------- Rappels mis de côté (« Plus tard ») ----------

  /// Jour (« aaaa-mm-jj ») et repas dont le rappel a été mis de côté ce jour-là.
  (String, Set<String>) chargerRappelsMisDeCote() {
    final objet = _lireObjet(_cleRappels);
    if (objet == null) return ('', <String>{});
    return (
      objet['jour'] as String? ?? '',
      {...(objet['repas'] as List? ?? const []).cast<String>()},
    );
  }

  Future<void> enregistrerRappelsMisDeCote(String jour, Set<String> repas) =>
      _prefs.setString(_cleRappels, jsonEncode({'jour': jour, 'repas': repas.toList()}));

  // ---------- Réglages ----------

  Reglages chargerReglages() {
    final objet = _lireObjet(_cleReglages);
    return objet == null ? const Reglages() : Reglages.fromJson(objet);
  }

  Future<void> enregistrerReglages(Reglages reglages) =>
      _prefs.setString(_cleReglages, jsonEncode(reglages.toJson()));

  /// Efface toutes les données de l'application.
  Future<void> toutEffacer() async {
    for (final cle in [
      _cleProfil,
      _clePesees,
      _cleActivites,
      _cleJournal,
      _cleReglages,
      _cleProgres,
      _cleRepasPhotos,
      _clePlan,
      _clePlatsPerso,
      _cleRappels,
    ]) {
      await _prefs.remove(cle);
    }
  }

  // ---------- Outils internes ----------

  /// Lit un objet JSON ; renvoie `null` s'il est absent ou illisible.
  Map<String, dynamic>? _lireObjet(String cle) {
    final texte = _prefs.getString(cle);
    if (texte == null) return null;
    try {
      return jsonDecode(texte) as Map<String, dynamic>;
    } catch (_) {
      return null; // Données abîmées : on repart de zéro plutôt que planter.
    }
  }

  /// Lit une liste d'objets JSON ; renvoie une liste vide en cas de souci.
  List<Map<String, dynamic>> _lireListe(String cle) {
    final texte = _prefs.getString(cle);
    if (texte == null) return [];
    try {
      return (jsonDecode(texte) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

/// Transforme une date en clé « aaaa-mm-jj » (utilisée pour le journal).
String cleDuJour(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
