import 'package:material_ui/material_ui.dart';

import '../models/reglages.dart';
import '../services/stockage_service.dart';

/// Gère les réglages (thème, objectif d'eau, affichage du poids).
class ReglagesProvider extends ChangeNotifier {
  ReglagesProvider(this._stockage) : _reglages = _stockage.chargerReglages();

  final StockageService _stockage;
  Reglages _reglages;

  Reglages get reglages => _reglages;

  /// Thème à transmettre à MaterialApp.
  ThemeMode get themeMode => switch (_reglages.theme) {
        ThemeChoisi.clair => ThemeMode.light,
        ThemeChoisi.sombre => ThemeMode.dark,
        ThemeChoisi.systeme => ThemeMode.system,
      };

  Future<void> modifier(Reglages nouveaux) async {
    _reglages = nouveaux;
    notifyListeners();
    await _stockage.enregistrerReglages(nouveaux);
  }
}
