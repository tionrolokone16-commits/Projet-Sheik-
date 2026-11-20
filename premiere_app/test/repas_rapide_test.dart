import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/plat.dart';
import 'package:premiere_app/models/progres.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/ajouter_repas_screen.dart';
import 'package:premiere_app/services/recompenses_service.dart';
import 'package:premiere_app/services/stockage_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Noter ses repas plus facilement : favoris, « comme hier », semaine bien remplie.
void main() {
  final n = DateTime.now();
  DateTime ilYA(int jours, [int h = 13]) => DateTime(n.year, n.month, n.day - jours, h);

  Future<HabitudesProvider> noter(List<(int, String, Repas)> repas) async {
    final h = HabitudesProvider(await preparerStockage(avecProfil: true));
    for (final (jours, nom, moment) in repas) {
      await h.ajouterRepas(
        date: ilYA(jours),
        repas: moment,
        portions: Portions.equilibre,
        nomPlat: nom,
        emojiPlat: '🍲',
        taille: TaillePortion.grande,
        ressentis: const {RessentiRepas.plaisir: 5},
      );
    }
    return h;
  }

  test('favoris : les plats notés au moins 2 fois, les plus fréquents d\'abord', () async {
    final h = await noter([
      (1, 'Attiéké poisson', Repas.dejeuner),
      (2, 'attiéké poisson ', Repas.diner),
      (3, 'Attiéké poisson', Repas.dejeuner),
      (1, 'Alloco', Repas.diner),
      (4, 'Alloco', Repas.diner),
      (2, 'Garba', Repas.dejeuner), // une seule fois
      (80, 'Garba', Repas.dejeuner), // trop ancien
    ]);
    expect(h.platsFavoris().map((r) => r.nomPlat!.trim().toLowerCase()), [
      'attiéké poisson',
      'alloco',
    ]);
  });

  test('« comme hier » : le même moment de repas, la veille', () async {
    final h = await noter([(1, 'Garba', Repas.dejeuner), (1, 'Bouillie', Repas.petitDejeuner)]);
    expect(h.memeRepasVeille(n, Repas.dejeuner)?.nomPlat, 'Garba');
    expect(h.memeRepasVeille(n, Repas.diner), isNull);
  });

  test('noter à nouveau un plat : sans sa photo ni ses ressentis, et le repas est coché', () async {
    final h = await noter([(1, 'Garba', Repas.dejeuner)]);
    final modele = h.repasPhotos.first;
    final copie = await h.renoterRepas(modele, date: n, moment: Repas.dejeuner);
    expect(copie.nomPlat, 'Garba');
    expect(copie.taille, TaillePortion.grande);
    expect(copie.ressentis, isEmpty);
    expect(copie.photoBase64, isNull);
    expect(h.jour(n).repas, contains(Repas.dejeuner));
  });

  group('semaine bien remplie', () {
    final lundi = DateTime(2026, 11, 16);
    List<Evenement> evenements(List<int> joursNotes) => RecompensesService.evenements(
      journal: {
        for (final i in joursNotes)
          cleDuJour(DateTime(2026, 11, 16 + i)): const JourHabitudes(repas: {Repas.dejeuner}),
      },
      activites: const [],
      objectifVerres: 8,
      progres: Progres(),
      profil: null,
      pesees: const [],
      maintenant: DateTime(2026, 11, 21),
    );
    bool celebree(List<int> jours) =>
        evenements(jours).any((e) => e.cle == 'repasSemaine:${cleDuJour(lundi)}');

    test('5 jours notés, même avec des jours vides entre eux', () {
      expect(celebree([0, 2, 3, 4, 5]), isTrue);
    });

    test('4 jours : pas encore, et rien de négatif', () {
      expect(celebree([0, 1, 2, 3]), isFalse);
      for (final e in evenements([0, 1, 2, 3])) {
        expect(e.message.toLowerCase(), isNot(contains('manqu')));
      }
    });
  });

  testWidgets('« comme hier » note le repas en une touche', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await HabitudesProvider(stockage).ajouterRepas(
      date: ilYA(1),
      repas: Repas.dejeuner,
      portions: Portions.equilibre,
      nomPlat: 'Garba',
      emojiPlat: '🐟',
    );
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute(
            builder: (_) => AjouterRepasScreen(date: DateTime.now(), moment: Repas.dejeuner),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('Comme hier : Garba'), findsOneWidget);
    final habitudes = Provider.of<HabitudesProvider>(
      tester.element(find.byType(AjouterRepasScreen)),
      listen: false,
    );
    await tester.tap(find.byKey(const Key('comme_hier')));
    await tester.pumpAndSettle();

    expect(find.byType(AjouterRepasScreen), findsNothing);
    expect(habitudes.repasPhotosDu(DateTime.now()).single.nomPlat, 'Garba');
    expect(find.text('🐟 Garba noté, merci 💗'), findsOneWidget);
  });
}
