import 'package:flutter/foundation.dart';

/// Types of conditions that can be checked
enum ConditionType { connectivity, propertyCheck }

/// Protocol types for connectivity checks
enum ConnectivityProtocol { ping, http, dnsLookup }

/// Data types for properties
enum PropertyDataType { string, boolean, integer, ipAddress }

/// Operators for property checks
enum PropertyOperator { equals, notEquals, contains, greaterThan, lessThan }

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
  final PropertyDataType? propertyDataType;
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
    this.propertyDataType,
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
    PropertyDataType? propertyDataType,
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
      propertyDataType: propertyDataType ?? this.propertyDataType,
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
      if (propertyDataType != null)
        'propertyDataType': propertyDataType!.name.toUpperCase(),
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

    return ScenarioCondition(
      id: json['id'] as String,
      description: json['description'] as String,
      type: type,
      protocol: protocol,
      sourceDeviceID: json['sourceDeviceID'] as String?,
      targetAddress: json['targetAddress'] as String?,
      targetDeviceID: json['targetDeviceID'] as String?,
      property: json['property'] as String?,
      propertyDataType: propertyDataType,
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
