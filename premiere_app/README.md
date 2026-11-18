# Kira's FAT 🌸

Application de suivi bien-être pour perdre du poids de façon saine et
progressive, avec un ton bienveillant. Interface en français, thème rose
clair et sombre, fonctionne dans le navigateur (Flutter Web).

> Indications générales, pas un avis médical.

## Fonctionnalités

| Onglet / écran | Contenu |
|---|---|
| **Onboarding** | 6 pages animées pour créer le profil (objectif refusé si IMC < 18,5) |
| **Accueil** | Photo et salutation selon l'heure, rappel de repas, plan du jour, mot du jour, plante 🌸 qui grandit avec les habitudes, eau, dernière activité, « J'ai une fringale » (respiration d'1 minute) |
| **Poids** | Pesées, courbe avec tendance sur 7 jours, chemin des paliers (5 % + 2 semaines de stabilisation) |
| **Habitudes** | Journal à glisser jour par jour : eau (bouteille animée), humeur, sommeil, repas (avec assiette en photo), activités, petit mot, calendrier coloré |
| **Profil** | Photo de profil, modification du profil, repère calorique (Mifflin-St Jeor, jamais sous 1200 kcal) remplacé par le plan quand il y en a un |
| **Mon plan** | Plan de la diététicienne, collé une fois et gardé uniquement sur l'appareil : menu du jour, aliments conseillés ou à éviter |
| **Journal des repas** | Noter un repas en 2 touches : ~70 plats africains (CI, Sénégal, Cameroun, Ghana, Nigeria, Mali, Bénin-Togo), plats du plan, plats perso ou photo ; portion, faim, satiété, plaisir. Aucun compteur |
| **Rappels** | Invitation douce sur l'accueil aux heures de repas (réglables), « Plus tard » sans insister |
| **Bilan** | Chaque dimanche : ce qui s'est bien passé, constats sans jugement, 1 ou 2 idées à choisir, résumé à partager avec le nutritionniste |
| **Bouger** | 8 exercices illustrés (figurines animées), 4 séances guidées avec minuteur, proposées selon l'énergie du jour, confettis à la fin |
| **Défis & badges** | 10 défis doux par semaine (3 max), victoires hors balance, collection de badges, confettis |
| **Recettes** | 10 plats ivoiriens en cartes à retourner : plat d'origine / version revisitée |
| **Réglages** | Masquer le poids sur l'accueil, objectif d'eau, rappels, thème, tout effacer |

Règles bien-être appliquées partout : aucun message culpabilisant, jamais de
rouge si le poids augmente, la plante et les badges récompensent les
habitudes (jamais une restriction), et toutes les données restent sur
l'appareil.

## Installer sur iPhone et iPad

1. Ouvrir **https://tionrolokone16-commits.github.io/Projet-Sheik-/** dans **Safari**.
2. Toucher **Partager** (le carré avec une flèche), puis **Sur l'écran d'accueil**.
3. Toujours ouvrir l'appli depuis cette icône : elle s'ouvre en plein écran
   et ses données sont conservées durablement.

Les données restent sur chaque appareil (l'iPad et l'iPhone ne les partagent pas).
La version en ligne se met à jour toute seule à chaque mise à jour de la branche
`main` (voir `.github/workflows/publier-kiras-fat.yml`).

Icônes : `flutter test tool/generer_icones_test.dart` les redessine.

## Lancer l'application (Codespaces)

Le Codespace installe tout seul Flutter 3.50.0 à sa création
(`.devcontainer/installer-flutter.sh`, qu'on peut relancer sans risque).

```bash
cd premiere_app
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

Puis ouvrir le port **8080** dans l'onglet *Ports* de VS Code.

## Vérifier le code

```bash
flutter analyze   # recherche d'erreurs
flutter test      # tests automatiques
```

## Organisation du code

```
lib/
  main.dart        point d'entrée, providers, thème
  theme.dart       palette rose et thèmes clair / sombre
  models/          données (profil, pesée, activité, journée, recette…)
  services/        stockage local et règles (calculs, messages, paliers…)
  providers/       état de l'application (provider)
  screens/         écrans
  widgets/         éléments réutilisables (bouteille, plante, assiette…)
test/              tests automatiques
```

Packages : provider, shared_preferences, fl_chart, intl, google_fonts,
flutter_animate, confetti, image_picker, share_plus (tous compatibles web).
