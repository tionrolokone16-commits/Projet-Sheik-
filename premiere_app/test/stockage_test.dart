import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:premiere_app/main.dart';
import 'package:premiere_app/models/jour_habitudes.dart';
import 'package:premiere_app/models/recette.dart';
import 'package:premiere_app/models/repas_photo.dart';
import 'package:premiere_app/providers/habitudes_provider.dart';
import 'package:premiere_app/screens/reglages_screen.dart';
import 'package:premiere_app/services/stockage_service.dart';
import 'package:premiere_app/theme.dart';
import 'package:premiere_app/widgets/couche_celebrations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'outils.dart';

/// Faux navigateur dont la mémoire est limitée : au-delà de [limite]
/// caractères, l'écriture échoue, comme Safari quand il n'a plus de place.
class StockageLimite extends InMemorySharedPreferencesStore {
  StockageLimite(this.limite) : super.empty();

  int limite;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final tout = await getAll();
    var total = key.length + value.toString().length;
    tout.forEach((k, v) {
      if (k != key) total += k.length + v.toString().length;
    });
    if (total > limite) throw Exception('QuotaExceededError (simulée)');
    return super.setValue(valueType, key, value);
  }
}

/// Stockage de l'application branché sur le faux navigateur limité.
Future<(StockageService, StockageLimite)> stockageLimite(int limite) async {
  ThemeFormeDouce.utiliserGoogleFonts = false;
  CoucheCelebrations.confettisActives = false;
  await initializeDateFormatting('fr_FR');
  final navigateur = StockageLimite(limite);
  SharedPreferences.resetStatic();
  SharedPreferencesStorePlatform.instance = navigateur;
  return (await StockageService.initialiser(), navigateur);
}

RepasPhoto repas(int jour, {bool photo = true}) => RepasPhoto(
  id: 'r$jour',
  date: DateTime(2026, 11, jour, 13),
  repas: Repas.dejeuner,
  portions: Portions.equilibre,
  nomPlat: 'Repas $jour',
  photoBase64: photo ? 'A' * 1000 : null,
);

void main() {
  test('photos trop lourdes : les plus anciennes sont retirées, les repas restent', () async {
    final (stockage, _) = await stockageLimite(5000);
    final dix = [for (var j = 10; j >= 1; j--) repas(j)]; // du plus récent au plus ancien

    final enregistres = await stockage.enregistrerRepasPhotos(dix);

    expect(enregistres.length, 10); // aucun repas perdu
    final avecPhoto = enregistres.where((r) => r.photoBase64 != null).toList();
    expect(avecPhoto, isNotEmpty);
    expect(avecPhoto.length, lessThan(10));
    // Ce sont les plus récents qui gardent leur photo.
    expect(enregistres.first.photoBase64, isNotNull);
    expect(enregistres.last.photoBase64, isNull);
    expect(stockage.alerte.value?.type, TypeAlerteStockage.photosRetirees);
    expect(stockage.chargerRepasPhotos().length, 10);
  });

  test('pour enregistrer autre chose, on libère de la place avec les vieilles photos', () async {
    final (stockage, navigateur) = await stockageLimite(100000);
    await stockage.enregistrerRepasPhotos([for (var j = 6; j >= 1; j--) repas(j)]);
    navigateur.limite = 6000; // la place vient à manquer

    await stockage.enregistrerJournal({'2026-11-18': JourHabitudes(verres: 5, note: 'x' * 500)});

    expect(stockage.chargerJournal()['2026-11-18']?.verres, 5); // bien enregistré
    expect(stockage.alerte.value?.type, TypeAlerteStockage.photosRetirees);
    expect(stockage.chargerRepasPhotos().where((r) => r.photoBase64 != null).length, lessThan(6));
  });

  test('si rien ne suffit : une alerte plutôt qu\'une perte silencieuse', () async {
    final (stockage, _) = await stockageLimite(300);
    await stockage.enregistrerJournal({'2026-11-18': JourHabitudes(note: 'x' * 1000)});
    expect(stockage.alerte.value?.type, TypeAlerteStockage.echec);
    expect(stockage.alerte.value!.message, contains('Réglages → Mes données'));
  });

  test('le provider se resynchronise quand des photos sont retirées', () async {
    final (stockage, navigateur) = await stockageLimite(100000);
    final h = HabitudesProvider(stockage);
    for (var j = 1; j <= 6; j++) {
      await h.ajouterRepas(
        date: DateTime(2026, 11, j, 13),
        repas: Repas.dejeuner,
        portions: Portions.equilibre,
        photoBase64: 'A' * 1000,
      );
    }
    expect(h.repasPhotos.where((r) => r.photoBase64 != null).length, 6);

    navigateur.limite = 6000;
    await h.definirNote(DateTime(2026, 11, 18), 'x' * 500);

    expect(h.repasPhotos.length, 6);
    expect(h.repasPhotos.where((r) => r.photoBase64 != null).length, lessThan(6));
  });

  test('espace utilisé : il augmente avec les données', () async {
    final (stockage, _) = await stockageLimite(1000000);
    final avant = stockage.espaceUtiliseOctets();
    await stockage.enregistrerRepasPhotos([repas(1)]);
    expect(stockage.espaceUtiliseOctets(), greaterThan(avant + 2000));
  });

  testWidgets('l\'alerte s\'affiche en bas de l\'écran', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();

    stockage.alerte.value = AlerteStockage(TypeAlerteStockage.photosRetirees);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('alerte_stockage')), findsOneWidget);
    expect(find.textContaining('restent notés'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // le message repart
  });

  testWidgets('réglages : retirer les photos de repas, garder les repas', (tester) async {
    ecranIpad(tester);
    final stockage = await preparerStockage(avecProfil: true);
    final h = HabitudesProvider(stockage);
    for (var j = 1; j <= 3; j++) {
      await h.ajouterRepas(
        date: DateTime(2026, 11, j, 13),
        repas: Repas.dejeuner,
        portions: Portions.equilibre,
        photoBase64: 'A' * 1000,
      );
    }
    await tester.pumpWidget(FormeDouceApp(stockage: stockage));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => const ReglagesScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('espace_utilise')), findsOneWidget);
    final bouton = find.byKey(const Key('bouton_retirer_photos'));
    await tester.ensureVisible(bouton);
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmer_retrait_photos')));
    await tester.pumpAndSettle();

    final relus = stockage.chargerRepasPhotos();
    expect(relus.length, 3);
    expect(relus.where((r) => r.photoBase64 != null), isEmpty);
    expect(find.textContaining('3 photos retirées'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
