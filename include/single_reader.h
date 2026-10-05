#pragma once
// One-shot read of an arbitrary register, for the scan buttons in
// therma-v.yaml. Replaces ModbusCommandItem::create_read_command, which ESPHome
// 2026.9 deprecated and 2027.3 removes (issue #1).
//
// This is the route ESPHome itself recommends: a subclass of
// ModbusClientDevice on the same hub and device address as the
// modbus_controller. Requests therefore go through the same queue as normal
// polling. If a register answers with an exception (it does not exist) or not
// at all, no callback follows.
#include <functional>
#include <span>
#include <utility>
#include "esphome/components/modbus/modbus.h"

namespace single_reader {

using esphome::modbus::EntityType;

class SingleReader : public esphome::modbus::ModbusClientDevice {
 public:
  // Callback with register type, address and value (coils and discrete inputs: 0/1).
  using Callback = std::function<void(EntityType kind, uint16_t address, uint16_t value)>;

  SingleReader(esphome::modbus::ModbusClientHub *hub, uint8_t device_address, Callback callback)
      : ModbusClientDevice(hub, device_address), callback_(std::move(callback)) {}

  // Queues a single read. false = refused by the hub; no callback follows.
  bool read_one(EntityType kind, uint16_t address) { return this->read_entities(kind, address, 1); }

  // Prefix as used in the register map: IR, HR, DI, CO.
  static const char *prefix(EntityType kind) {
    switch (kind) {
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
  void on_read_registers(EntityType kind, uint16_t address, std::span<const uint16_t> values,
                         esphome::modbus::ResponseStatus status) override {
    if (!esphome::modbus::succeeded(status) || values.empty())
      return;
    this->callback_(kind, address, values[0]);
  }
  void on_read_bits(EntityType kind, uint16_t address, esphome::modbus::PackedBits bits,
                    esphome::modbus::ResponseStatus status) override {
    if (!esphome::modbus::succeeded(status) || bits.size() == 0)
      return;
    this->callback_(kind, address, bits[0] ? 1 : 0);
  }

 private:
  Callback callback_;
};

}  // namespace single_reader
