import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../services/journal_service.dart';
import '../widgets/vue_jour_habitudes.dart';
import 'calendrier_screen.dart';

/// Onglet Habitudes, sous forme de journal :
/// on glisse d'un jour à l'autre (vers la droite = jours passés),
/// ou on choisit un jour dans le calendrier coloré.
class HabitudesScreen extends StatefulWidget {
  const HabitudesScreen({super.key});

  @override
  State<HabitudesScreen> createState() => _HabitudesScreenState();
}

class _HabitudesScreenState extends State<HabitudesScreen> {
  /// Nombre de jours passés consultables (environ 10 ans).
  static const _joursMax = 3650;

  final _pages = PageController();

  /// 0 = aujourd'hui, 1 = hier, etc.
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Date correspondant à une page.
  DateTime _dateDe(int index) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - index);
  }

  void _allerA(int index) {
    if (index < 0 || index >= _joursMax) return;
    // Pour un saut lointain, pas d'animation de défilement interminable.
    if ((index - _index).abs() > 3) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(index,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _ouvrirCalendrier() async {
    final choisie = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => CalendrierScreen(jourSelectionne: _dateDe(_index)),
      ),
    );
    if (choisie == null) return;
    final n = DateTime.now();
    final aujourdhui = DateTime(n.year, n.month, n.day);
    _allerA((aujourdhui.difference(choisie).inHours / 24).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _dateDe(_index);
    final dateEnClair =
        toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr_FR').format(date));
    final titreJour = JournalService.nomRelatif(date) ?? dateEnClair;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes habitudes'),
        actions: [
          IconButton(
            key: const Key('bouton_calendrier'),
            tooltip: 'Calendrier',
            onPressed: _ouvrirCalendrier,
            icon: const Hero(
              tag: 'calendrier',
              child: Icon(Icons.calendar_month_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Barre de navigation entre les jours.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Jour précédent',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _allerA(_index + 1),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      titreJour,
                      key: ValueKey(titreJour),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Jour suivant',
                  icon: const Icon(Icons.chevron_right_rounded),
                  // Pas de jours futurs.
                  onPressed: _index == 0 ? null : () => _allerA(_index - 1),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton.extended(
              // Étiquette unique : plusieurs onglets ont un bouton flottant.
              heroTag: 'fab_journal',
              onPressed: () => _allerA(0),
              icon: const Icon(Icons.today_rounded),
              label: const Text('Aujourd\'hui'),
            ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pages,
          // Inversé : glisser vers la droite fait remonter dans le passé.
          reverse: true,
          itemCount: _joursMax,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: VueJourHabitudes(key: ValueKey(i), date: _dateDe(i)),
            ),
          ),
        ),
      ),
    );
  }
}
