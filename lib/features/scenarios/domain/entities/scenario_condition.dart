import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;

/// Types of conditions that can be checked
enum ConditionType {
  ping, // Ping protocol checks (ICMP, ARP) - RENAMED from connectivity
  deviceProperty, // Basic device properties (RENAMED from propertyCheck)
  interfaceProperty, // NEW: Interface-specific checks
  arpCacheCheck, // NEW: ARP cache validation
  routingTableCheck, // NEW: Routing table validation
  linkCheck, // NEW: Connection/topology validation
  composite, // NEW: Multiple combined conditions
}

/// Ping protocol types
enum PingProtocolType {
  icmp, // ICMP Echo Request/Reply
  arp, // ARP Request/Reply
}

/// Ping check types (legacy - kept for backwards compatibility)
enum PingCheckType {
  sent, // Check if a packet was sent
  received, // Check if any packet was received
  receivedFromAny, // Check if packet received from any source
  receivedFromSpecific, // Check if packet received from specific source
  responseTime, // Check response time threshold
  finalReply, // Check if final ICMP reply was received
}

/// Ping session check types (new session-based verification)
enum PingSessionCheckType {
  responseTime, // Check response time with operator (greater/less than)
  timeout, // Check if ping session timed out
  hasArp, // Check if ping session has ARP events
  hasIcmp, // Check if ping session has ICMP events
  success, // Check if ping was successful (last event is ICMP echo reply from dest to source)
}

/// Response time comparison operator
enum ResponseTimeOperator {
  greaterThan, // Response time > threshold
  lessThan, // Response time < threshold
}

/// ICMP event types for condition checks
enum IcmpEventType {
  sent, // Packet sent event
  received, // Packet received event
}

/// Device scope for ping conditions
enum PingDeviceScope {
  anyDevice, // From/to any device
  specificDevice, // From/to a specific device
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

  // Ping-specific fields (legacy - kept for backwards compatibility)
  final String? sourceDeviceID;
  final String? targetAddress;
  final PingProtocolType? protocolType; // ICMP or ARP
  final PingCheckType? pingCheckType; // Type of check to perform (legacy)
  final String? targetDeviceIdForPing; // Target device ID for device selection
  final int?
  responseTimeThreshold; // Milliseconds threshold for response time checks

  // ICMP-specific fields (legacy)
  final IcmpEventType? icmpEventType; // Sent or Received event
  final PingDeviceScope? icmpDeviceScope; // Any device or specific device
  final String? icmpSpecificDeviceId; // Specific device ID for scope

