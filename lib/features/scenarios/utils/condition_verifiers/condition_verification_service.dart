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
    appLogger.d(
      '[ConditionVerification] Verifying ${conditions.length} conditions',
    );
    appLogger.d(
      '[ConditionVerification] Canvas has ${canvasState.devices.length} devices, ${canvasState.links.length} links',
    );

    final results = <String, bool>{};

    for (final condition in conditions) {
      appLogger.d(
        '[ConditionVerification] Checking: ${condition.description} (${condition.type})',
      );
      final result = verifyCondition(condition, canvasState);
      results[condition.id] = result;
      appLogger.d(
        '[ConditionVerification] Result: ${result ? "PASSED ✓" : "FAILED ✗"}',
      );
    }

    appLogger.d('[ConditionVerification] Total results: ${results.length}');
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
    // Connectivity check is for ping - check if two devices are connected
    // For now, we check if a direct link exists between source and target
    if (condition.sourceDeviceID == null || condition.targetAddress == null) {
      appLogger.w(
        '[ConditionVerification] Missing source or target for connectivity check',
      );
      return false;
    }

    // Try to find if targetAddress is a device ID
    final targetDeviceId = condition.targetAddress;

    // Check if a link exists between the two devices
    final linkExists = canvasState.links.any(
      (link) =>
          (link.fromDeviceId == condition.sourceDeviceID &&
              link.toDeviceId == targetDeviceId) ||
          (link.fromDeviceId == targetDeviceId &&
              link.toDeviceId == condition.sourceDeviceID),
    );

    appLogger.d(
      '[ConditionVerification] Connectivity check: source=${condition.sourceDeviceID}, target=$targetDeviceId, linkExists=$linkExists',
    );

    return linkExists;
  }

  bool _verifyDeviceProperty(
    ScenarioCondition condition,
    CanvasState canvasState,
  ) {
    // Log available devices for debugging
    appLogger.d(
      '[ConditionVerification] Available networkDevices: ${canvasState.networkDevices.keys.toList()}',
    );
    appLogger.d(
      '[ConditionVerification] Looking for device: ${condition.targetDeviceID}',
    );
    appLogger.d(
      '[ConditionVerification] Property to check: ${condition.property}',
    );

    // Get the device
    final device = canvasState.networkDevices[condition.targetDeviceID];
    if (device == null) {
      appLogger.w(
        '[ConditionVerification] Device not found: ${condition.targetDeviceID}',
      );
      appLogger.w(
        '[ConditionVerification] Available devices in networkDevices map: ${canvasState.networkDevices.keys.join(", ")}',
      );
      appLogger.w(
        '[ConditionVerification] Total canvas devices: ${canvasState.devices.length}',
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
    // Use mode-aware verification if mode is specified
    if (condition.linkCheckMode != null) {
      return LinkVerifier.verifyWithMode(
        mode: condition.linkCheckMode!,
        allLinks: canvasState.links,
        sourceDeviceId:
            condition.linkCheckMode == LinkCheckMode.booleanLinkStatus
            ? condition.sourceDeviceIDForLink
            : condition.targetDeviceID,
        targetDeviceId: condition.targetDeviceIdForLink,
        operator: condition.operator ?? PropertyOperator.equals,
        expectedValue: condition.expectedValue ?? '',
      );
    }

    // Legacy support: use old property-based verification
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

    // Verify using LinkVerifier (legacy)
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
