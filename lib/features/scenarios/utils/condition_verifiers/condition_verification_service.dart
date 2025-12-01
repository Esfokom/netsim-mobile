import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/device_property_verifier.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/interface_property_verifier.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/arp_cache_verifier.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/routing_table_verifier.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/link_verifier.dart';
import 'package:netsim_mobile/features/scenarios/utils/condition_verifiers/composite_verifier.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// Master service for verifying all condition types
class ConditionVerificationService {
  /// Verify a single condition
  bool verifyCondition(ScenarioCondition condition, CanvasState canvasState) {
    try {
      switch (condition.type) {
        case ConditionType.connectivity:
          return _verifyConnectivity(condition, canvasState);

        case ConditionType.deviceProperty:
          return _verifyDeviceProperty(condition, canvasState);

        case ConditionType.interfaceProperty:
          return _verifyInterfaceProperty(condition, canvasState);

        case ConditionType.arpCacheCheck:
          return _verifyArpCache(condition, canvasState);

        case ConditionType.routingTableCheck:
          return _verifyRoutingTable(condition, canvasState);

        case ConditionType.linkCheck:
          return _verifyLink(condition, canvasState);

        case ConditionType.composite:
          return _verifyComposite(condition, canvasState);
      }
    } catch (e, stackTrace) {
      appLogger.e(
        '[ConditionVerification] Error verifying condition ${condition.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Verify all conditions in a list
  Map<String, bool> verifyAllConditions(
    List<ScenarioCondition> conditions,
    CanvasState canvasState,
  ) {
    final results = <String, bool>{};

    for (final condition in conditions) {
      results[condition.id] = verifyCondition(condition, canvasState);
    }

    return results;
  }

  /// Check if all conditions are satisfied
  bool areAllConditionsSatisfied(
    List<ScenarioCondition> conditions,
    CanvasState canvasState,
  ) {
    if (conditions.isEmpty) return false;

    return conditions.every((condition) {
      return verifyCondition(condition, canvasState);
    });
  }

  // Private verification methods

  bool _verifyConnectivity(
    ScenarioCondition condition,
    CanvasState canvasState,
  ) {
    // TODO: Implement connectivity check (ping/link)
    // This would involve checking simulation results or ping history
    appLogger.d(
      '[ConditionVerification] Connectivity check not yet implemented',
    );
    return false;
  }

  bool _verifyDeviceProperty(
    ScenarioCondition condition,
    CanvasState canvasState,
  ) {
    // Get the device
    final device = canvasState.networkDevices[condition.targetDeviceID];
    if (device == null) {
      appLogger.w(
        '[ConditionVerification] Device not found: ${condition.targetDeviceID}',
      );
      return false;
    }

    // Parse property type
    final propertyType = _parseDevicePropertyType(condition.property);
    if (propertyType == null) {
      appLogger.w(
        '[ConditionVerification] Invalid property type: ${condition.property}',
      );
      return false;
    }

    // Verify using DevicePropertyVerifier
    return DevicePropertyVerifier.verify(
      device: device,
      property: propertyType,
      operator: condition.operator ?? PropertyOperator.equals,
      expectedValue: condition.expectedValue ?? '',
    );
  }

  bool _verifyInterfaceProperty(
    ScenarioCondition condition,
    CanvasState canvasState,
  ) {
    // Get the device
    final device = canvasState.networkDevices[condition.targetDeviceID];
    if (device is! EndDevice) {
      appLogger.w(
        '[ConditionVerification] Device is not an EndDevice: ${condition.targetDeviceID}',
      );
      return false;
    }

    if (condition.interfaceName == null) {
      appLogger.w('[ConditionVerification] Interface name is null');
      return false;
    }

    // Parse property type
    final propertyType = _parseInterfacePropertyType(condition.property);
    if (propertyType == null) {
      appLogger.w(
        '[ConditionVerification] Invalid interface property: ${condition.property}',
      );
      return false;
    }

    // Verify using InterfacePropertyVerifier
    return InterfacePropertyVerifier.verify(
      device: device,
      interfaceName: condition.interfaceName!,
      property: propertyType,
      operator: condition.operator ?? PropertyOperator.equals,
      expectedValue: condition.expectedValue ?? '',
    );
  }

  bool _verifyArpCache(ScenarioCondition condition, CanvasState canvasState) {
    // Get the device
    final device = canvasState.networkDevices[condition.targetDeviceID];
    if (device is! EndDevice) {
      appLogger.w(
        '[ConditionVerification] Device is not an EndDevice: ${condition.targetDeviceID}',
      );
      return false;
    }

    // Parse property type
    final propertyType = _parseArpCachePropertyType(condition.property);
    if (propertyType == null) {
      appLogger.w(
        '[ConditionVerification] Invalid ARP property: ${condition.property}',
      );
      return false;
    }

    // Verify using ArpCacheVerifier
    return ArpCacheVerifier.verify(
      device: device,
      property: propertyType,
      targetIp: condition.targetIpForCheck,
      operator: condition.operator ?? PropertyOperator.equals,
      expectedValue: condition.expectedValue ?? '',
    );
  }

  bool _verifyRoutingTable(
    ScenarioCondition condition,
    CanvasState canvasState,
  ) {
    // Get the device
    final device = canvasState.networkDevices[condition.targetDeviceID];
    if (device is! EndDevice) {
      appLogger.w(
        '[ConditionVerification] Device is not an EndDevice: ${condition.targetDeviceID}',
      );
      return false;
    }

    // Parse property type
    final propertyType = _parseRoutingTablePropertyType(condition.property);
    if (propertyType == null) {
      appLogger.w(
        '[ConditionVerification] Invalid routing property: ${condition.property}',
      );
      return false;
    }

    // Verify using RoutingTableVerifier
    return RoutingTableVerifier.verify(
      device: device,
      property: propertyType,
      targetNetwork: condition.targetNetworkForCheck,
      operator: condition.operator ?? PropertyOperator.equals,
      expectedValue: condition.expectedValue ?? '',
    );
  }

  bool _verifyLink(ScenarioCondition condition, CanvasState canvasState) {
    // Get the canvas device
    final canvasDevice = canvasState.devices.firstWhere(
      (d) => d.id == condition.targetDeviceID,
      orElse: () =>
          throw Exception('Device not found: ${condition.targetDeviceID}'),
    );

    // Parse property type
    final propertyType = _parseLinkPropertyType(condition.property);
    if (propertyType == null) {
      appLogger.w(
        '[ConditionVerification] Invalid link property: ${condition.property}',
      );
      return false;
    }

    // Verify using LinkVerifier
    return LinkVerifier.verify(
      device: canvasDevice,
      allLinks: canvasState.links,
      property: propertyType,
      targetDeviceId: condition.targetDeviceIdForLink,
      operator: condition.operator ?? PropertyOperator.equals,
      expectedValue: condition.expectedValue ?? '',
    );
  }

  bool _verifyComposite(ScenarioCondition condition, CanvasState canvasState) {
    // Verify using CompositeVerifier
    return CompositeVerifier.verify(
      condition: condition,
      canvasState: canvasState,
      verifySubCondition: (subCondition, state) {
        // Convert SubCondition to ScenarioCondition and verify
        final scenarioCondition =
            CompositeVerifier.subConditionToScenarioCondition(subCondition);
        return verifyCondition(scenarioCondition, state);
      },
    );
  }

  // Helper methods to parse enum types from strings

  DevicePropertyType? _parseDevicePropertyType(String? property) {
    if (property == null) return null;
    try {
      return DevicePropertyType.values.firstWhere((e) => e.name == property);
    } catch (e) {
      appLogger.w(
        '[ConditionVerification] Failed to parse DevicePropertyType: $property',
      );
      return null;
    }
  }

  InterfacePropertyType? _parseInterfacePropertyType(String? property) {
    if (property == null) return null;
    try {
      return InterfacePropertyType.values.firstWhere((e) => e.name == property);
    } catch (e) {
      appLogger.w(
        '[ConditionVerification] Failed to parse InterfacePropertyType: $property',
      );
      return null;
    }
  }

  ArpCachePropertyType? _parseArpCachePropertyType(String? property) {
    if (property == null) return null;
    try {
      return ArpCachePropertyType.values.firstWhere((e) => e.name == property);
    } catch (e) {
      appLogger.w(
        '[ConditionVerification] Failed to parse ArpCachePropertyType: $property',
      );
      return null;
    }
  }

  RoutingTablePropertyType? _parseRoutingTablePropertyType(String? property) {
    if (property == null) return null;
    try {
      return RoutingTablePropertyType.values.firstWhere(
        (e) => e.name == property,
      );
    } catch (e) {
      appLogger.w(
        '[ConditionVerification] Failed to parse RoutingTablePropertyType: $property',
      );
      return null;
    }
  }

  LinkPropertyType? _parseLinkPropertyType(String? property) {
    if (property == null) return null;
    try {
      return LinkPropertyType.values.firstWhere((e) => e.name == property);
    } catch (e) {
      appLogger.w(
        '[ConditionVerification] Failed to parse LinkPropertyType: $property',
      );
      return null;
    }
  }
}
