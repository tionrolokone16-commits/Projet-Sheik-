import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'format.dart';

/// Résultat renvoyé par la fenêtre de saisie d'une pesée.
typedef SaisiePesee = ({DateTime date, double poidsKg});

/// Ouvre une fenêtre pour saisir une pesée (date + poids).
/// Renvoie `null` si l'utilisateur annule.
Future<SaisiePesee?> afficherDialoguePesee(
  BuildContext context, {
  double? poidsPropose,
}) {
  return showDialog<SaisiePesee>(
    context: context,
    builder: (_) => _DialoguePesee(poidsPropose: poidsPropose),
  );
}

class _DialoguePesee extends StatefulWidget {
  const _DialoguePesee({this.poidsPropose});

  final double? poidsPropose;

  @override
  State<_DialoguePesee> createState() => _DialoguePeseeState();
}

class _DialoguePeseeState extends State<_DialoguePesee> {
  final _formulaire = GlobalKey<FormState>();
  late final TextEditingController _poids = TextEditingController(
    text: widget.poidsPropose == null ? '' : formaterDecimal(widget.poidsPropose!),
  );
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _poids.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Pas de pesée dans le futur.
    );
    if (choisie != null) setState(() => _date = choisie);
  }

  void _valider() {
    if (!_formulaire.currentState!.validate()) return;
    Navigator.of(context).pop((date: _date, poidsKg: lireDecimal(_poids.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle pesée'),
      content: Form(
        key: _formulaire,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('EEEE d MMMM y', 'fr_FR').format(_date)),
              subtitle: const Text('Toucher pour changer la date'),
              onTap: _choisirDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('champ_poids_pesee'),
              controller: _poids,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Poids', suffixText: 'kg'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onFieldSubmitted: (_) => _valider(),
              validator: (t) {
                final v = lireDecimal(t);
                if (v == null) return 'Merci d\'indiquer un nombre';
                if (v < 30 || v > 300) return 'Entre 30 et 300 kg';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('bouton_valider_pesee'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
