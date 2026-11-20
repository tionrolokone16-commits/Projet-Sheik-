/// Une pesée : une date et un poids en kilogrammes.
class Pesee {
  const Pesee({required this.id, required this.date, required this.poidsKg});

  /// Identifiant unique (sert à modifier ou supprimer une pesée).
  final String id;
  final DateTime date;
  final double poidsKg;

  Pesee copyWith({DateTime? date, double? poidsKg}) =>
      Pesee(id: id, date: date ?? this.date, poidsKg: poidsKg ?? this.poidsKg);

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'poidsKg': poidsKg};

  factory Pesee.fromJson(Map<String, dynamic> json) => Pesee(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    poidsKg: (json['poidsKg'] as num).toDouble(),
  );
}
