import 'package:flutter_test/flutter_test.dart';
import 'package:premiere_app/models/profil.dart';
import 'package:premiere_app/services/calculs_service.dart';

/// Tests des calculs santé (IMC, Mifflin-St Jeor, plancher 1200 kcal).
void main() {
  const profil = Profil(
    prenom: 'Camille',
    age: 35,
    tailleCm: 165,
    poidsDepartKg: 80,
    poidsObjectifKg: 68,
    niveauActivite: NiveauActivite.modere,
    sexe: Sexe.femme,
  );

  test('IMC', () {
    expect(CalculsService.imc(80, 165), closeTo(29.38, 0.01));
  });

  test('objectif refusé si IMC < 18,5', () {
    expect(CalculsService.objectifAcceptable(48, 165), isFalse); // IMC ≈ 17,6
    expect(CalculsService.objectifAcceptable(55, 165), isTrue); // IMC ≈ 20,2
    expect(CalculsService.poidsObjectifMinimal(165), 50.4);
  });

  test('Mifflin-St Jeor', () {
    // 10×80 + 6,25×165 − 5×35 − 161 = 1495,25
    expect(
      CalculsService.metabolismeBase(poidsKg: 80, tailleCm: 165, age: 35, sexe: Sexe.femme),
      closeTo(1495.25, 0.01),
    );
  });

  test('perte visée de 0,5 kg/semaine', () {
    final r = CalculsService.objectifCalorique(profil);
    expect(r.perteHebdoKg, 0.5);
    expect(r.kcalParJour, (1495.25 * 1.55 - 550).round());
    expect(r.plancherApplique, isFalse);
  });

  test('jamais moins de 1200 kcal', () {
    final petit = profil.copyWith(
      tailleCm: 150,
      poidsDepartKg: 55,
      poidsObjectifKg: 50,
      age: 60,
      niveauActivite: NiveauActivite.sedentaire,
    );
    final r = CalculsService.objectifCalorique(petit);
    expect(r.kcalParJour, greaterThanOrEqualTo(1200));
    expect(r.plancherApplique, isTrue);
    expect(r.perteHebdoKg, lessThan(0.5));
  });

  test('objectif atteint : entretien', () {
    final r = CalculsService.objectifCalorique(profil, poidsActuelKg: 67);
    expect(r.perteHebdoKg, 0);
  });
}
