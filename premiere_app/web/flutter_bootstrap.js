{{flutter_js}}
{{flutter_build_config}}

// Démarrage personnalisé de Kira's FAT :
// l'écran de chargement (défini dans index.html) reste affiché pendant le
// téléchargement, puis disparaît en fondu quand l'application est prête.
// En cas d'échec (réseau coupé…), un message et un bouton « Réessayer »
// remplacent la page blanche.

(function () {
  function element(id) {
    return document.getElementById(id);
  }

  function afficherErreur() {
    var points = element('chargement-points');
    var etat = element('chargement-etat');
    var lent = element('chargement-lent');
    var erreur = element('chargement-erreur');
    var bouton = element('chargement-reessayer');
    if (points) points.hidden = true;
    if (etat) etat.hidden = true;
    if (lent) lent.hidden = true;
    if (erreur) erreur.hidden = false;
    if (bouton) bouton.hidden = false;
  }

  function masquerEcranDeChargement() {
    var ecran = element('chargement');
    if (!ecran) return;
    ecran.classList.add('fini');
    setTimeout(function () {
      if (ecran.parentNode) ecran.parentNode.removeChild(ecran);
    }, 450);
  }

  try {
    _flutter.loader
      .load({
        onEntrypointLoaded: async function (engineInitializer) {
          try {
            var etat = element('chargement-etat');
            if (etat) etat.textContent = 'Presque prêt…';
            var appRunner = await engineInitializer.initializeEngine();
            await appRunner.runApp();
            masquerEcranDeChargement();
          } catch (e) {
            console.error('Kira\'s FAT : démarrage impossible', e);
            afficherErreur();
          }
        },
      })
      .catch(function (e) {
        console.error('Kira\'s FAT : chargement impossible', e);
        afficherErreur();
      });
  } catch (e) {
    console.error('Kira\'s FAT : chargement impossible', e);
    afficherErreur();
  }
})();
