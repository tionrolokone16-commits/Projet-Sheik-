import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'providers/habitudes_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/poids_provider.dart';
import 'providers/profil_provider.dart';
import 'providers/recompenses_provider.dart';
import 'providers/reglages_provider.dart';
import 'screens/navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/stockage_service.dart';
import 'theme.dart';
import 'widgets/couche_celebrations.dart';

/// Point d'entrée de Kira's FAT.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dates et nombres en français.
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';

  // Chargement des données enregistrées sur l'appareil.
  final stockage = await StockageService.initialiser();

  runApp(FormeDouceApp(stockage: stockage));
}

class FormeDouceApp extends StatefulWidget {
  const FormeDouceApp({super.key, required this.stockage});

  final StockageService stockage;

  /// Repart de zéro : toutes les données sont relues depuis le stockage
  /// (utilisé après « Tout effacer »).
  static void redemarrer(BuildContext context) =>
      context.findAncestorStateOfType<_FormeDouceAppState>()?._redemarrer();

  @override
  State<FormeDouceApp> createState() => _FormeDouceAppState();
}

class _FormeDouceAppState extends State<FormeDouceApp> {
  /// Changer cette clé recrée tous les providers.
  Key _cle = UniqueKey();

  void _redemarrer() => setState(() => _cle = UniqueKey());

  @override
  Widget build(BuildContext context) {
    final stockage = widget.stockage;
    return MultiProvider(
      key: _cle,
      providers: [
        Provider.value(value: stockage),
        ChangeNotifierProvider(create: (_) => ProfilProvider(stockage)),
        ChangeNotifierProvider(create: (_) => PoidsProvider(stockage)),
        ChangeNotifierProvider(create: (_) => HabitudesProvider(stockage)),
        ChangeNotifierProvider(create: (_) => ReglagesProvider(stockage)),
        ChangeNotifierProvider(create: (_) => RecompensesProvider(stockage)),
        ChangeNotifierProvider(create: (_) => PlanProvider(stockage)),
      ],
      // Consumer : l'application se redessine quand le thème change.
      child: Consumer<ReglagesProvider>(
        builder: (context, reglages, _) => MaterialApp(
          title: 'Kira\'s FAT',
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
