# Extrait de ThermoBat (backend FastAPI).
# Humidité absolue (rapport de mélange) à partir de la température et de
# l'humidité relative mesurées sur le terrain. Sert pour la partie latente
# de la charge clim : à Lomé l'air est tellement humide que c'est loin d'être négligeable.
#
# Magnus-Tetens pour la pression de vapeur saturante, P = 1013,25 hPa.
# Ce n'est pas un diagramme de l'air humide complet (pas d'enthalpie, pas de rosée),
# juste ce dont le calcul a besoin.
from __future__ import annotations

import math

STANDARD_PRESSURE_HPA = 1013.25

# Constantes de l'approximation de Magnus-Tetens (Alduchov & Eskridge 1996)
# pour la pression de vapeur saturante au-dessus de l'eau liquide.
_MAGNUS_A = 6.1094
_MAGNUS_B = 17.625
_MAGNUS_C = 243.04


def humidity_ratio_g_kg(temp_c: float, rh_pct: float, pressure_hpa: float = STANDARD_PRESSURE_HPA) -> float:
    """Rapport de mélange approché W (g d'eau / kg d'air sec).

    W = 622 x e / (P - e), avec e = (rh/100) x e_s(T) (pression de vapeur),
    e_s(T) approchée par la formule de Magnus-Tetens.
    """
    if temp_c is None or rh_pct is None:
        raise ValueError("Température et humidité relative sont requises.")
    if not 0 <= rh_pct <= 100:
        raise ValueError("L'humidité relative doit être comprise entre 0 et 100 %.")
    if pressure_hpa is None or pressure_hpa <= 0:
        raise ValueError("La pression atmosphérique doit être strictement positive.")
    if temp_c <= -_MAGNUS_C:
        raise ValueError("Température hors du domaine de validité de l'approximation.")

    e_saturation = _MAGNUS_A * math.exp((_MAGNUS_B * temp_c) / (temp_c + _MAGNUS_C))
    e_vapor = (rh_pct / 100.0) * e_saturation
    if e_vapor >= pressure_hpa:
        raise ValueError("Pression de vapeur incohérente avec la pression atmosphérique fournie.")
    return 622.0 * e_vapor / (pressure_hpa - e_vapor)