  // NEW: Ping session-based verification fields
  final PingSessionCheckType?
  pingSessionCheckType; // New session-based check type
  final ResponseTimeOperator?
  responseTimeOperator; // Greater/less than for response time
  final String? sourceDeviceIdForSession; // Source device for ping session
  final String?
  sourceInterfaceForSession; // Source interface name (to derive IP)
  final String? destDeviceIdForSession; // Destination device for ping session
  final String?
  destInterfaceForSession; // Destination interface name (to derive IP)

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
    this.protocolType,
    this.pingCheckType,
    this.targetDeviceIdForPing,
    this.responseTimeThreshold,
    this.icmpEventType,
    this.icmpDeviceScope,
    this.icmpSpecificDeviceId,
    // NEW: Ping session fields
    this.pingSessionCheckType,
    this.responseTimeOperator,
    this.sourceDeviceIdForSession,
    this.sourceInterfaceForSession,
    this.destDeviceIdForSession,
    this.destInterfaceForSession,
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
    PingProtocolType? protocolType,
    PingCheckType? pingCheckType,
    String? targetDeviceIdForPing,
    int? responseTimeThreshold,
    IcmpEventType? icmpEventType,
    PingDeviceScope? icmpDeviceScope,
    String? icmpSpecificDeviceId,
    // NEW: Ping session fields
    PingSessionCheckType? pingSessionCheckType,
    ResponseTimeOperator? responseTimeOperator,
    String? sourceDeviceIdForSession,
    String? sourceInterfaceForSession,
    String? destDeviceIdForSession,
    String? destInterfaceForSession,
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
      protocolType: protocolType ?? this.protocolType,
      pingCheckType: pingCheckType ?? this.pingCheckType,
      targetDeviceIdForPing:
          targetDeviceIdForPing ?? this.targetDeviceIdForPing,
      responseTimeThreshold:
          responseTimeThreshold ?? this.responseTimeThreshold,
      icmpEventType: icmpEventType ?? this.icmpEventType,
      icmpDeviceScope: icmpDeviceScope ?? this.icmpDeviceScope,
      icmpSpecificDeviceId: icmpSpecificDeviceId ?? this.icmpSpecificDeviceId,
      // NEW: Ping session fields
      pingSessionCheckType: pingSessionCheckType ?? this.pingSessionCheckType,
      responseTimeOperator: responseTimeOperator ?? this.responseTimeOperator,
      sourceDeviceIdForSession:
          sourceDeviceIdForSession ?? this.sourceDeviceIdForSession,
      sourceInterfaceForSession:
          sourceInterfaceForSession ?? this.sourceInterfaceForSession,
      destDeviceIdForSession:
          destDeviceIdForSession ?? this.destDeviceIdForSession,
      destInterfaceForSession:
          destInterfaceForSession ?? this.destInterfaceForSession,
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
      if (protocolType != null)
        'protocolType': protocolType!.name.toUpperCase(),
      if (pingCheckType != null)
        'pingCheckType': pingCheckType!.name.toUpperCase(),
      if (targetDeviceIdForPing != null)
        'targetDeviceIdForPing': targetDeviceIdForPing,
      if (responseTimeThreshold != null)
        'responseTimeThreshold': responseTimeThreshold,
      if (icmpEventType != null)
        'icmpEventType': icmpEventType!.name.toUpperCase(),
      if (icmpDeviceScope != null)
        'icmpDeviceScope': icmpDeviceScope!.name.toUpperCase(),
      if (icmpSpecificDeviceId != null)
        'icmpSpecificDeviceId': icmpSpecificDeviceId,
      // NEW: Ping session fields serialization
      if (pingSessionCheckType != null)
        'pingSessionCheckType': pingSessionCheckType!.name.toUpperCase(),
      if (responseTimeOperator != null)
        'responseTimeOperator': responseTimeOperator!.name.toUpperCase(),
      if (sourceDeviceIdForSession != null)
        'sourceDeviceIdForSession': sourceDeviceIdForSession,
      if (sourceInterfaceForSession != null)
        'sourceInterfaceForSession': sourceInterfaceForSession,
      if (destDeviceIdForSession != null)
        'destDeviceIdForSession': destDeviceIdForSession,
      if (destInterfaceForSession != null)
        'destInterfaceForSession': destInterfaceForSession,
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

