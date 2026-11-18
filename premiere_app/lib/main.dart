import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/habitudes_provider.dart';
import 'providers/poids_provider.dart';
import 'providers/profil_provider.dart';
import 'providers/recompenses_provider.dart';
import 'providers/reglages_provider.dart';
import 'screens/navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/stockage_service.dart';
import 'theme.dart';
import 'widgets/couche_celebrations.dart';

/// Point d'entrée de Forme Douce.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dates et nombres en français.
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  // Chargement des données enregistrées sur l'appareil.
  final stockage = await StockageService.initialiser();

  runApp(FormeDouceApp(stockage: stockage));
}

class FormeDouceApp extends StatelessWidget {
  const FormeDouceApp({super.key, required this.stockage});

  final StockageService stockage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: stockage),
        ChangeNotifierProvider(create: (_) => ProfilProvider(stockage)),
        ChangeNotifierProvider(create: (_) => PoidsProvider(stockage)),
        ChangeNotifierProvider(create: (_) => HabitudesProvider(stockage)),
        ChangeNotifierProvider(create: (_) => ReglagesProvider(stockage)),
        ChangeNotifierProvider(create: (_) => RecompensesProvider(stockage)),
      ],
      // Consumer : l'application se redessine quand le thème change.
      child: Consumer<ReglagesProvider>(
        builder: (context, reglages, _) => MaterialApp(
          title: 'Forme Douce',
          debugShowCheckedModeBanner: false,
          theme: ThemeFormeDouce.clair(),
          darkTheme: ThemeFormeDouce.sombre(),
          themeMode: reglages.themeMode,
          // Interface entièrement en français (y compris le calendrier).
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // Confettis et bannières de célébration, au-dessus de tous les écrans.
          builder: (context, enfant) => CoucheCelebrations(child: enfant!),
          // Premier lancement : onboarding. Ensuite : écran principal.
          // Le passage de l'un à l'autre se fait en fondu.
          home: Consumer<ProfilProvider>(
            builder: (context, profil, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: profil.estComplet
                  ? const NavigationScreen(key: ValueKey('principal'))
                  : const OnboardingScreen(key: ValueKey('onboarding')),
            ),
          ),
        ),
      ),
    );
  }
}
