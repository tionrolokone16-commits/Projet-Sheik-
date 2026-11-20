import 'package:flutter_test/flutter_test.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/services/equilibre_service.dart';
import 'package:premiere_app/services/exercices_service.dart';

/// « Retrouver l'équilibre » : séances seulement au-dessus de l'objectif du jour.
void main() {
  Equilibre? calculer({
    int consomme = 2000,
    int objectif = 1700,
    int mouvement = 0,
    int? energie,
    double? sommeil,
  }) => EquilibreService.calculer(
    consomme: consomme,
    objectif: objectif,
    mouvementDuJour: mouvement,
    poidsKg: 80,
    energie: energie,
    sommeilHeures: sommeil,
  );

  test('dans l\'objectif : rien n\'est proposé', () {
    expect(calculer(consomme: 1600), isNull);
    expect(calculer(consomme: 1700), isNull);
  });

  test('le mouvement déjà fait compte', () {
    expect(calculer(consomme: 1900, mouvement: 250), isNull);
    expect(calculer(consomme: 1900, mouvement: 100)!.excedent, 100);
  });

  test('au-dessus : des durées concrètes selon le poids', () {
    final e = calculer()!; // 300 kcal au-dessus
    expect(e.excedent, 300);
    expect(e.aBruler, 300);
    expect(e.repos, isFalse);
    final marche = e.idees.firstWhere((i) => i.type == TypeActivite.marche);
    // Marche à 80 kg : (3,5 − 1) × 80 / 60 ≈ 3,3 kcal par minute → 90 min, plafonnées à 60.
    expect(marche.minutes, EquilibreService.plafondMinutes);
    final danse = e.idees.firstWhere((i) => i.type == TypeActivite.danse);
    // Danse : (5 − 1) × 80 / 60 ≈ 5,3 kcal par minute → 60 min.
    expect(danse.minutes, 60);
    expect(danse.kcal, 320);
    expect(e.seance, isNotNull);
  });

  test('plafond : jamais plus de ≈ 300 kcal proposées dans la journée', () {
    final e = calculer(consomme: 3000)!;
    expect(e.excedent, 1300);
    expect(e.aBruler, EquilibreService.plafondKcal);
    expect(e.plafonne, isTrue);
    expect(EquilibreService.message(e), contains('le reste attendra demain'));
    for (final i in e.idees) {
      expect(i.minutes, lessThanOrEqualTo(EquilibreService.plafondMinutes));
    }
  });

  test('énergie très basse ou nuit courte : du repos, pas de sport', () {
    for (final e in [calculer(energie: 1)!, calculer(sommeil: 4)!]) {
      expect(e.repos, isTrue);
      expect(e.idees, isEmpty);
      expect(e.seance, isNull);
      expect(EquilibreService.message(e), contains('repos'));
    }
  });

  test('la séance guidée suit l\'énergie du jour', () {
    expect(calculer(energie: 5)!.seance, ExercicesService.seanceEnergie);
    expect(calculer(energie: 3)!.seance, ExercicesService.reveil);
  });

  test('textes bienveillants', () {
    for (final e in [calculer()!, calculer(consomme: 3000)!, calculer(energie: 1)!]) {
      final t = EquilibreService.message(e).toLowerCase();
      for (final mot in ['échec', 'faute', 'punition', 'interdit']) {
        expect(t, isNot(contains(mot)));
      }
    }
  });
}
