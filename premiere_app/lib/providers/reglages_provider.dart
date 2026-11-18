import 'package:material_ui/material_ui.dart';

import '../models/jour_habitudes.dart';
import '../models/reglages.dart';
import '../services/stockage_service.dart';

/// Gère les réglages (thème, objectif d'eau, affichage du poids, rappels).
class ReglagesProvider extends ChangeNotifier {
  ReglagesProvider(this._stockage) : _reglages = _stockage.chargerReglages() {
    final (jour, repas) = _stockage.chargerRappelsMisDeCote();
    _jourMisDeCote = jour;
    _misDeCote = {
      for (final nom in repas)
        for (final r in Repas.values)
          if (r.name == nom) r,
    };
  }

  final StockageService _stockage;
  Reglages _reglages;

  /// Rappels mis de côté (« Plus tard ») et le jour concerné.
  String _jourMisDeCote = '';
  Set<Repas> _misDeCote = {};

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

  /// Rappels mis de côté aujourd'hui (vide dès le lendemain).
  Set<Repas> rappelsMisDeCote(DateTime maintenant) =>
      _jourMisDeCote == cleDuJour(maintenant) ? Set.unmodifiable(_misDeCote) : const {};

  /// « Plus tard » : le rappel de ce repas ne revient pas avant demain.
  Future<void> mettreRappelDeCote(Repas repas, DateTime maintenant) async {
    final jour = cleDuJour(maintenant);
    if (_jourMisDeCote != jour) {
      _jourMisDeCote = jour;
      _misDeCote = {};
    }
    _misDeCote.add(repas);
    notifyListeners();
    await _stockage.enregistrerRappelsMisDeCote(jour, {for (final r in _misDeCote) r.name});
  }
}
