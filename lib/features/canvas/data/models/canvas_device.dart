import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart'
    show DeviceStatus;

/// Represents a device placed on the canvas
class CanvasDevice {
  final String id;
  final String name;
  final DeviceType type;
  Offset position;
  bool isSelected;
  DeviceStatus status;

  CanvasDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.isSelected = false,
    this.status = DeviceStatus.online,
  });

  CanvasDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    Offset? position,
    bool? isSelected,
    DeviceStatus? status,
  }) {
    return CanvasDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      isSelected: isSelected ?? this.isSelected,
      status: status ?? this.status,
    );
  }
}

/// Types of devices available
enum DeviceType { router, switch_, server, computer, firewall, accessPoint }

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.router:
        return 'Router';
      case DeviceType.switch_:
        return 'Switch';
      case DeviceType.server:
        return 'Server';
      case DeviceType.computer:
        return 'Computer';
      case DeviceType.firewall:
        return 'Firewall';
      case DeviceType.accessPoint:
        return 'Access Point';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.router:
        return Icons.router;
      case DeviceType.switch_:
        return Icons.hub;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.computer:
        return Icons.computer;
      case DeviceType.firewall:
        return Icons.security;
      case DeviceType.accessPoint:
        return Icons.wifi;
    }
  }

  Color get color {
    switch (this) {
      case DeviceType.router:
        return Colors.blue;
      case DeviceType.switch_:
        return Colors.green;
      case DeviceType.server:
        return Colors.orange;
      case DeviceType.computer:
        return Colors.purple;
      case DeviceType.firewall:
        return Colors.red;
      case DeviceType.accessPoint:
        return Colors.cyan;
    }
  }
}
