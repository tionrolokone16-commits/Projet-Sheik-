import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/activite.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/progres.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/bilan_screen.dart';
import 'package:premiere_app/services/bilan_service.dart';
import 'package:premiere_app/widgets/graphique_semaine.dart';

import 'outils.dart';

/// Vue semaine : graphique des habitudes, constat petit-déjeuner / fringales,
/// partage et bascule Mois | Semaine dans le calendrier.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));
  final lundi = DateTime(2026, 11, 16);
  DateTime jour(int i, [int h = 12]) => DateTime(2026, 11, 16 + i, h);

  BilanSemaine calculer(
    Map<String, JourHabitudes> journal, {
    List<DateTime> fringales = const [],
  }) => BilanService.calculer(
    lundi: lundi,
    journal: journal,
    activites: [Activite(id: '1', date: jour(2), type: TypeActivite.marche, dureeMinutes: 30)],
    repasPhotos: const [],
    progres: Progres(fringales: [...fringales]),
    objectifVerres: 8,
  );

  test('habitudes jour par jour, du lundi au dimanche', () {
    final bilan = calculer({
      '2026-11-16': const JourHabitudes(verres: 8, sommeilHeures: 8),
      '2026-11-18': JourHabitudes(verres: 8, repas: Repas.principaux),
    });
    // Lundi : eau + sommeil ; mercredi : eau + repas + mouvement (la marche).
    expect(bilan.habitudesParJour, [2, 0, 3, 0, 0, 0, 0]);
  });

  test('constat : fringales plus fréquentes les jours sans petit-déjeuner', () {
    const avecPetitDej = JourHabitudes(repas: {Repas.petitDejeuner});
    const sansPetitDej = JourHabitudes(verres: 2);
    final bilan = calculer(
      {
        '2026-11-16': avecPetitDej,
        '2026-11-17': avecPetitDej,
        '2026-11-18': avecPetitDej,
        '2026-11-19': sansPetitDej,
        '2026-11-20': sansPetitDej,
      },
      fringales: [jour(3, 16), jour(4, 16), jour(4, 17)],
    );
    final textes = bilan.constats.map((c) => c.texte);
    expect(
      textes,
      contains('Les fringales sont arrivées plus souvent les jours sans petit-déjeuner.'),
    );
    expect(bilan.ideesSuggerees, contains(IdeeSemaine.prepPetitDej));
  });

  test('pas de constat petit-déjeuner quand les fringales sont réparties', () {
    const avecPetitDej = JourHabitudes(repas: {Repas.petitDejeuner});
    const sansPetitDej = JourHabitudes(verres: 2);
    final bilan = calculer(
      {
        '2026-11-16': avecPetitDej,
        '2026-11-17': avecPetitDej,
        '2026-11-19': sansPetitDej,
        '2026-11-20': sansPetitDej,
      },
      fringales: [jour(0, 11), jour(3, 11)],
    );
    expect(bilan.constats.map((c) => c.texte).join(), isNot(contains('sans petit-déjeuner')));
  });

  test('le résumé partagé contient les habitudes jour par jour', () {
    final bilan = calculer({'2026-11-16': const JourHabitudes(verres: 8)});
    final texte = BilanService.texteAPartager(bilan: bilan, prenom: '', ideesChoisies: const []);
    expect(texte, contains('Habitudes prises en soin (sur 4) : lun. 1 · mar. 0 · mer. 1'));
  });

  testWidgets('calendrier : la vue Semaine montre le graphique et le partage', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await HabitudesProvider(stockage).ajouterVerre(DateTime.now());
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendrier'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Semaine'));
    await tester.pumpAndSettle();
    expect(find.byType(VueSemaine), findsOneWidget);
    expect(find.byType(GraphiqueSemaine), findsOneWidget);

    final partage = find.byKey(const Key('bouton_partager_bilan'));
    await tester.scrollUntilVisible(
      partage,
      300,
      scrollable: find
          .descendant(of: find.byType(VueSemaine), matching: find.byType(Scrollable))
          .first,
    );
    expect(partage, findsOneWidget);

    // Retour au mois.
    await tester.tap(find.text('Mois'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('titre_mois')), findsOneWidget);
  });

  test('le résumé partagé contient les calories de la semaine (jours notés seulement)', () {
    final bilan = calculer({'2026-11-16': const JourHabitudes(verres: 8)});
    final texte = BilanService.texteAPartager(
      bilan: bilan,
      prenom: '',
      ideesChoisies: const [],
      kcalParJour: [1600, null, 1800, null, null, null, null],
      objectifKcal: 1700,
    );
    expect(texte, contains('CALORIES (ESTIMATIONS)'));
    expect(
      texte,
      contains('Moyenne consommée : ≈ 1700 kcal par jour (sur 2 jours avec repas notés)'),
    );
    expect(texte, contains('Objectif de l\'appli : ≈ 1700 kcal par jour'));
    // Sans repas notés : pas de section calories.
    expect(
      BilanService.texteAPartager(bilan: bilan, prenom: '', ideesChoisies: const []),
      isNot(contains('CALORIES')),
    );
  });
}
