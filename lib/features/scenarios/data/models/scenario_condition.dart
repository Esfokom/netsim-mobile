import 'package:flutter/foundation.dart';

/// Types of conditions that can be checked
enum ConditionType { connectivity, propertyCheck }

/// Protocol types for connectivity checks
enum ConnectivityProtocol { ping, http, dnsLookup }

/// Operators for property checks
enum PropertyOperator { equals, notEquals, contains }

/// Represents a success condition for a scenario
@immutable
class ScenarioCondition {
  final String id;
  final String description;
  final ConditionType type;

  // Connectivity-specific fields
  final ConnectivityProtocol? protocol;
  final String? sourceDeviceID;
  final String? targetAddress;

  // Property check-specific fields
  final String? targetDeviceID;
  final String? property;
  final PropertyOperator? operator;
  final String? expectedValue;

  const ScenarioCondition({
    required this.id,
    required this.description,
    required this.type,
    this.protocol,
    this.sourceDeviceID,
    this.targetAddress,
    this.targetDeviceID,
    this.property,
    this.operator,
    this.expectedValue,
  });

  ScenarioCondition copyWith({
    String? id,
    String? description,
    ConditionType? type,
    ConnectivityProtocol? protocol,
    String? sourceDeviceID,
    String? targetAddress,
    String? targetDeviceID,
    String? property,
    PropertyOperator? operator,
    String? expectedValue,
  }) {
    return ScenarioCondition(
      id: id ?? this.id,
      description: description ?? this.description,
      type: type ?? this.type,
      protocol: protocol ?? this.protocol,
      sourceDeviceID: sourceDeviceID ?? this.sourceDeviceID,
      targetAddress: targetAddress ?? this.targetAddress,
      targetDeviceID: targetDeviceID ?? this.targetDeviceID,
      property: property ?? this.property,
      operator: operator ?? this.operator,
      expectedValue: expectedValue ?? this.expectedValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type': type.name.toUpperCase(),
      if (protocol != null) 'protocol': protocol!.name.toUpperCase(),
      if (sourceDeviceID != null) 'sourceDeviceID': sourceDeviceID,
      if (targetAddress != null) 'targetAddress': targetAddress,
      if (targetDeviceID != null) 'targetDeviceID': targetDeviceID,
      if (property != null) 'property': property,
      if (operator != null) 'operator': operator!.name.toUpperCase(),
      if (expectedValue != null) 'expectedValue': expectedValue,
    };
  }

  factory ScenarioCondition.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'].toString().toLowerCase();
    final type = typeStr == 'connectivity'
        ? ConditionType.connectivity
        : ConditionType.propertyCheck;

    ConnectivityProtocol? protocol;
    if (json['protocol'] != null) {
      final protocolStr = json['protocol'].toString().toLowerCase();
      protocol = protocolStr == 'ping'
          ? ConnectivityProtocol.ping
          : protocolStr == 'http'
          ? ConnectivityProtocol.http
          : ConnectivityProtocol.dnsLookup;
    }

    PropertyOperator? operator;
    if (json['operator'] != null) {
      final operatorStr = json['operator'].toString().toLowerCase();
      operator = operatorStr == 'equals'
          ? PropertyOperator.equals
          : operatorStr == 'notequals'
          ? PropertyOperator.notEquals
          : PropertyOperator.contains;
    }

    return ScenarioCondition(
      id: json['id'] as String,
      description: json['description'] as String,
      type: type,
      protocol: protocol,
      sourceDeviceID: json['sourceDeviceID'] as String?,
      targetAddress: json['targetAddress'] as String?,
      targetDeviceID: json['targetDeviceID'] as String?,
      property: json['property'] as String?,
      operator: operator,
      expectedValue: json['expectedValue'] as String?,
    );
  }
}

extension ConditionTypeExtension on ConditionType {
  String get displayName {
    switch (this) {
      case ConditionType.connectivity:
        return 'Connectivity';
      case ConditionType.propertyCheck:
        return 'Property Check';
    }
  }
}

extension ConnectivityProtocolExtension on ConnectivityProtocol {
  String get displayName {
    switch (this) {
      case ConnectivityProtocol.ping:
        return 'PING';
      case ConnectivityProtocol.http:
        return 'HTTP';
      case ConnectivityProtocol.dnsLookup:
        return 'DNS Lookup';
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
    }
  }
}
