import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/poids_provider.dart';
import '../providers/profil_provider.dart';
import '../providers/reglages_provider.dart';
import '../services/pesee_hebdo_service.dart';
import 'dialogue_pesee.dart';
import 'format.dart';

/// Calendrier des pesées par semaine (8 dernières semaines), avec le jour
/// de pesée et un commentaire pour la semaine choisie.
class CartePeseesSemaine extends StatefulWidget {
  const CartePeseesSemaine({super.key});

  @override
  State<CartePeseesSemaine> createState() => _CartePeseesSemaineState();
}

class _CartePeseesSemaineState extends State<CartePeseesSemaine> {
  /// Semaine choisie (0 = la semaine en cours).
  int _choisie = 0;

  Future<void> _peser(SemainePesee semaine, int jourPesee) async {
    final poids = context.read<PoidsProvider>();
    final profil = context.read<ProfilProvider>().profil;
    final saisie = await afficherDialoguePesee(
      context,
      poidsPropose: semaine.pesee?.poidsKg ?? poids.derniere?.poidsKg ?? profil?.poidsDepartKg,
      dateProposee:
          semaine.pesee?.date ??
          PeseeHebdoService.dateProposee(semaine.lundi, jourPesee, DateTime.now()),
    );
    if (saisie == null) return;
    await poids.ajouter(saisie.date, saisie.poidsKg);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Pesée de la semaine enregistrée 🌿')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurs = theme.colorScheme;
    final pesees = context.watch<PoidsProvider>().pesees;
    final profil = context.watch<ProfilProvider>().profil;
    final reglagesProvider = context.watch<ReglagesProvider>();
    final jourPesee = reglagesProvider.reglages.jourPesee;
    final semaines = PeseeHebdoService.semaines(
      nombre: 8,
      maintenant: DateTime.now(),
      pesees: pesees,
    );
    final choisie = semaines[_choisie.clamp(0, semaines.length - 1)];
    final format = DateFormat('d MMM', 'fr_FR');

    return Card(
      key: const Key('carte_pesees_semaine'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Mes pesées de la semaine',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text('Mon jour de pesée :', style: theme.textTheme.bodyMedium),
                DropdownButton<int>(
                  key: const Key('choix_jour_pesee'),
                  value: jourPesee,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (var j = 1; j <= 7; j++)
                      DropdownMenuItem(value: j, child: Text(PeseeHebdoService.nomJour(j))),
                  ],
                  onChanged: (j) {
                    if (j == null) return;
                    reglagesProvider.modifier(reglagesProvider.reglages.copyWith(jourPesee: j));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Une case par semaine, la plus récente à gauche.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, s) in semaines.indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: s.pesee != null
                            ? couleurs.primaryContainer
                            : couleurs.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: i == _choisie ? couleurs.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('semaine_pesee_$i'),
                          onTap: () =>
                              s.pesee == null ? _peser(s, jourPesee) : setState(() => _choisie = i),
                          onLongPress: () => _peser(s, jourPesee),
                          child: SizedBox(
                            width: 78,
                            height: 78,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  i == 0 ? 'Cette sem.' : format.format(s.lundi),
                                  style: theme.textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                s.pesee == null
                                    ? Icon(Icons.add_rounded, color: couleurs.primary)
                                    : Text(
                                        formaterDecimal(s.pesee!.poidsKg),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: couleurs.onPrimaryContainer,
                                        ),
                                      ),
                                if (s.pesee != null) Text('kg', style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ----- Commentaire de la semaine choisie -----
            if (choisie.pesee != null && profil != null) ...[
              Text(
                'Semaine du ${format.format(choisie.lundi)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              for (final ligne in PeseeHebdoService.commentaire(
                profil: profil,
                pesees: pesees,
                pesee: choisie.pesee!,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(ligne, style: theme.textTheme.bodyMedium),
                ),
            ] else
              Text(
                'Touche « + » pour ajouter la pesée d\'une semaine. Une pesée par semaine, '
                'le ${PeseeHebdoService.nomJour(jourPesee)} matin par exemple, suffit pour '
                'suivre ta tendance.',
                key: const Key('aide_pesee_semaine'),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
