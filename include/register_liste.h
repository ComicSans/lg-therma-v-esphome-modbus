#pragma once
// Namen der Entitaeten, die direkt ein Modbus-Register lesen oder schreiben.
// Eine Liste fuer alle Auswertungen: Punkte ohne Antwort, Registerbeobachtung,
// Referenzvergleich und das Ungueltigsetzen bei Busausfall. scripts/test.sh
// prueft, dass sie mit den modbus_controller-Eintraegen in therma-v.yaml
// uebereinstimmt.
#include <cstring>

namespace register_liste {

inline bool ist_register(const char *name) {
  static const char *const NAMEN[] = {
      // sensor
      "Außentemperatur Gerätefühler",
      "Raumtemperatur",
      "Wasser Rücklauftemperatur",
      "Wasser Vorlauftemperatur",
      "Warmwassertemperatur",
      "Hochdruck",
      "Niederdruck",
      "Sauggastemperatur",
      "Scheinleistung Anlage",
      "Verdichtertemperatur",
      "Wärmetauscher außen",
      "Wärmetauscher außen (Spiegelregister)",
      "Wassertemperatur unbestimmt",
      "IR09 Kennwert",
      "Kennwert Kältemittel",
      "IR10 unbestimmt",
      "Verdichterleistung Anforderung",
      "IR27 unbestimmt",
      "Betriebsmodus Rohwert",
      "HR25 unbestimmt",
      "HR27 unbestimmt",
      "HR28 unbestimmt",
      // binary_sensor
      "DI06 unbestimmt",
      "Verdichter startbereit",
      "Verdichter hohe Stufe",
      "DI09 Warmwasserbereitung",
      "CO5 unbestimmt (nur Anzeige)",
      "Heizkreis 1 invers",
      "DI32 unbestimmt",
      "Heizkreis 1",
      "Außeneinheit in Betrieb",
      "CO29 unbestimmt",
      "CO30 unbestimmt",
      // number, select, switch
      "Soll-Temperatur Heizkreis 1",
      "Soll-Temperatur Warmwasser",
      "Betriebsmodus (stellbar)",
      "Flüstermodus",
      "Warmwasser Freigabe",
  };
  for (const char *n : NAMEN)
    if (std::strcmp(n, name) == 0)
      return true;
  return false;
}

}  // namespace register_liste
