import '../models/recette.dart';

/// Recettes ivoiriennes et leurs versions revisitées.
///
/// Ton : on ajoute, on remplace, on ajuste… on n'interdit jamais.
class RecettesService {
  RecettesService._();

  static const recettes = [
    Recette(
      id: 'attieke_poisson',
      nom: 'Attiéké poisson braisé',
      emoji: '🐟',
      description: 'La semoule de manioc fermentée, servie avec un poisson '
          'braisé, des oignons, de la tomate et du piment. Un classique du maquis.',
      astuces: [
        'Garde le poisson braisé : il est déjà délicieux sans friture.',
        'Double la salade de tomates, oignons et concombre : la moitié de l\'assiette.',
        'Sers l\'attiéké sur un quart de l\'assiette, et savoure-le.',
        'Un filet de citron vert remplace très bien une partie de l\'huile.',
      ],
      portions: Portions(legumes: 0.5, proteines: 0.25, feculents: 0.25),
    ),
    Recette(
      id: 'alloco',
      nom: 'Alloco',
      emoji: '🍌',
      description: 'Des bananes plantain bien mûres, frites et dorées, '
          'souvent servies avec du poisson, un œuf ou une sauce pimentée.',
      astuces: [
        'Essaie le plantain au four ou braisé : il caramélise tout seul.',
        'Ajoute une protéine : œuf dur, poisson grillé ou haricots.',
        'Accompagne d\'une salade d\'avocat et de tomates.',
        'Envie d\'alloco frit ? Savoure-le pleinement, avec une belle salade à côté.',
      ],
      portions: Portions(legumes: 0.4, proteines: 0.3, feculents: 0.3),
    ),
    Recette(
      id: 'garba',
      nom: 'Garba',
      emoji: '🥘',
      description: 'L\'attiéké avec du thon frit, des oignons et du piment frais. '
          'Le plat convivial et rassasiant par excellence.',
      astuces: [
        'Fais griller ou cuire le thon au four, avec un peu d\'huile au pinceau.',
        'Ajoute des crudités : tomates, oignons, chou, concombre.',
        'Assaisonne avec piment, citron et cube maison plutôt qu\'avec l\'huile de friture.',
      ],
      portions: Portions(legumes: 0.45, proteines: 0.3, feculents: 0.25),
    ),
    Recette(
      id: 'foutou_graine',
      nom: 'Foutou banane, sauce graine',
      emoji: '🍲',
      description: 'Le foutou pilé de banane plantain et de manioc, avec la '
          'sauce à la graine de palme, riche et parfumée.',
      astuces: [
        'Laisse reposer la sauce et retire l\'huile qui remonte en surface.',
        'Ajoute des légumes à la sauce : aubergines, gombo, épinards.',
        'Choisis du poisson ou une viande maigre.',
        'Une boule de foutou à ta faim, accompagnée de beaucoup de sauce aux légumes.',
      ],
      portions: Portions(legumes: 0.4, proteines: 0.3, feculents: 0.3),
    ),
    Recette(
      id: 'kedjenou',
      nom: 'Kédjénou de poulet',
      emoji: '🍗',
      description: 'Le poulet mijoté à l\'étouffée dans son jus, avec tomates, '
          'oignons, aubergines et piment. Sans ajout de matière grasse !',
      astuces: [
        'Déjà une merveille d\'équilibre : cuit dans son jus, sans huile.',
        'Retire la peau du poulet pour une version encore plus légère.',
        'Ajoute plus de légumes dans la canari : gombo, carottes, aubergines.',
        'Sers avec un peu d\'attiéké ou de riz.',
      ],
      portions: Portions(legumes: 0.45, proteines: 0.35, feculents: 0.2),
    ),
    Recette(
      id: 'sauce_arachide',
      nom: 'Riz sauce arachide',
      emoji: '🥜',
      description: 'La sauce onctueuse à la pâte d\'arachide, avec viande ou '
          'poisson, servie sur du riz blanc.',
      astuces: [
        'Utilise un peu moins de pâte d\'arachide et plus de bouillon et de tomates.',
        'Ajoute aubergines, gombo, chou ou carottes dans la sauce.',
        'Poulet sans peau ou poisson pour la protéine.',
        'Le riz sur un quart de l\'assiette, et le reste pour la sauce aux légumes.',
      ],
      portions: Portions(legumes: 0.45, proteines: 0.3, feculents: 0.25),
    ),
    Recette(
      id: 'placali_gombo',
      nom: 'Placali, sauce gombo',
      emoji: '🌿',
      description: 'La pâte de manioc fermenté avec la sauce gombo gluante, '
          'au poisson fumé et au crabe.',
      astuces: [
        'La sauce gombo est riche en légumes : profites-en !',
        'Réduis un peu l\'huile de palme et laisse parler le poisson fumé.',
        'Ajoute des feuilles (épinards, kplala) pour encore plus de verdure.',
      ],
      portions: Portions(legumes: 0.5, proteines: 0.25, feculents: 0.25),
    ),
    Recette(
      id: 'riz_gras',
      nom: 'Riz gras',
      emoji: '🍚',
      description: 'Le riz cuit dans une sauce tomate généreuse, avec viande '
          'et légumes. Le plat des grandes occasions.',
      astuces: [
        'Fais revenir les oignons dans une cuillère d\'huile, pas plus.',
        'Mets beaucoup de légumes : carottes, chou, haricots verts, poivrons.',
        'Mélange moitié riz, moitié légumes dans la marmite.',
      ],
      portions: Portions(legumes: 0.5, proteines: 0.25, feculents: 0.25),
    ),
    Recette(
      id: 'claclo',
      nom: 'Claclo',
      emoji: '🍪',
      description: 'Les petits beignets de banane plantain bien mûre, '
          'dorés et fondants. La gourmandise de l\'après-midi.',
      astuces: [
        'Version au four : petites boules sur une plaque, 20 minutes à 200 °C.',
        'La banane bien mûre suffit à sucrer : inutile d\'en rajouter.',
        'Savoure-les avec un yaourt nature ou un thé, en prenant ton temps.',
      ],
      portions: Portions(legumes: 0.2, proteines: 0.2, feculents: 0.6),
    ),
    Recette(
      id: 'degue',
      nom: 'Dêguê',
      emoji: '🥣',
      description: 'Le dessert frais au mil et au lait caillé, sucré et '
          'rafraîchissant.',
      astuces: [
        'Prends un yaourt ou un lait caillé nature, et sucre toi-même, un peu.',
        'Ajoute des morceaux de mangue, de banane ou d\'ananas.',
        'Une belle bolée en dessert ou au goûter, c\'est parfait.',
      ],
      portions: Portions(legumes: 0.25, proteines: 0.35, feculents: 0.4),
    ),
  ];
}
