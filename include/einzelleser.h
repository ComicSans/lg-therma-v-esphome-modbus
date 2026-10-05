#pragma once
// Einmalige Einzelabfrage beliebiger Register, fuer die Scan-Knoepfe in
// therma-v.yaml. Ersetzt ModbusCommandItem::create_read_command, das ESPHome
// 2026.9 als veraltet markiert und 2027.3 entfernt (Issue #1).
//
// Der Weg ist der, den ESPHome selbst vorgibt: eine eigene Unterklasse von
// ModbusClientDevice am selben Hub und unter derselben Geraeteadresse wie der
// modbus_controller. Die Anfragen laufen damit durch dieselbe Warteschlange wie
// der Normalbetrieb. Antwortet ein Register mit einer Exception (Register gibt
// es nicht) oder gar nicht, kommt kein Rueckruf - genau wie bisher.
#include <functional>
#include <span>
#include <utility>
#include "esphome/components/modbus/modbus.h"

namespace einzelleser {

using esphome::modbus::EntityType;

class EinzelLeser : public esphome::modbus::ModbusClientDevice {
 public:
  // Rueckruf mit Registertyp, Adresse und Wert (Coils und Discrete Inputs: 0/1).
  using Antwort = std::function<void(EntityType typ, uint16_t adresse, uint16_t wert)>;

  EinzelLeser(esphome::modbus::ModbusClientHub *hub, uint8_t geraeteadresse, Antwort antwort)
      : ModbusClientDevice(hub, geraeteadresse), antwort_(std::move(antwort)) {}

  // Stellt eine Einzelabfrage in die Warteschlange. false = vom Hub abgelehnt,
  // dann folgt kein Rueckruf.
  bool lesen(EntityType typ, uint16_t adresse) { return this->read_entities(typ, adresse, 1); }

  // Kuerzel wie in der Registerkarte: IR, HR, DI, CO.
  static const char *kuerzel(EntityType typ) {
    switch (typ) {
      case EntityType::INPUT_REGISTER:
        return "IR";
      case EntityType::HOLDING:
        return "HR";
      case EntityType::DISCRETE_INPUT:
        return "DI";
      case EntityType::COIL:
        return "CO";
      default:
        return "??";
    }
  }

 protected:
  void on_read_registers(EntityType typ, uint16_t adresse, std::span<const uint16_t> werte,
                         esphome::modbus::ResponseStatus status) override {
    if (!esphome::modbus::succeeded(status) || werte.empty())
      return;
    this->antwort_(typ, adresse, werte[0]);
  }
  void on_read_bits(EntityType typ, uint16_t adresse, esphome::modbus::PackedBits bits,
                    esphome::modbus::ResponseStatus status) override {
    if (!esphome::modbus::succeeded(status) || bits.size() == 0)
      return;
    this->antwort_(typ, adresse, bits[0] ? 1 : 0);
  }

 private:
  Antwort antwort_;
};

}  // namespace einzelleser
