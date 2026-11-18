import 'package:flutter/foundation.dart';

import '../models/pesee.dart';
import '../services/stockage_service.dart';

/// Gère la liste des pesées (triées de la plus ancienne à la plus récente).
class PoidsProvider extends ChangeNotifier {
  PoidsProvider(this._stockage) : _pesees = _stockage.chargerPesees();

  final StockageService _stockage;
  final List<Pesee> _pesees;

  List<Pesee> get pesees => List.unmodifiable(_pesees);

  /// Pesée la plus récente, ou `null` s'il n'y en a pas encore.
  Pesee? get derniere => _pesees.isEmpty ? null : _pesees.last;

  /// Pesée juste avant la plus récente (pour calculer la variation).
  Pesee? get avantDerniere =>
      _pesees.length < 2 ? null : _pesees[_pesees.length - 2];

  /// Ajoute une pesée. Une seule pesée par jour : si une pesée existe déjà
  /// à cette date, elle est remplacée.
  Future<void> ajouter(DateTime date, double poidsKg) async {
    final jour = DateTime(date.year, date.month, date.day);
    _pesees
      ..removeWhere((p) => _memeJour(p.date, jour))
      ..add(Pesee(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: jour,
        poidsKg: poidsKg,
      ))
      ..sort((a, b) => a.date.compareTo(b.date));
    await _sauver();
  }

  /// Supprime une pesée et la renvoie (pour pouvoir l'annuler).
  Future<Pesee?> supprimer(String id) async {
    final index = _pesees.indexWhere((p) => p.id == id);
    if (index < 0) return null;
    final pesee = _pesees.removeAt(index);
    await _sauver();
    return pesee;
  }

  /// Remet une pesée supprimée (bouton « Annuler »).
  Future<void> restaurer(Pesee pesee) async {
    _pesees
      ..removeWhere((p) => _memeJour(p.date, pesee.date))
      ..add(pesee)
      ..sort((a, b) => a.date.compareTo(b.date));
    await _sauver();
  }

  Future<void> _sauver() async {
    notifyListeners();
    await _stockage.enregistrerPesees(_pesees);
  }

  static bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
