import 'package:flutter/foundation.dart';

/// Types of conditions that can be checked
enum ConditionType {
  connectivity, // Ping and link checks only
  deviceProperty, // Basic device properties (RENAMED from propertyCheck)
  interfaceProperty, // NEW: Interface-specific checks
  arpCacheCheck, // NEW: ARP cache validation
  routingTableCheck, // NEW: Routing table validation
  linkCheck, // NEW: Connection/topology validation
  composite, // NEW: Multiple combined conditions
}

/// Data types for properties
enum PropertyDataType { string, boolean, integer, ipAddress }

/// Operators for property checks
enum PropertyOperator { equals, notEquals, contains, greaterThan, lessThan }

/// NEW: Device property types
enum DevicePropertyType {
  // Identity
  hostname,
  deviceId,
  deviceType,

  // State (FIXED: powerState is now boolean)
  powerState, // boolean: true/false (not "ON"/"OFF")
  linkState, // boolean: true/false (not "UP"/"DOWN")
  operationalStatus, // string: "online"/"offline"/"error"
  // Network
  ipAddress,
  macAddress,
  subnetMask,
  defaultGateway,
  ipConfigMode, // string: "STATIC"/"DHCP"
  // Position
  positionX,
  positionY,

  // Counts
  interfaceCount,
}

/// NEW: Interface property types
enum InterfacePropertyType {
  interfaceName,
  interfaceStatus, // string: "UP"/"DOWN"/"DISABLED"
  interfaceIpAddress,
  interfaceMacAddress,
  interfaceSubnetMask,
  interfaceGateway,
  connectedDeviceId,
  connectedDeviceName,
}

/// NEW: Link property types
enum LinkPropertyType {
  linkCount, // integer: total connections
  isLinkedToDevice, // boolean: connected to specific device
  linkedDeviceIds, // array (for internal use)
}

/// Link check modes
enum LinkCheckMode {
  booleanLinkStatus, // Check if two devices are linked (true/false)
  linkCount, // Check total link count for a device (0-N)
}

/// NEW: ARP cache property types
enum ArpCachePropertyType {
  hasArpEntry, // boolean: has entry for IP
  arpEntryMac, // string: MAC for IP
  arpEntryCount, // integer: total entries
}

/// NEW: Routing table property types
enum RoutingTablePropertyType {
  hasRoute, // boolean: has route for destination
  routeGateway, // string: gateway IP for destination
  routeInterface, // string: interface for destination
  routeCount, // integer: total routes
  hasDefaultRoute, // boolean: has 0.0.0.0/0 route
}

/// NEW: Composite logic
enum CompositeLogic {
  and, // All sub-conditions must be true
  or, // At least one sub-condition must be true
}

/// Sub-condition for composite conditions
@immutable
class SubCondition {
  final String id;
  final ConditionType type;
  final Map<String, dynamic> parameters;
  final bool isHidden; // Don't show to students in UI

  const SubCondition({
    required this.id,
    required this.type,
    required this.parameters,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name.toUpperCase(),
    'parameters': parameters,
    'isHidden': isHidden,
  };

  factory SubCondition.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'].toString().toLowerCase();
    final type = ConditionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ConditionType.deviceProperty,
    );

    return SubCondition(
      id: json['id'] as String,
      type: type,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }
}

/// Represents a success condition for a scenario
@immutable
class ScenarioCondition {
  final String id;
  final String description;
  final ConditionType type;

  // Connectivity-specific fields (ping only)
  final String? sourceDeviceID;
  final String? targetAddress;

  // Property check-specific fields
  final String? targetDeviceID;
  final String? property;
  final PropertyDataType? propertyDataType;
  final PropertyOperator? operator;
  final String? expectedValue;

  // NEW: Interface-specific fields
  final String? interfaceName; // e.g., "eth0"

  // NEW: ARP/Routing check fields
  final String? targetIpForCheck; // IP to check in ARP/routing
  final String? targetNetworkForCheck; // Network for routing check

  // NEW: Link check fields
  final LinkCheckMode? linkCheckMode; // Mode for link checking
  final String? sourceDeviceIDForLink; // Source device for boolean link check
  final String? targetDeviceIdForLink; // Target device for boolean link check

  // NEW: Composite condition fields
  final List<SubCondition>? subConditions;
  final CompositeLogic? compositeLogic;

  const ScenarioCondition({
    required this.id,
    required this.description,
    required this.type,
    this.sourceDeviceID,
    this.targetAddress,
    this.targetDeviceID,
    this.property,
    this.propertyDataType,
    this.operator,
    this.expectedValue,
    this.interfaceName,
    this.targetIpForCheck,
    this.targetNetworkForCheck,
    this.linkCheckMode,
    this.sourceDeviceIDForLink,
    this.targetDeviceIdForLink,
    this.subConditions,
    this.compositeLogic,
  });

