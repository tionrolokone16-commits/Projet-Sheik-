import 'package:flutter/foundation.dart';

import '../models/plan_nutrition.dart';
import '../services/plan_service.dart';
import '../services/stockage_service.dart';

/// Gère le plan nutritionnel importé (stocké uniquement sur l'appareil).
class PlanProvider extends ChangeNotifier {
  PlanProvider(this._stockage) {
    final texte = _stockage.chargerPlanTexte();
    if (texte != null) {
      try {
        _plan = PlanService.lire(texte);
      } on ErreurPlan {
        _plan = null; // Texte abîmé : on fait comme s'il n'y avait pas de plan.
      }
    }
  }

  final StockageService _stockage;
  PlanNutrition? _plan;

  /// Plan importé, ou `null`.
  PlanNutrition? get plan => _plan;

  bool get aUnPlan => _plan != null;

  /// Lit et enregistre le plan collé. Lève [ErreurPlan] si le texte est invalide
  /// (rien n'est alors modifié).
  Future<PlanNutrition> importer(String texte) async {
    final plan = PlanService.lire(texte);
    _plan = plan;
    notifyListeners();
    await _stockage.enregistrerPlanTexte(plan.texteSource);
    return plan;
  }

  Future<void> supprimer() async {
    _plan = null;
    notifyListeners();
    await _stockage.enregistrerPlanTexte(null);
  }

  /// Ingrédients de la liste que le plan conseille d'éviter (vide sans plan).
  List<String> aEviterParmi(List<String> ingredients) =>
      _plan == null ? const [] : PlanService.ingredientsAEviter(_plan!, ingredients);
}
