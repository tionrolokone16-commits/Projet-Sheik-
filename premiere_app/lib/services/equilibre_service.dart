import '../models/activite.dart';
import '../models/exercice.dart';
import 'depense_service.dart';
import 'exercices_service.dart';

/// Une idée pour retrouver l'équilibre : une activité, sa durée et ses calories.
typedef IdeeEquilibre = ({TypeActivite type, int minutes, int kcal});

/// Ce qui est proposé quand les calories du jour dépassent l'objectif.
class Equilibre {
  const Equilibre({
    required this.excedent,
    required this.aBruler,
    required this.repos,
    required this.idees,
    required this.seance,
  });

  /// Calories au-dessus de l'objectif (après le mouvement déjà fait).
  final int excedent;

  /// Calories proposées à brûler aujourd'hui (plafonnées).
  final int aBruler;

  /// Vrai si le corps a plutôt besoin de repos (énergie très basse, nuit courte).
  final bool repos;

  /// Idées d'activités converties en durées.
  final List<IdeeEquilibre> idees;

  /// Séance guidée proposée (selon l'énergie du jour).
  final Seance? seance;

  bool get plafonne => aBruler < excedent;
}

/// Règles de « Retrouver l'équilibre » : les séances ne sont proposées que
/// lorsque les calories consommées dépassent l'objectif du jour.
class EquilibreService {
  EquilibreService._();

  /// Au plus ≈ 300 kcal proposées par jour.
  static const plafondKcal = 300;

  /// Au plus 60 minutes pour une activité.
  static const plafondMinutes = 60;

  /// Sous ces seuils, on propose du repos plutôt que du sport.
  static const energieMinimum = 2;
  static const sommeilMinimumHeures = 5.0;

  /// Activités proposées, de la plus douce à la plus tonique.
  static const typesProposes = [TypeActivite.marche, TypeActivite.danse, TypeActivite.velo];

  /// `null` si les calories du jour restent dans l'objectif.
  static Equilibre? calculer({
    required int consomme,
    required int objectif,
    required int mouvementDuJour,
    required double poidsKg,
    int? energie,
    double? sommeilHeures,
  }) {
    final excedent = consomme - objectif - mouvementDuJour;
    if (excedent <= 0) return null;
    final repos =
        (energie != null && energie <= energieMinimum) ||
        (sommeilHeures != null && sommeilHeures < sommeilMinimumHeures);
    final aBruler = excedent < plafondKcal ? excedent : plafondKcal;

    final idees = <IdeeEquilibre>[];
    if (!repos) {
      for (final type in typesProposes) {
        final parMinute = DepenseService.kcalActivite(type, 60, poidsKg) / 60;
        if (parMinute <= 0) continue;
        var minutes = (aBruler / parMinute / 5).ceil() * 5; // arrondi aux 5 minutes
        if (minutes > plafondMinutes) minutes = plafondMinutes;
        if (minutes < 5) minutes = 5;
        idees.add((
          type: type,
          minutes: minutes,
          kcal: DepenseService.kcalActivite(type, minutes, poidsKg),
        ));
      }
    }
    return Equilibre(
      excedent: excedent,
      aBruler: aBruler,
      repos: repos,
      idees: idees,
      seance: repos
          ? null
          : (ExercicesService.proposer(energie: energie ?? 3)?.seance ?? ExercicesService.reveil),
    );
  }

  /// Phrase d'introduction, toujours bienveillante.
  static String message(Equilibre e) {
    if (e.repos) {
      return 'Tu es au-dessus de ton objectif aujourd\'hui, mais ton corps a besoin de repos '
          '(énergie basse ou nuit courte). Prends soin de toi : demain est un autre jour 🌙';
    }
    final base =
        'Tu es ≈ ${e.excedent} kcal au-dessus de ton objectif aujourd\'hui. '
        'Si tu en as envie, voici de quoi retrouver l\'équilibre';
    return e.plafonne
        ? '$base (≈ ${e.aBruler} kcal au plus aujourd\'hui, le reste attendra demain) :'
        : '$base :';
  }
}
