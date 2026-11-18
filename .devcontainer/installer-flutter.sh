#!/usr/bin/env bash
# Installe Flutter dans le Codespace, dans une version fixée.
#
# Lancé automatiquement à la création du Codespace (voir devcontainer.json).
# On peut aussi le relancer à la main sans risque :
#   bash .devcontainer/installer-flutter.sh
set -euo pipefail

# Version testée avec l'application. Pour changer de version : modifier ici,
# ainsi que flutter-version dans .github/workflows/publier-kiras-fat.yml.
VERSION_FLUTTER="3.50.0"
DOSSIER="$HOME/flutter"
RACINE="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Outils système nécessaires"
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends unzip xz-utils curl git

echo "==> Flutter $VERSION_FLUTTER"
version_installee=""
if [ -x "$DOSSIER/bin/flutter" ]; then
  version_installee="$("$DOSSIER/bin/flutter" --version --machine 2>/dev/null \
    | grep -o '"frameworkVersion": *"[^"]*"' | grep -o '[0-9][0-9.]*' || true)"
fi
if [ "$version_installee" = "$VERSION_FLUTTER" ]; then
  echo "Déjà installé, rien à faire."
else
  if [ -d "$DOSSIER" ]; then
    # Une autre version est présente : on la met de côté plutôt que de l'effacer.
    echo "Version actuelle : ${version_installee:-inconnue}, mise de côté dans $DOSSIER.ancien"
    rm -rf "$DOSSIER.ancien"
    mv "$DOSSIER" "$DOSSIER.ancien"
  fi
  git clone --quiet https://github.com/flutter/flutter.git \
    --branch "$VERSION_FLUTTER" --depth 1 "$DOSSIER"
fi
export PATH="$DOSSIER/bin:$PATH"

# Filet de sécurité pour les terminaux (devcontainer.json déclare déjà le chemin).
for fichier in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -q 'flutter/bin' "$fichier" 2>/dev/null \
    || echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$fichier"
done

echo "==> Réglages de Flutter"
# Pas d'envoi de statistiques d'utilisation à Google.
flutter --disable-analytics >/dev/null
dart --disable-analytics >/dev/null
flutter config --enable-web >/dev/null
flutter precache --web

echo "==> Packages de l'application"
(cd "$RACINE/premiere_app" && flutter pub get)

flutter --version
echo "==> Prêt ! Pour lancer l'appli :"
echo "    cd premiere_app && flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0"