  ScenarioCondition copyWith({
    String? id,
    String? description,
    ConditionType? type,
    String? sourceDeviceID,
    String? targetAddress,
    String? targetDeviceID,
    String? property,
    PropertyDataType? propertyDataType,
    PropertyOperator? operator,
    String? expectedValue,
    String? interfaceName,
    String? targetIpForCheck,
    String? targetNetworkForCheck,
    LinkCheckMode? linkCheckMode,
    String? sourceDeviceIDForLink,
    String? targetDeviceIdForLink,
    List<SubCondition>? subConditions,
    CompositeLogic? compositeLogic,
  }) {
    return ScenarioCondition(
      id: id ?? this.id,
      description: description ?? this.description,
      type: type ?? this.type,
      sourceDeviceID: sourceDeviceID ?? this.sourceDeviceID,
      targetAddress: targetAddress ?? this.targetAddress,
      targetDeviceID: targetDeviceID ?? this.targetDeviceID,
      property: property ?? this.property,
      propertyDataType: propertyDataType ?? this.propertyDataType,
      operator: operator ?? this.operator,
      expectedValue: expectedValue ?? this.expectedValue,
      interfaceName: interfaceName ?? this.interfaceName,
      targetIpForCheck: targetIpForCheck ?? this.targetIpForCheck,
      targetNetworkForCheck:
          targetNetworkForCheck ?? this.targetNetworkForCheck,
      linkCheckMode: linkCheckMode ?? this.linkCheckMode,
      sourceDeviceIDForLink:
          sourceDeviceIDForLink ?? this.sourceDeviceIDForLink,
      targetDeviceIdForLink:
          targetDeviceIdForLink ?? this.targetDeviceIdForLink,
      subConditions: subConditions ?? this.subConditions,
      compositeLogic: compositeLogic ?? this.compositeLogic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type': type.name.toUpperCase(),
      if (sourceDeviceID != null) 'sourceDeviceID': sourceDeviceID,
      if (targetAddress != null) 'targetAddress': targetAddress,
      if (targetDeviceID != null) 'targetDeviceID': targetDeviceID,
      if (property != null) 'property': property,
      if (propertyDataType != null)
        'propertyDataType': propertyDataType!.name.toUpperCase(),
      if (operator != null) 'operator': operator!.name.toUpperCase(),
      if (expectedValue != null) 'expectedValue': expectedValue,
      if (interfaceName != null) 'interfaceName': interfaceName,
      if (targetIpForCheck != null) 'targetIpForCheck': targetIpForCheck,
      if (targetNetworkForCheck != null)
        'targetNetworkForCheck': targetNetworkForCheck,
      if (linkCheckMode != null)
        'linkCheckMode': linkCheckMode!.name.toUpperCase(),
      if (sourceDeviceIDForLink != null)
        'sourceDeviceIDForLink': sourceDeviceIDForLink,
      if (targetDeviceIdForLink != null)
        'targetDeviceIdForLink': targetDeviceIdForLink,
      if (subConditions != null)
        'subConditions': subConditions!.map((sc) => sc.toJson()).toList(),
      if (compositeLogic != null)
        'compositeLogic': compositeLogic!.name.toUpperCase(),
    };
  }

  factory ScenarioCondition.fromJson(Map<String, dynamic> json) {
    // Parse condition type with migration support
    final typeStr = json['type'].toString().toLowerCase();
    var type = ConditionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => typeStr == 'propertycheck'
          ? ConditionType
                .deviceProperty // Legacy support
          : ConditionType.deviceProperty,
    );

    // MIGRATION: Convert old connectivity+link protocol to linkCheck type
    if (typeStr == 'connectivity' && json['protocol'] != null) {
      final protocolStr = json['protocol'].toString().toLowerCase();
      if (protocolStr == 'link') {
        type = ConditionType.linkCheck;
      }
    }

    PropertyDataType? propertyDataType;
    if (json['propertyDataType'] != null) {
      final dataTypeStr = json['propertyDataType'].toString().toLowerCase();
      propertyDataType = dataTypeStr == 'string'
          ? PropertyDataType.string
          : dataTypeStr == 'boolean'
          ? PropertyDataType.boolean
          : dataTypeStr == 'integer'
          ? PropertyDataType.integer
          : PropertyDataType.ipAddress;
    }

