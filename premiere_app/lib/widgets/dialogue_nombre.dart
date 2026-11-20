import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Demande un nombre entier (calories, pas…). Renvoie `null` si on annule.
Future<int?> demanderNombre(
  BuildContext context, {
  required String titre,
  int? initial,
  String? aide,
  String? unite,
  int maximum = 100000,
}) => showDialog<int>(
  context: context,
  builder: (_) =>
      _DialogueNombre(titre: titre, initial: initial, aide: aide, unite: unite, maximum: maximum),
);

class _DialogueNombre extends StatefulWidget {
  const _DialogueNombre({
    required this.titre,
    required this.initial,
    required this.aide,
    required this.unite,
    required this.maximum,
  });

  final String titre;
  final int? initial;
  final String? aide;
  final String? unite;
  final int maximum;

  @override
  State<_DialogueNombre> createState() => _DialogueNombreState();
}

class _DialogueNombreState extends State<_DialogueNombre> {
  late final _champ = TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  void _valider() {
    final n = int.tryParse(_champ.text);
    if (n != null) Navigator.of(context).pop(n.clamp(0, widget.maximum));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.aide != null) ...[
            Text(widget.aide!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
          ],
          TextField(
            key: const Key('champ_nombre'),
            controller: _champ,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(suffixText: widget.unite),
            onSubmitted: (_) => _valider(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(
          key: const Key('valider_nombre'),
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
