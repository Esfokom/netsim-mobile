import 'package:flutter/foundation.dart';

/// Types of actions that can be controlled by rules
enum DeviceActionType {
  editProperty,
  changePosition,
  delete,
  powerOn,
  powerOff,
  createLink,
  removeLink,
}

/// Rule types
enum RuleType { allow, deny }

/// A rule that controls what actions can be performed on a device in simulation
@immutable
class DeviceRule {
  final String id;
  final RuleType type;
  final DeviceActionType actionType;
  final String?
  propertyId; // Specific property ID if actionType is editProperty

  const DeviceRule({
    required this.id,
    required this.type,
    required this.actionType,
    this.propertyId,
  });

  DeviceRule copyWith({
    String? id,
    RuleType? type,
    DeviceActionType? actionType,
    String? propertyId,
  }) {
    return DeviceRule(
      id: id ?? this.id,
      type: type ?? this.type,
      actionType: actionType ?? this.actionType,
      propertyId: propertyId ?? this.propertyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name.toUpperCase(),
      'actionType': actionType.name.toUpperCase(),
      if (propertyId != null) 'propertyId': propertyId,
    };
  }

  factory DeviceRule.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'].toString().toLowerCase();
    final type = typeStr == 'allow' ? RuleType.allow : RuleType.deny;

    final actionTypeStr = json['actionType'].toString().toLowerCase();
    final actionType = DeviceActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == actionTypeStr,
      orElse: () => DeviceActionType.editProperty,
    );

    return DeviceRule(
      id: json['id'] as String,
      type: type,
      actionType: actionType,
      propertyId: json['propertyId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeviceRule &&
        other.id == id &&
        other.type == type &&
        other.actionType == actionType &&
        other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        actionType.hashCode ^
        propertyId.hashCode;
  }
}

extension DeviceActionTypeExtension on DeviceActionType {
  String get displayName {
    switch (this) {
      case DeviceActionType.editProperty:
        return 'Edit Property';
      case DeviceActionType.changePosition:
        return 'Change Position';
      case DeviceActionType.delete:
        return 'Delete Device';
      case DeviceActionType.powerOn:
        return 'Power On';
      case DeviceActionType.powerOff:
        return 'Power Off';
      case DeviceActionType.createLink:
        return 'Create Link';
      case DeviceActionType.removeLink:
        return 'Remove Link';
    }
  }

  String get description {
    switch (this) {
      case DeviceActionType.editProperty:
        return 'Ability to modify device properties';
      case DeviceActionType.changePosition:
        return 'Ability to move device on canvas';
      case DeviceActionType.delete:
        return 'Ability to delete the device';
      case DeviceActionType.powerOn:
        return 'Ability to power on the device';
      case DeviceActionType.powerOff:
        return 'Ability to power off the device';
      case DeviceActionType.createLink:
        return 'Ability to create connections';
      case DeviceActionType.removeLink:
        return 'Ability to remove connections';
    }
  }
}

extension RuleTypeExtension on RuleType {
  String get displayName {
    switch (this) {
      case RuleType.allow:
        return 'Allow';
      case RuleType.deny:
        return 'Deny';
    }
  }
}