    PropertyOperator? operator;
    if (json['operator'] != null) {
      final operatorStr = json['operator'].toString().toLowerCase();
      operator = operatorStr == 'equals'
          ? PropertyOperator.equals
          : operatorStr == 'notequals'
          ? PropertyOperator.notEquals
          : operatorStr == 'contains'
          ? PropertyOperator.contains
          : operatorStr == 'greaterthan'
          ? PropertyOperator.greaterThan
          : PropertyOperator.lessThan;
    }

    // Parse composite logic
    CompositeLogic? compositeLogic;
    if (json['compositeLogic'] != null) {
      final logicStr = json['compositeLogic'].toString().toLowerCase();
      compositeLogic = CompositeLogic.values.firstWhere(
        (e) => e.name == logicStr,
        orElse: () => CompositeLogic.and,
      );
    }

    // Parse sub-conditions
    List<SubCondition>? subConditions;
    if (json['subConditions'] != null) {
      subConditions = (json['subConditions'] as List)
          .map((sc) => SubCondition.fromJson(sc as Map<String, dynamic>))
          .toList();
    }

    // Parse link check mode with migration support
    LinkCheckMode? linkCheckMode;
    if (json['linkCheckMode'] != null) {
      final modeStr = json['linkCheckMode'].toString().toLowerCase();
      linkCheckMode = LinkCheckMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => LinkCheckMode.linkCount, // Default to linkCount
      );
    } else if (type == ConditionType.linkCheck) {
      // Migration: old linkCheck conditions default to linkCount mode
      linkCheckMode = LinkCheckMode.linkCount;
    }

    return ScenarioCondition(
      id: json['id'] as String,
      description: json['description'] as String,
      type: type,
      sourceDeviceID: json['sourceDeviceID'] as String?,
      targetAddress: json['targetAddress'] as String?,
      targetDeviceID: json['targetDeviceID'] as String?,
      property: json['property'] as String?,
      propertyDataType: propertyDataType,
      operator: operator,
      expectedValue: json['expectedValue'] as String?,
      interfaceName: json['interfaceName'] as String?,
      targetIpForCheck: json['targetIpForCheck'] as String?,
      targetNetworkForCheck: json['targetNetworkForCheck'] as String?,
      linkCheckMode: linkCheckMode,
      sourceDeviceIDForLink: json['sourceDeviceIDForLink'] as String?,
      targetDeviceIdForLink: json['targetDeviceIdForLink'] as String?,
      subConditions: subConditions,
      compositeLogic: compositeLogic,
    );
  }
}

extension ConditionTypeExtension on ConditionType {
  String get displayName {
    switch (this) {
      case ConditionType.connectivity:
        return 'Connectivity';
      case ConditionType.deviceProperty:
        return 'Device Property';
      case ConditionType.interfaceProperty:
        return 'Interface Property';
      case ConditionType.arpCacheCheck:
        return 'ARP Cache';
      case ConditionType.routingTableCheck:
        return 'Routing Table';
      case ConditionType.linkCheck:
        return 'Link Check';
      case ConditionType.composite:
        return 'Composite';
    }
  }
}

extension PropertyDataTypeExtension on PropertyDataType {
  String get displayName {
    switch (this) {
      case PropertyDataType.string:
        return 'String';
      case PropertyDataType.boolean:
        return 'Boolean';
      case PropertyDataType.integer:
        return 'Integer';
      case PropertyDataType.ipAddress:
        return 'IP Address';
    }
  }

  /// Get valid operators for this data type
  List<PropertyOperator> get validOperators {
    switch (this) {
      case PropertyDataType.boolean:
        return [PropertyOperator.equals, PropertyOperator.notEquals];
      case PropertyDataType.integer:
        return [
          PropertyOperator.equals,
          PropertyOperator.notEquals,
          PropertyOperator.greaterThan,
          PropertyOperator.lessThan,
        ];
      case PropertyDataType.string:
      case PropertyDataType.ipAddress:
        return [
          PropertyOperator.equals,
          PropertyOperator.notEquals,
          PropertyOperator.contains,
        ];
    }
  }
}

extension PropertyOperatorExtension on PropertyOperator {
  String get displayName {
    switch (this) {
      case PropertyOperator.equals:
        return 'Equals';
      case PropertyOperator.notEquals:
        return 'Not Equals';
      case PropertyOperator.contains:
        return 'Contains';
      case PropertyOperator.greaterThan:
        return 'Greater Than';
      case PropertyOperator.lessThan:
        return 'Less Than';
    }
  }

  String get symbol {
    switch (this) {
      case PropertyOperator.equals:
        return '==';
      case PropertyOperator.notEquals:
        return '!=';
      case PropertyOperator.contains:
        return '⊃';
      case PropertyOperator.greaterThan:
        return '>';
      case PropertyOperator.lessThan:
        return '<';
    }
  }
}
