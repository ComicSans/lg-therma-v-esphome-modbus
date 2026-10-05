#pragma once
// Names of the entities that read or write a Modbus register directly. One list
// for every evaluation: registers without response, register observation,
// reference comparison and invalidation on a bus outage. scripts/test.sh
// checks that it matches the modbus_controller entries in therma-v.yaml.
#include <cstring>

namespace register_list {

inline bool is_register(const char *name) {
  static const char *const NAMES[] = {
      // sensor
      "Outdoor Temperature Unit Sensor",
      "Room Temperature",
      "Water Return Temperature",
      "Water Flow Temperature",
      "Hot Water Temperature",
      "High Pressure",
      "Low Pressure",
      "Suction Gas Temperature",
      "Unit Apparent Power",
      "Compressor Shell Temperature",
      "Outdoor Heat Exchanger",
      "Outdoor Heat Exchanger (Mirror Register)",
      "IR14 Water Temperature Unassigned",
      "IR09 Constant",
      "IR13 Refrigerant Constant",
      "IR10 Unassigned",
      "Compressor Speed",
      "IR27 Unassigned",
      "Operating Mode Raw",
      "HR25 Unassigned",
      "HR27 Unassigned",
      "HR28 Unassigned",
      // binary_sensor
      "DI06 Unassigned",
      "Compressor Ready",
      "Compressor Top Stage",
      "DI09 Hot Water Mode",
      "CO5 Unassigned (Read Only)",
      "Heating Circuit 1 Inverted",
      "DI32 Unassigned",
      "Heating Circuit 1",
      "Outdoor Unit Running",
      "CO29 Unassigned",
      "CO30 Unassigned",
      // number, select, switch
      "Heating Circuit 1 Setpoint",
      "Hot Water Setpoint",
      "Operating Mode",
      "Silent Mode",
      "Hot Water Enable",
  };
  for (const char *n : NAMES)
    if (std::strcmp(n, name) == 0)
      return true;
  return false;
}

}  // namespace register_list
