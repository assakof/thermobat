# ThermoBat

Petit assistant pour faire un relevé thermique sur le terrain et calculer la charge de climatisation d'un local. Tu rentres les murs couche par couche, les fenêtres, les gens, les appareils, et l'appli te donne les résistances R, les U, puis la puissance de clim qu'il faut.

Fait pour une présentation en licence 3 (physique appliquée, énergie et habitat). La première version a été montée en à peu près deux jours, ensuite j'ai continué à l'améliorer.

**Démo en ligne : https://assakof.github.io/thermobat/**

(si ça met du temps à charger la première fois c'est normal, le serveur gratuit se met en veille, il lui faut 30 s à 1 min pour se réveiller)

## Ce qu'il y a dedans

- Projet → bâtiment → local → parois multicouches → mesures de terrain
- Météo de conception trouvée automatiquement à partir du nom de la ville (jour le plus chaud des 3 dernières années)
- Apports solaires par orientation, bilan sensible / latent
- Catalogues de murs, fenêtres et équipements réutilisables dans un projet
- Rapport PDF + export JSON
- Installable sur téléphone comme une appli (PWA) : dans Chrome, menu ⋮ puis « Ajouter à l'écran d'accueil »

Une précision importante : on est en climat chaud, donc c'est un calcul de **clim**, pas de chauffage. La chaleur des occupants et des appareils s'ajoute à ce qu'il faut sortir, elle ne vient pas en déduction comme dans un bilan d'hiver en Europe.

Les résultats ont été vérifiés contre des calculs faits à la main (R = e/λ, U = 1/R, Q = A·U·ΔT…), mais pas encore confrontés à des mesures réelles. C'est un outil pédagogique d'abord.

## Technique

- Backend : Python, FastAPI, SQLAlchemy, SQLite, génération PDF, tests pytest sur tout le moteur de calcul
- Frontend : Flutter Web (Riverpod, Dio), habillage « Frutiger Aero » fait main (dégradés, reflets, jauge à aiguille)
- Hébergement : API sur Render, appli sur GitHub Pages

Le code est privé, voici deux extraits :

- [`extraits/humidite.py`](extraits/humidite.py) — humidité absolue à partir de T et HR (Magnus-Tetens)
- [`extraits/jauge_aero.dart`](extraits/jauge_aero.dart) — la jauge du résultat, dessinée entièrement au CustomPainter

Pour un outil plus complet (lecture de plans PDF, bâtiment entier), voir mon autre logiciel [AkClim](https://github.com/assakof/AkClim).

---

ASSOGBA Koffi Ezechiel — Togo
