import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  Future<void> enregistrerProfil(Profil profil) => _ecrire(_cleProfil, jsonEncode(profil.toJson()));

  // ---------- Pesées ----------

  /// Renvoie les pesées triées de la plus ancienne à la plus récente.
  List<Pesee> chargerPesees() {
    final liste = _lireListe(_clePesees).map(Pesee.fromJson).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return liste;
  }

  Future<void> enregistrerPesees(List<Pesee> pesees) =>
      _ecrire(_clePesees, jsonEncode(pesees.map((p) => p.toJson()).toList()));

  // ---------- Activités ----------

  /// Renvoie les activités triées de la plus récente à la plus ancienne.
  List<Activite> chargerActivites() {
    final liste = _lireListe(_cleActivites).map(Activite.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return liste;
  }

  Future<void> enregistrerActivites(List<Activite> activites) =>
      _ecrire(_cleActivites, jsonEncode(activites.map((a) => a.toJson()).toList()));

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
      _ecrire(_cleJournal, jsonEncode(journal.map((cle, jour) => MapEntry(cle, jour.toJson()))));

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

  /// Enregistre les repas notés et renvoie la liste réellement enregistrée.
  ///
  /// Si l'appareil manque de place, les photos des repas les plus anciens
  /// sont retirées (les repas, eux, restent notés) jusqu'à ce que ça tienne.
  Future<List<RepasPhoto>> enregistrerRepasPhotos(List<RepasPhoto> repas) async {
    var liste = repas;
    var photosRetirees = false;
    while (true) {
      try {
        await _prefs.setString(_cleRepasPhotos, jsonEncode([for (final r in liste) r.toJson()]));
        break;
      } catch (_) {
        final allegee = _sansPhotosAnciennes(liste);
        if (allegee == null) {
          alerte.value = AlerteStockage(TypeAlerteStockage.echec);
          return liste;
        }
        liste = allegee;
        photosRetirees = true;
      }
    }
    if (photosRetirees) alerte.value = AlerteStockage(TypeAlerteStockage.photosRetirees);
    return liste;
  }

  /// Retire toutes les photos de repas (les repas restent notés).
  /// Renvoie la liste enregistrée et le nombre de photos retirées.
  Future<(List<RepasPhoto>, int)> retirerToutesLesPhotos() async {
    final repas = chargerRepasPhotos();
    final nombre = repas.where((r) => r.photoBase64 != null).length;
    final sansPhotos = [for (final r in repas) r.photoBase64 == null ? r : r.sansPhoto()];
    await _ecrire(_cleRepasPhotos, jsonEncode([for (final r in sansPhotos) r.toJson()]));
    return (sansPhotos, nombre);
  }

  /// Même liste, sans les photos de la moitié la plus ancienne des repas
  /// qui en ont une. `null` s'il n'y a plus aucune photo à retirer.
  static List<RepasPhoto>? _sansPhotosAnciennes(List<RepasPhoto> repas) {
    final avecPhoto = [
      for (final r in repas)
        if (r.photoBase64 != null) r,
    ]..sort((a, b) => a.date.compareTo(b.date)); // les plus anciens d'abord
    if (avecPhoto.isEmpty) return null;
    final aRetirer = {for (final r in avecPhoto.take((avecPhoto.length + 1) ~/ 2)) r.id};
    return [for (final r in repas) aRetirer.contains(r.id) ? r.sansPhoto() : r];
  }

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

  Future<void> enregistrerPlatsPerso(List<Plat> plats) =>
      _ecrire(_clePlatsPerso, jsonEncode([for (final p in plats) p.toJson()]));

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
      _ecrire(_cleProgres, jsonEncode(progres.toJson()));

  // ---------- Plan nutritionnel (texte importé) ----------

  /// Texte du plan importé, ou `null` s'il n'y en a pas.
  String? chargerPlanTexte() => _prefs.getString(_clePlan);

  Future<void> enregistrerPlanTexte(String? texte) =>
      texte == null ? _prefs.remove(_clePlan) : _ecrire(_clePlan, texte);

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
      _ecrire(_cleRappels, jsonEncode({'jour': jour, 'repas': repas.toList()}));

  // ---------- Réglages ----------

  Reglages chargerReglages() {
    final objet = _lireObjet(_cleReglages);
    return objet == null ? const Reglages() : Reglages.fromJson(objet);
  }

  Future<void> enregistrerReglages(Reglages reglages) =>
      _ecrire(_cleReglages, jsonEncode(reglages.toJson()));

  /// Toutes les clés utilisées par l'application.
  static const _toutesLesCles = [
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
  ];

  /// Efface toutes les données de l'application.
  Future<void> toutEffacer() async {
    for (final cle in _toutesLesCles) {
      await _prefs.remove(cle);
    }
  }

  // ---------- Place disponible ----------

  /// Place approximative offerte par le navigateur (Safari : environ 5 Mo).
  static const placeDisponibleOctets = 5 * 1024 * 1024;

  /// Signale un souci d'enregistrement (à afficher à l'utilisatrice).
  /// Une nouvelle alerte est un nouvel objet : chaque alerte est signalée.
  final alerte = ValueNotifier<AlerteStockage?>(null);

  /// Espace occupé par les données de l'application, en octets (estimation :
  /// le navigateur compte 2 octets par caractère).
  int espaceUtiliseOctets() {
    var caracteres = 0;
    for (final cle in _toutesLesCles) {
      final valeur = _prefs.getString(cle);
      if (valeur != null) caracteres += 'flutter.'.length + cle.length + valeur.length + 2;
    }
    return caracteres * 2;
  }

  // ---------- Outils internes ----------

  /// Écrit une valeur. Si l'appareil manque de place, on retire d'abord des
  /// photos de repas anciennes puis on réessaie. Si rien n'y fait, une alerte
  /// est émise au lieu de perdre la donnée en silence.
  Future<bool> _ecrire(String cle, String valeur) async {
    while (true) {
      try {
        await _prefs.setString(cle, valeur);
        return true;
      } catch (_) {
        if (cle == _cleRepasPhotos || !await _alleger()) {
          alerte.value = AlerteStockage(TypeAlerteStockage.echec);
          return false;
        }
      }
    }
  }

  /// Libère de la place en retirant les photos des repas les plus anciens.
  /// Renvoie `false` s'il n'y avait plus aucune photo à retirer.
  Future<bool> _alleger() async {
    final allegee = _sansPhotosAnciennes(chargerRepasPhotos());
    if (allegee == null) return false;
    try {
      await _prefs.setString(_cleRepasPhotos, jsonEncode([for (final r in allegee) r.toJson()]));
    } catch (_) {
      return false;
    }
    alerte.value = AlerteStockage(TypeAlerteStockage.photosRetirees);
    return true;
  }

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

/// Type de souci d'enregistrement.
enum TypeAlerteStockage {
  /// Des photos de repas anciennes ont été retirées pour faire de la place.
  photosRetirees,

  /// Malgré tout, la dernière modification n'a pas pu être enregistrée.
  echec,
}

/// Souci d'enregistrement à signaler, avec un message doux.
class AlerteStockage {
  AlerteStockage(this.type);
  final TypeAlerteStockage type;

  String get message => switch (type) {
    TypeAlerteStockage.photosRetirees =>
      '📸 Ton appareil manquait de place : les photos des repas les plus '
          'anciens ont été retirées. Les repas, eux, restent notés.',
    TypeAlerteStockage.echec =>
      '⚠️ Ton appareil manque de place : la dernière modification n\'a pas pu '
          'être enregistrée. Tu peux libérer de la place dans Réglages → Mes données.',
  };
}
