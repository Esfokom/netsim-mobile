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

/// Property permission levels
/// - denied: Property is completely hidden from view
/// - readonly: Property is visible but cannot be edited
/// - editable: Property is visible and can be edited
enum PropertyPermission { denied, readonly, editable }

/// Legacy rule types for backward compatibility
@Deprecated('Use PropertyPermission instead')
enum RuleType { allow, deny }

/// A rule that controls what actions can be performed on a device in simulation
@immutable
class DeviceRule {
  final String id;
  final PropertyPermission permission;
  final DeviceActionType actionType;
  final String?
  propertyId; // Specific property ID if actionType is editProperty

  const DeviceRule({
    required this.id,
    required this.permission,
    required this.actionType,
    this.propertyId,
  });

  DeviceRule copyWith({
    String? id,
    PropertyPermission? permission,
    DeviceActionType? actionType,
    String? propertyId,
  }) {
    return DeviceRule(
      id: id ?? this.id,
      permission: permission ?? this.permission,
      actionType: actionType ?? this.actionType,
      propertyId: propertyId ?? this.propertyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permission': permission.name.toUpperCase(),
      'actionType': actionType.name.toUpperCase(),
      if (propertyId != null) 'propertyId': propertyId,
    };
  }

  factory DeviceRule.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility: convert old 'type' to 'permission'
    PropertyPermission permission;
    if (json.containsKey('permission')) {
      final permissionStr = json['permission'].toString().toLowerCase();
      permission = PropertyPermission.values.firstWhere(
        (e) => e.name.toLowerCase() == permissionStr,
        orElse: () => PropertyPermission.denied,
      );
    } else if (json.containsKey('type')) {
      // Legacy support: convert old allow/deny to new permission model
      final typeStr = json['type'].toString().toLowerCase();
      if (typeStr == 'allow') {
        permission = PropertyPermission.editable;
      } else {
        permission = PropertyPermission.denied;
      }
    } else {
      // Default to denied if neither field exists
      permission = PropertyPermission.denied;
    }

    final actionTypeStr = json['actionType'].toString().toLowerCase();
    final actionType = DeviceActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == actionTypeStr,
      orElse: () => DeviceActionType.editProperty,
    );

    return DeviceRule(
      id: json['id'] as String,
      permission: permission,
      actionType: actionType,
      propertyId: json['propertyId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeviceRule &&
        other.id == id &&
        other.permission == permission &&
        other.actionType == actionType &&
        other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        permission.hashCode ^
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

extension PropertyPermissionExtension on PropertyPermission {
  String get displayName {
    switch (this) {
      case PropertyPermission.denied:
        return 'Denied (Hidden)';
      case PropertyPermission.readonly:
        return 'Read Only';
      case PropertyPermission.editable:
        return 'Editable';
    }
  }

  String get shortName {
    switch (this) {
      case PropertyPermission.denied:
        return 'Denied';
      case PropertyPermission.readonly:
        return 'Read Only';
      case PropertyPermission.editable:
        return 'Editable';
    }
  }
}

@Deprecated('Use PropertyPermissionExtension instead')
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
