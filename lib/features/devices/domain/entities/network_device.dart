import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';

/// Base abstract class for all network devices
/// Uses composition pattern - devices are defined by their capabilities
abstract class NetworkDevice {
  // Core Identity
  final String deviceId;
  final String deviceType;

  // UI Positioning
  Offset position;
  bool isSelected;

  NetworkDevice({
    required this.deviceId,
    required this.deviceType,
    required this.position,
    this.isSelected = false,
  });

  // Abstract methods that must be implemented by concrete devices

  /// Returns all capabilities this device has
  List<DeviceCapability> get capabilities;

  /// Returns all properties this device has
  List<DeviceProperty> get properties;

  /// Returns the icon to display for this device
  IconData get icon;

  /// Returns the color theme for this device
  Color get color;

  /// Returns the display name for this device
  String get displayName;

  /// Returns the current status for dashboard
  DeviceStatus get status;

  /// Returns available actions for context menu
  List<DeviceAction> getAvailableActions();

  /// Update device position
  void updatePosition(Offset newPosition) {
    position = newPosition;
  }

  /// Select/deselect device
  void setSelected(bool selected) {
    isSelected = selected;
  }
}

/// Device status for dashboard display
enum DeviceStatus { online, offline, warning, error, configured, notConfigured }

extension DeviceStatusExtension on DeviceStatus {
  Color get color {
    switch (this) {
      case DeviceStatus.online:
        return Colors.green;
      case DeviceStatus.offline:
        return Colors.grey;
      case DeviceStatus.warning:
        return Colors.orange;
      case DeviceStatus.error:
        return Colors.red;
      case DeviceStatus.configured:
        return Colors.blue;
      case DeviceStatus.notConfigured:
        return Colors.amber;
    }
  }

  String get label {
    switch (this) {
      case DeviceStatus.online:
        return 'Online';
      case DeviceStatus.offline:
        return 'Offline';
      case DeviceStatus.warning:
        return 'Warning';
      case DeviceStatus.error:
        return 'Error';
      case DeviceStatus.configured:
        return 'Configured';
      case DeviceStatus.notConfigured:
        return 'Not Configured';
    }
  }
}
