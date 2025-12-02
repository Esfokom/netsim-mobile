import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Verify ARP cache conditions
class ArpCacheVerifier {
  /// Verify an ARP cache condition
  static bool verify({
    required EndDevice device,
    required ArpCachePropertyType property,
    String? targetIp,
    required PropertyOperator operator,
    required String expectedValue,
  }) {
    switch (property) {
      case ArpCachePropertyType.hasArpEntry:
        // Check if ARP cache has entry for specific IP
        if (targetIp == null) return false;
        final macAddress = device.arpCacheStructured.lookup(targetIp);
        final hasEntry = macAddress != null;
        final expected = expectedValue.toLowerCase() == 'true';
        return _compareBoolean(hasEntry, operator, expected);

      case ArpCachePropertyType.arpEntryMac:
        // Check if MAC for IP matches expected value
        if (targetIp == null) return false;
        final mac = device.arpCacheStructured.lookup(targetIp);
        if (mac == null) return false;
        return _compareStrings(mac, operator, expectedValue);

      case ArpCachePropertyType.arpEntryCount:
        // Check total ARP entries (valid entries only)
        final count = device.arpCacheStructured.validEntries.length;
        final expected = int.tryParse(expectedValue) ?? 0;
        return _compareIntegers(count, operator, expected);
    }
  }

  /// Compare booleans based on operator
  static bool _compareBoolean(
    bool actual,
    PropertyOperator operator,
    bool expected,
  ) {
    switch (operator) {
      case PropertyOperator.equals:
        return actual == expected;
      case PropertyOperator.notEquals:
        return actual != expected;
      default:
        return false;
    }
  }

  /// Compare strings based on operator
  static bool _compareStrings(
    String actual,
    PropertyOperator operator,
    String expected,
  ) {
    switch (operator) {
      case PropertyOperator.equals:
        return actual == expected;
      case PropertyOperator.notEquals:
        return actual != expected;
      case PropertyOperator.contains:
        return actual.contains(expected);
      default:
        return false;
    }
  }

  /// Compare integers based on operator
  static bool _compareIntegers(
    int actual,
    PropertyOperator operator,
    int expected,
  ) {
    switch (operator) {
      case PropertyOperator.equals:
        return actual == expected;
      case PropertyOperator.notEquals:
        return actual != expected;
      case PropertyOperator.greaterThan:
        return actual > expected;
      case PropertyOperator.lessThan:
        return actual < expected;
      default:
        return false;
    }
  }
}
