/// Salutations et messages d'encouragement de l'accueil.
class EncouragementsService {
  EncouragementsService._();

  /// Salutation selon l'heure : « Bonjour Kira ☀️ », « Bonsoir Kira 🌙 »…
  static String salutation(String prenom, {DateTime? maintenant}) {
    final heure = (maintenant ?? DateTime.now()).hour;
    final nom = prenom.trim().isEmpty ? '' : ' ${prenom.trim()}';
    if (heure >= 5 && heure < 12) return 'Bonjour$nom ☀️';
    if (heure >= 12 && heure < 18) return 'Bel après-midi$nom 🌤️';
    if (heure >= 18 && heure < 23) return 'Bonsoir$nom 🌙';
    return 'Douce nuit$nom ✨';
  }

  /// Messages du jour : toujours bienveillants, centrés sur les habitudes
  /// et le bien-être plutôt que sur le chiffre de la balance.
  static const messages = [
    'Chaque verre d\'eau est un petit cadeau que tu te fais 💧',
    'Le progrès, ce n\'est pas la perfection : c\'est la régularité 🌱',
    'Ton corps mérite de la douceur, aujourd\'hui comme les autres jours 💗',
    'Une marche de 10 minutes compte vraiment. Tout compte !',
    'Les variations du poids sont normales : regarde la tendance, pas le jour 🌸',
    'Prendre le temps de manger assis, sans écran, c\'est déjà prendre soin de toi.',
    'Tu n\'as rien à rattraper : chaque jour est un nouveau départ ✨',
    'Bien dormir fait partie du chemin. Ce soir, offre-toi un moment calme 🌙',
    'Parle-toi avec la même tendresse que tu offres aux personnes que tu aimes 💕',
    'Un plat que tu aimes a toujours sa place. L\'équilibre se fait sur la semaine.',
    'Respire profondément. Tu fais de ton mieux, et c\'est suffisant 🫶',
    'Les petites habitudes d\'aujourd\'hui font les grandes victoires de demain.',
    'Bouger pour le plaisir : danse, marche, jardinage… choisis ce qui te fait sourire 💃',
    'Écoute ta faim et ta satiété : ton corps sait des choses 🌿',
    'Une journée moins réussie ne défait pas tout ce que tu as construit.',
    'Note une victoire hors balance aujourd\'hui : énergie, sommeil, sourire…',
    'Les légumes de saison sont tes alliés : colorés, savoureux et généreux 🥬',
    'Tu avances à ton rythme, et ton rythme est le bon 🐢🌸',
    'Un grand verre d\'eau au réveil, et la journée commence en douceur 💧',
    'Chaque petit pas mérite d\'être fêté 🎉',
    'Le repos fait partie de l\'entraînement. Écoute-toi 🌙',
    'Cuisiner maison, même simplement, c\'est une belle façon de prendre soin de soi 🍲',
    'Ta valeur ne se mesure pas en kilos 💗',
    'Aujourd\'hui, choisis une seule petite chose à faire pour toi. Juste une.',
  ];

  /// Message du jour : le même toute la journée, différent le lendemain.
  static String messageDuJour({DateTime? date}) {
    final d = date ?? DateTime.now();
    final jourDeLAnnee = d.difference(DateTime(d.year)).inDays;
    return messages[(jourDeLAnnee + d.year) % messages.length];
  }
}
