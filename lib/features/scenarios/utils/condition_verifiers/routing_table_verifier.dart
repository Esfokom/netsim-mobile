import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Verify routing table conditions
class RoutingTableVerifier {
  /// Verify a routing table condition
  static bool verify({
    required EndDevice device,
    required RoutingTablePropertyType property,
    String? targetNetwork,
    required PropertyOperator operator,
    required String expectedValue,
  }) {
    switch (property) {
      case RoutingTablePropertyType.hasRoute:
        // Check if routing table has route for destination
        if (targetNetwork == null) return false;
        final route = device.routingTable.longestPrefixMatch(targetNetwork);
        final hasRoute = route != null;
        final expected = expectedValue.toLowerCase() == 'true';
        return _compareBoolean(hasRoute, operator, expected);

      case RoutingTablePropertyType.routeGateway:
        // Check gateway for specific route
        if (targetNetwork == null) return false;
        final route = device.routingTable.longestPrefixMatch(targetNetwork);
        if (route == null) return false;
        final gateway = route.gateway ?? '';
        return _compareStrings(gateway, operator, expectedValue);

      case RoutingTablePropertyType.routeInterface:
        // Check interface for specific route
        if (targetNetwork == null) return false;
        final route = device.routingTable.longestPrefixMatch(targetNetwork);
        if (route == null) return false;
        return _compareStrings(route.interfaceName, operator, expectedValue);

      case RoutingTablePropertyType.routeCount:
        // Check total number of routes
        final count = device.routingTable.entries.length;
        final expected = int.tryParse(expectedValue) ?? 0;
        return _compareIntegers(count, operator, expected);

      case RoutingTablePropertyType.hasDefaultRoute:
        // Check if default route exists
        final defaultRoute = device.routingTable.getDefaultRoute();
        final hasDefault = defaultRoute != null;
        final expected = expectedValue.toLowerCase() == 'true';
        return _compareBoolean(hasDefault, operator, expected);
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
