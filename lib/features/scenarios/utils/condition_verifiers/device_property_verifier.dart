import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Verify device property conditions
class DevicePropertyVerifier {
  /// Verify a device property condition
  static bool verify({
    required NetworkDevice device,
    required DevicePropertyType property,
    required PropertyOperator operator,
    required String expectedValue,
  }) {
    // Get actual value based on property type
    switch (property) {
      case DevicePropertyType.hostname:
        if (device is! EndDevice) return false;
        return _compareStrings(device.hostname, operator, expectedValue);

      case DevicePropertyType.deviceId:
        return _compareStrings(device.deviceId, operator, expectedValue);

      case DevicePropertyType.deviceType:
        return _compareStrings(device.deviceType, operator, expectedValue);

      case DevicePropertyType.powerState:
        // FIXED: Now boolean comparison (not string "ON"/"OFF")
        if (device is! EndDevice) return false;
        final isPoweredOn = device.isPoweredOn;
        final expected = expectedValue.toLowerCase() == 'true';
        return _compareBooleans(isPoweredOn, operator, expected);

      case DevicePropertyType.linkState:
        // FIXED: Now boolean comparison (not string "UP"/"DOWN")
        if (device is! EndDevice) return false;
        final isLinkUp = device.linkState == 'UP';
        final expected = expectedValue.toLowerCase() == 'true';
        return _compareBooleans(isLinkUp, operator, expected);

      case DevicePropertyType.operationalStatus:
        return _compareStrings(device.status.name, operator, expectedValue);

      case DevicePropertyType.ipAddress:
        if (device is! EndDevice) return false;
        return _compareStrings(
          device.currentIpAddress ?? '',
          operator,
          expectedValue,
        );

      case DevicePropertyType.macAddress:
        if (device is! EndDevice) return false;
        return _compareStrings(device.macAddress, operator, expectedValue);

      case DevicePropertyType.subnetMask:
        if (device is! EndDevice) return false;
        return _compareStrings(
          device.currentSubnetMask ?? '',
          operator,
          expectedValue,
        );

      case DevicePropertyType.defaultGateway:
        if (device is! EndDevice) return false;
        return _compareStrings(
          device.currentDefaultGateway ?? '',
          operator,
          expectedValue,
        );

      case DevicePropertyType.ipConfigMode:
        if (device is! EndDevice) return false;
        return _compareStrings(device.ipConfigMode, operator, expectedValue);

      case DevicePropertyType.positionX:
        final x = device.position.dx.toInt();
        final expected = int.tryParse(expectedValue) ?? 0;
        return _compareIntegers(x, operator, expected);

      case DevicePropertyType.positionY:
        final y = device.position.dy.toInt();
        final expected = int.tryParse(expectedValue) ?? 0;
        return _compareIntegers(y, operator, expected);

      case DevicePropertyType.interfaceCount:
        if (device is! EndDevice) return false;
        final count = device.interfaces.length;
        final expected = int.tryParse(expectedValue) ?? 0;
        return _compareIntegers(count, operator, expected);
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

  /// Compare booleans based on operator
  static bool _compareBooleans(
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
