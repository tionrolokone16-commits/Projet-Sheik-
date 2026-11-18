import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/plan_nutrition.dart';
import 'package:premiere_app/providers/plan_provider.dart';
import 'package:premiere_app/screens/mon_plan_screen.dart';
import 'package:premiere_app/screens/recettes_screen.dart';
import 'package:premiere_app/services/plan_service.dart';
import 'package:premiere_app/services/recettes_service.dart';

import 'outils.dart';

/// Plan FICTIF pour les tests (aucune donnée réelle).
const _planExemple = '''
[[Kira's FAT · plan]]
# titre: Plan d'essai
# sous-titre: Exemple fictif
== Conseils
- Boire de l'eau entre les repas
== Petit-déjeuner
- Un fruit et un yaourt
== Menu de la semaine
Lundi | Riz + poisson | Salade + poulet
Mardi | Attiéké + poisson | Haricot vert + viande
Mercredi | Igname + poisson | Carotte + viande
Jeudi | Placali + poisson | Petit pois + poulet
Vendredi | Banane + poisson | Salade + viande
Samedi | Spaghetti + viande | Carotte + poulet
Dimanche | Cabato + poisson | Haricot vert + viande
== Aliments conseillés
## Fruits
- Orange, pomme
== Aliments à éviter
## Fruits
- Coco, avocat
## Préparations
- Préparations grasses et fritures
- Épices fortes (piment, poivre)
- Poissons gras : maquereau
''';

void main() {
  group('lecture du plan', () {
    test('sections, types, menu et titre', () {
      final plan = PlanService.lire(_planExemple);
      expect(plan.titre, 'Plan d\'essai');
      expect(plan.sousTitre, 'Exemple fictif');
      expect(plan.sections.map((s) => s.type), [
        TypeSection.liste,
        TypeSection.liste,
        TypeSection.menu,
        TypeSection.conseille,
        TypeSection.eviter,
      ]);
      expect(plan.menu.length, 7);
      expect(plan.menuDu(DateTime(2026, 11, 16))!.midi, 'Riz + poisson'); // un lundi
      expect(plan.menuDu(DateTime(2026, 11, 22))!.jour, 'Dimanche');
      expect(plan.petitDejeuner!.groupes.single.elements.single, 'Un fruit et un yaourt');
    });

    test('texte qui n\'est pas un plan : message clair', () {
      expect(() => PlanService.lire('Bonjour, voici ma liste de courses'),
          throwsA(isA<ErreurPlan>()));
      expect(() => PlanService.lire("[[Kira's FAT · plan]]\nrien"), throwsA(isA<ErreurPlan>()));
    });

    test('aliments à éviter : exemples précis, pas les catégories', () {
      final plan = PlanService.lire(_planExemple);
      final termes = PlanService.termesAEviter(plan);
      expect(termes, containsAll(['coco', 'avocat', 'friture', 'piment', 'poivre', 'maquereau']));
      // « Poissons gras » ne doit pas faire éviter tout le poisson.
      expect(PlanService.ingredientsAEviter(plan, ['poisson', 'riz']), isEmpty);
      expect(PlanService.ingredientsAEviter(plan, ['banane plantain', 'friture', 'piment']),
          ['friture', 'piment']);
    });

    test('normalisation : accents, majuscules, pluriels', () {
      expect(PlanService.normaliser('Fritures'), 'friture');
      expect(PlanService.normaliser('Œuf  Dur'), 'oeuf dur');
      expect(PlanService.normaliser('Épices'), 'epice');
    });
  });

  testWidgets('importer un plan depuis le profil, puis le voir sur l\'accueil', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accueil_plan_du_jour')), findsNothing);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    final acces = find.byKey(const Key('acces_mon_plan'));
    await tester.ensureVisible(acces);
    await tester.pumpAndSettle();
    await tester.tap(acces);
    await tester.pumpAndSettle();
    expect(find.byType(MonPlanScreen), findsOneWidget);

    // Un texte invalide est refusé avec un message.
    await tester.enterText(find.byKey(const Key('champ_plan')), 'pas un plan');
    await tester.tap(find.byKey(const Key('bouton_importer_plan')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ne ressemble pas à un plan'), findsOneWidget);
    expect(stockage.chargerPlanTexte(), isNull);

    await tester.enterText(find.byKey(const Key('champ_plan')), _planExemple);
    await tester.tap(find.byKey(const Key('bouton_importer_plan')));
    await tester.pumpAndSettle();
    expect(find.text('Plan d\'essai'), findsOneWidget);
    expect(find.byKey(const Key('plan_aujourdhui')), findsOneWidget);
    expect(stockage.chargerPlanTexte(), isNotNull);

    // Retour au profil : le repère calorique laisse la place au plan.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.text('Ton repère : ton plan'), findsOneWidget);
    expect(find.text('Indications générales, pas un avis médical.'), findsNothing);

    // Sur l'accueil : le plan du jour.
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accueil_plan_du_jour'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('recettes : note neutre sur ce que le plan conseille d\'éviter', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await PlanProvider(stockage).importer(_planExemple);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const RecettesScreen()));
    await tester.pumpAndSettle();

    // L'alloco est frit : la note apparaît au dos de la carte.
    await tester.tap(find.byKey(const Key('recette_alloco')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note_plan_alloco')), findsOneWidget);
    expect(find.textContaining('friture'), findsWidgets);
  });

  testWidgets('retirer le plan', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await PlanProvider(stockage).importer(_planExemple);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const MonPlanScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('menu_plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer le plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmer_retrait_plan')));
    await tester.pumpAndSettle();
    expect(stockage.chargerPlanTexte(), isNull);
    expect(find.byKey(const Key('champ_plan')), findsOneWidget);
    // Laisse se terminer l'infobulle du bouton de menu.
    await tester.pump(const Duration(seconds: 5));
  });

  test('les recettes ont toutes des ingrédients', () {
    for (final r in RecettesService.recettes) {
      expect(r.ingredients, isNotEmpty, reason: r.nom);
    }
  });
}
