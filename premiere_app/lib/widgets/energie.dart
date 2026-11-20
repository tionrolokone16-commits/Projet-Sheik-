import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../services/calculs_service.dart';
import '../services/calories_service.dart';

/// Poids actuel : la dernière pesée, sinon le poids de départ du profil.
double? poidsActuel(BuildContext context) {
  final profil = context.watch<ProfilProvider>().profil;
  if (profil == null) return null;
  return context.watch<PoidsProvider>().derniere?.poidsKg ?? profil.poidsDepartKg;
}

/// Objectif calorique du jour, selon le poids visé et la dernière pesée
/// (`null` sans profil). Il se recalcule à chaque nouvelle pesée.
ObjectifCalorique? objectifActuel(BuildContext context) {
  final profil = context.watch<ProfilProvider>().profil;
  if (profil == null) return null;
  return CalculsService.objectifCalorique(profil, poidsActuelKg: poidsActuel(context));
}

/// « Reste ≈ 450 kcal » ou « ≈ 200 kcal au-dessus de ton objectif ».
String texteReste(int consomme, int objectif) {
  final ecart = objectif - consomme;
  return ecart >= 0
      ? 'Reste ${CaloriesService.formater(ecart)}'
      : '${CaloriesService.formater(-ecart)} au-dessus de ton objectif';
}
