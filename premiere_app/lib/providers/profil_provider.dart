import 'package:flutter/foundation.dart';

import '../models/profil.dart';
import '../services/stockage_service.dart';

/// Gère le profil de l'utilisateur et prévient l'interface à chaque changement.
class ProfilProvider extends ChangeNotifier {
  ProfilProvider(this._stockage) : _profil = _stockage.chargerProfil();

  final StockageService _stockage;
  Profil? _profil;

  /// Profil actuel, ou `null` tant qu'il n'a pas été rempli.
  Profil? get profil => _profil;

  /// Vrai dès que le profil a été enregistré au moins une fois.
  bool get estComplet => _profil != null;

  Future<void> enregistrer(Profil profil) async {
    _profil = profil;
    notifyListeners();
    await _stockage.enregistrerProfil(profil);
  }
}
