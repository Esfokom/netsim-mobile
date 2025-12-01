import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart';
import 'package:netsim_mobile/features/canvas/data/models/device_link.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Verify link/connection conditions
class LinkVerifier {
  /// Verify a link condition
  static bool verify({
    required CanvasDevice device,
    required List<DeviceLink> allLinks,
    required LinkPropertyType property,
    String? targetDeviceId,
    required PropertyOperator operator,
    required String expectedValue,
  }) {
    // Get all links connected to this device
    final deviceLinks = allLinks
        .where(
          (link) =>
              link.fromDeviceId == device.id || link.toDeviceId == device.id,
        )
        .toList();

    switch (property) {
      case LinkPropertyType.linkCount:
        // Check total number of connections
        final count = deviceLinks.length;
        final expected = int.tryParse(expectedValue) ?? 0;
        return _compareIntegers(count, operator, expected);

      case LinkPropertyType.isLinkedToDevice:
        // Check if connected to specific device
        if (targetDeviceId == null) return false;
        final isLinked = deviceLinks.any(
          (link) =>
              link.fromDeviceId == targetDeviceId ||
              link.toDeviceId == targetDeviceId,
        );
        final expected = expectedValue.toLowerCase() == 'true';
        return _compareBoolean(isLinked, operator, expected);

      case LinkPropertyType.linkedDeviceIds:
        // Not directly checkable as single value
        // This would be used for more complex checks internally
        return false;
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