    // Try to match enum by lowercase comparison
    var type = ConditionType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr,
      orElse: () {
        // Legacy support for old type names
        if (typeStr == 'propertycheck') {
          return ConditionType.deviceProperty;
        }
        // Default fallback
        return ConditionType.deviceProperty;
      },
    );

    // MIGRATION: Convert old connectivity type to ping
    if (typeStr == 'connectivity') {
      if (json['protocol'] != null) {
        final protocolStr = json['protocol'].toString().toLowerCase();
        if (protocolStr == 'link') {
          type = ConditionType.linkCheck;
        } else {
          type = ConditionType.ping; // Convert connectivity to ping
        }
      } else {
        type = ConditionType.ping; // Default connectivity to ping
      }
    }

    // Parse ping-specific enums
    PingProtocolType? protocolType;
    if (json['protocolType'] != null) {
      final protocolStr = json['protocolType'].toString().toLowerCase();
      protocolType = PingProtocolType.values.firstWhere(
        (e) => e.name.toLowerCase() == protocolStr,
        orElse: () => PingProtocolType.icmp,
      );
    }

    PingCheckType? pingCheckType;
    if (json['pingCheckType'] != null) {
      final checkTypeStr = json['pingCheckType'].toString().toLowerCase();
      pingCheckType = PingCheckType.values.firstWhere(
        (e) => e.name.toLowerCase() == checkTypeStr,
        orElse: () => PingCheckType.sent,
      );
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
        (e) => e.name.toLowerCase() == logicStr,
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

    // Parse ICMP-specific enums
    IcmpEventType? icmpEventType;
    if (json['icmpEventType'] != null) {
      final eventTypeStr = json['icmpEventType'].toString().toLowerCase();
      icmpEventType = IcmpEventType.values.firstWhere(
        (e) => e.name.toLowerCase() == eventTypeStr,
        orElse: () => IcmpEventType.sent,
      );
    }

    PingDeviceScope? icmpDeviceScope;
    if (json['icmpDeviceScope'] != null) {
      final scopeStr = json['icmpDeviceScope'].toString().toLowerCase();
      icmpDeviceScope = PingDeviceScope.values.firstWhere(
        (e) => e.name.toLowerCase() == scopeStr,
        orElse: () => PingDeviceScope.anyDevice,
      );
    }

    // Parse link check mode with migration support
    LinkCheckMode? linkCheckMode;
    if (json['linkCheckMode'] != null) {
      final modeStr = json['linkCheckMode'].toString().toLowerCase();
      linkCheckMode = LinkCheckMode.values.firstWhere(
        (e) => e.name.toLowerCase() == modeStr,
        orElse: () => LinkCheckMode.linkCount, // Default to linkCount
      );
    } else if (type == ConditionType.linkCheck) {
      // Migration: old linkCheck conditions default to linkCount mode
      linkCheckMode = LinkCheckMode.linkCount;
    }

    // Parse ping session check type
    PingSessionCheckType? pingSessionCheckType;
    if (json['pingSessionCheckType'] != null) {
      final checkTypeStr = json['pingSessionCheckType']
          .toString()
          .toLowerCase();
      pingSessionCheckType = PingSessionCheckType.values.firstWhere(
        (e) => e.name.toLowerCase() == checkTypeStr,
        orElse: () => PingSessionCheckType.success,
      );
    }

    // Parse response time operator
    ResponseTimeOperator? responseTimeOperator;
    if (json['responseTimeOperator'] != null) {
      final operatorStr = json['responseTimeOperator'].toString().toLowerCase();
      responseTimeOperator = ResponseTimeOperator.values.firstWhere(
        (e) => e.name.toLowerCase() == operatorStr,
        orElse: () => ResponseTimeOperator.lessThan,
      );
    }

    return ScenarioCondition(
      id: json['id'] as String,
      description: json['description'] as String,
      type: type,
      sourceDeviceID: json['sourceDeviceID'] as String?,
      targetAddress: json['targetAddress'] as String?,
      protocolType: protocolType,
      pingCheckType: pingCheckType,
      targetDeviceIdForPing: json['targetDeviceIdForPing'] as String?,
      responseTimeThreshold: json['responseTimeThreshold'] as int?,
      icmpEventType: icmpEventType,
      icmpDeviceScope: icmpDeviceScope,
      icmpSpecificDeviceId: json['icmpSpecificDeviceId'] as String?,
      // NEW: Ping session fields
      pingSessionCheckType: pingSessionCheckType,
      responseTimeOperator: responseTimeOperator,
      sourceDeviceIdForSession: json['sourceDeviceIdForSession'] as String?,
      sourceInterfaceForSession: json['sourceInterfaceForSession'] as String?,
      destDeviceIdForSession: json['destDeviceIdForSession'] as String?,
      destInterfaceForSession: json['destInterfaceForSession'] as String?,
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
      case ConditionType.ping:
        return 'Ping';
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

extension PingSessionCheckTypeExtension on PingSessionCheckType {
  String get displayName {
    switch (this) {
      case PingSessionCheckType.responseTime:
        return 'Response Time';
      case PingSessionCheckType.timeout:
        return 'Timeout';
      case PingSessionCheckType.hasArp:
        return 'Has ARP';
      case PingSessionCheckType.hasIcmp:
        return 'Has ICMP';
      case PingSessionCheckType.success:
        return 'Success';
    }
  }

  String get description {
    switch (this) {
      case PingSessionCheckType.responseTime:
        return 'Check if response time is greater or less than threshold';
      case PingSessionCheckType.timeout:
        return 'Check if ping session timed out';
      case PingSessionCheckType.hasArp:
        return 'Check if session includes ARP resolution';
      case PingSessionCheckType.hasIcmp:
        return 'Check if session includes ICMP packets';
      case PingSessionCheckType.success:
        return 'Check if ping was successful (received ICMP echo reply)';
    }
  }

  IconData get icon {
    switch (this) {
      case PingSessionCheckType.responseTime:
        return Icons.timer;
      case PingSessionCheckType.timeout:
        return Icons.timer_off;
      case PingSessionCheckType.hasArp:
        return Icons.swap_horiz;
      case PingSessionCheckType.hasIcmp:
        return Icons.network_ping;
      case PingSessionCheckType.success:
        return Icons.check_circle;
    }
  }
}

extension ResponseTimeOperatorExtension on ResponseTimeOperator {
  String get displayName {
    switch (this) {
      case ResponseTimeOperator.greaterThan:
        return 'Greater Than';
      case ResponseTimeOperator.lessThan:
        return 'Less Than';
    }
  }

  String get symbol {
    switch (this) {
      case ResponseTimeOperator.greaterThan:
        return '>';
      case ResponseTimeOperator.lessThan:
        return '<';
    }
  }
}
