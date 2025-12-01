import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Verify interface property conditions
class InterfacePropertyVerifier {
  /// Verify an interface property condition
  static bool verify({
    required EndDevice device,
    required String interfaceName,
    required InterfacePropertyType property,
    required PropertyOperator operator,
    required String expectedValue,
  }) {
    // Get the interface
    final interface = device.getInterface(interfaceName);
    if (interface == null) return false;

    // Check property based on type
    switch (property) {
      case InterfacePropertyType.interfaceName:
        return _compareStrings(interface.name, operator, expectedValue);

      case InterfacePropertyType.interfaceStatus:
        final status = interface.status.name.toUpperCase();
        return _compareStrings(status, operator, expectedValue);

      case InterfacePropertyType.interfaceIpAddress:
        return _compareStrings(
          interface.ipAddress ?? '',
          operator,
          expectedValue,
        );

      case InterfacePropertyType.interfaceMacAddress:
        return _compareStrings(interface.macAddress, operator, expectedValue);

      case InterfacePropertyType.interfaceSubnetMask:
        return _compareStrings(
          interface.subnetMask ?? '',
          operator,
          expectedValue,
        );

      case InterfacePropertyType.interfaceGateway:
        return _compareStrings(
          interface.defaultGateway ?? '',
          operator,
          expectedValue,
        );

      case InterfacePropertyType.connectedDeviceId:
        return _compareStrings(
          interface.connectedDeviceId ?? '',
          operator,
          expectedValue,
        );

      case InterfacePropertyType.connectedDeviceName:
        // This would require canvas context to look up device name from ID
        // For now, return false - can be implemented when canvas context is available
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
}
