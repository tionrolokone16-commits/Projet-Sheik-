import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/calendrier_onglet_screen.dart';
import 'package:premiere_app/services/recommandations_service.dart';
import 'package:provider/provider.dart';

import 'outils.dart';

/// Recommandations de fin de journée, une fois la journée complète.
void main() {
  RepasPhoto repas(Repas moment, {int h = 13, Portions portions = Portions.equilibre}) =>
      RepasPhoto(
        id: '${moment.name}-$h',
        date: DateTime(2026, 11, 20, h),
        repas: moment,
        portions: portions,
        nomPlat: 'Plat',
      );
  final troisRepas = [
    repas(Repas.petitDejeuner, h: 8),
    repas(Repas.dejeuner),
    repas(Repas.diner, h: 19),
  ];
  const journeeComplete = JourHabitudes(
    verres: 8,
    sommeilHeures: 8,
    ressentis: {Ressenti.energie: 4},
    pas: 7000,
  );

  List<String> titres({
    JourHabitudes jour = journeeComplete,
    List<RepasPhoto>? repasDuJour,
    int consomme = 1700,
    int? objectif = 1700,
  }) => RecommandationsService.calculer(
    jour: jour,
    repasDuJour: repasDuJour ?? troisRepas,
    activitesDuJour: const [],
    objectifVerres: 8,
    consomme: consomme,
    objectifKcal: objectif,
  ).map((r) => r.titre).toList();

  test('journée complète : 3 repas, eau, nuit et énergie notés', () {
    expect(
      RecommandationsService.manquantes(jour: journeeComplete, repasDuJour: troisRepas),
      isEmpty,
    );
    expect(
      RecommandationsService.manquantes(jour: const JourHabitudes(verres: 2), repasDuJour: []),
      [InfoManquante.repas, InfoManquante.nuit, InfoManquante.energie],
    );
  });

  test('tout va bien : objectif respecté et un mot positif', () {
    expect(titres(), ['Objectif respecté', 'Belle journée']);
  });

  test('au-dessus de l\'objectif, ou nettement en dessous', () {
    expect(titres(consomme: 2100).first, 'Retrouver l\'équilibre');
    expect(titres(consomme: 1000).first, 'Bien te nourrir');
  });

  test('assiettes : légumes, féculents, protéines', () {
    final riches = [
      for (final r in troisRepas)
        RepasPhoto(
          id: r.id,
          date: r.date,
          repas: r.repas,
          portions: Portions.normalisees(0.1, 0.1, 1),
          nomPlat: 'Riz',
        ),
    ];
    expect(
      titres(repasDuJour: riches),
      containsAll(['Plus de légumes', 'Équilibrer les féculents', 'Un peu plus de protéines']),
    );
  });

  test('petit-déjeuner absent, dîner tardif, eau, nuit, mouvement, stress, digestion', () {
    final t = titres(
      jour: const JourHabitudes(
        verres: 5,
        sommeilHeures: 6,
        ressentis: {Ressenti.energie: 3, Ressenti.stress: 5},
        digestion: 2,
      ),
      repasDuJour: [repas(Repas.dejeuner), repas(Repas.diner, h: 22), repas(Repas.collation)],
      objectif: null,
    );
    // Au plus 5 recommandations, les plus utiles d'abord.
    expect(t, [
      'Le petit-déjeuner',
      'Dîner un peu plus tôt',
      'Boire un peu plus',
      'Une nuit plus longue',
      'Bouger un peu',
    ]);
  });

  test('textes bienveillants', () {
    final recos = RecommandationsService.calculer(
      jour: const JourHabitudes(
        verres: 1,
        sommeilHeures: 4,
        ressentis: {Ressenti.energie: 1, Ressenti.stress: 5},
        digestion: 1,
      ),
      repasDuJour: troisRepas,
      activitesDuJour: [
        Activite(id: 'a', date: DateTime(2026, 11, 20), type: TypeActivite.marche, dureeMinutes: 5),
      ],
      objectifVerres: 8,
      consomme: 3000,
      objectifKcal: 1700,
    );
    for (final r in recos) {
      for (final mot in ['échec', 'faute', 'interdit', 'punition', 'mauvais']) {
        expect(r.texte.toLowerCase(), isNot(contains(mot)), reason: r.titre);
      }
    }
  });

  testWidgets('vue du jour : à compléter, puis les recommandations', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    final n = DateTime.now();
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => JourScreen(date: n)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recommandations_a_completer')), findsOneWidget);

    // On complète la journée depuis les données.
    final habitudes = tester.element(find.byType(JourScreen)).read<HabitudesProvider>();
    for (final (i, moment) in [Repas.petitDejeuner, Repas.dejeuner, Repas.diner].indexed) {
      await habitudes.ajouterRepas(
        date: DateTime(n.year, n.month, n.day, 8 + 5 * i),
        repas: moment,
        portions: Portions.equilibre,
        nomPlat: 'Garba',
      );
    }
    await habitudes.ajouterVerre(n);
    await habitudes.definirSommeil(n, 8);
    await habitudes.definirRessenti(n, Ressenti.energie, 4);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('carte_recommandations')), findsOneWidget);
    expect(find.text('Boire un peu plus'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // fin des animations
  });
}
