import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/data/models/canvas_device.dart'
    as legacy;
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/server_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/switch_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/router_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/firewall_device.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/wireless_access_point.dart';

/// Factory for creating NetworkDevice entities from CanvasDevice models
/// This provides the bridge between the old canvas system and new device architecture
class DeviceFactory {
  /// Create a NetworkDevice from a CanvasDevice
  static NetworkDevice fromCanvasDevice(legacy.CanvasDevice canvasDevice) {
    final macAddress = _generateMAC(canvasDevice.id);

    switch (canvasDevice.type) {
      case legacy.DeviceType.computer:
        return EndDevice(
          deviceId: canvasDevice.id,
          position: canvasDevice.position,
          hostname: canvasDevice.name,
          macAddress: macAddress,
          ipConfigMode: 'DHCP',
          isPoweredOn: canvasDevice.status != legacy.DeviceStatus.offline,
        );

      case legacy.DeviceType.server:
        final server = ServerDevice(
          deviceId: canvasDevice.id,
          position: canvasDevice.position,
          hostname: canvasDevice.name,
          macAddress: macAddress,
        );

        // Initialize with basic services
        server.addService('DHCP', DhcpServiceConfig(isRunning: false));
        server.addService('DNS', DnsServiceConfig(isRunning: false));
        server.addService('WEB', WebServiceConfig(isRunning: false));

        return server;

      case legacy.DeviceType.switch_:
        return SwitchDevice(
          deviceId: canvasDevice.id,
          position: canvasDevice.position,
          portCount: 8,
          isManaged: false,
          isPoweredOn: canvasDevice.status != legacy.DeviceStatus.offline,
        );

      case legacy.DeviceType.router:
        return RouterDevice(
          deviceId: canvasDevice.id,
          position: canvasDevice.position,
          isPoweredOn: canvasDevice.status != legacy.DeviceStatus.offline,
          natEnabled: false,
          dhcpServiceEnabled: false,
          firewallEnabled: false,
        );

      case legacy.DeviceType.firewall:
        return FirewallDevice(
          deviceId: canvasDevice.id,
          position: canvasDevice.position,
          isPoweredOn: canvasDevice.status != legacy.DeviceStatus.offline,
          defaultPolicy: 'DENY',
        );

      case legacy.DeviceType.accessPoint:
        return WirelessAccessPoint(
          deviceId: canvasDevice.id,
          position: canvasDevice.position,
          isPoweredOn: canvasDevice.status != legacy.DeviceStatus.offline,
          ssid: 'Network-${canvasDevice.id.substring(0, 4)}',
          securityMode: 'WPA2',
          wpaPassword: 'password123',
        );
    }
  }

  /// Create a CanvasDevice from a NetworkDevice (reverse conversion)
  static legacy.CanvasDevice toCanvasDevice(NetworkDevice networkDevice) {
    return legacy.CanvasDevice(
      id: networkDevice.deviceId,
      name: networkDevice.displayName,
      type: _getDeviceType(networkDevice),
      position: networkDevice.position,
      isSelected: networkDevice.isSelected,
      status: _getDeviceStatus(networkDevice.status),
    );
  }

  /// Map NetworkDevice type to CanvasDevice DeviceType
  static legacy.DeviceType _getDeviceType(NetworkDevice device) {
    switch (device.deviceType) {
      case 'PC':
        return legacy.DeviceType.computer;
      case 'Server':
        return legacy.DeviceType.server;
      case 'Switch':
        return legacy.DeviceType.switch_;
      case 'Router':
        return legacy.DeviceType.router;
      case 'Firewall':
        return legacy.DeviceType.firewall;
      case 'WAP':
        return legacy.DeviceType.accessPoint;
      default:
        return legacy.DeviceType.computer;
    }
  }

  /// Map NetworkDevice status to CanvasDevice DeviceStatus
  static legacy.DeviceStatus _getDeviceStatus(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return legacy.DeviceStatus.online;
      case DeviceStatus.offline:
        return legacy.DeviceStatus.offline;
      case DeviceStatus.warning:
      case DeviceStatus.notConfigured:
        return legacy.DeviceStatus.warning;
      case DeviceStatus.error:
      case DeviceStatus.configured:
        return legacy.DeviceStatus.error;
    }
  }

  /// Generate a unique MAC address based on device ID
  static String _generateMAC(String deviceId) {
    final hash = deviceId.hashCode.abs();
    final hex = hash.toRadixString(16).padLeft(12, '0').substring(0, 12);

    return '${hex.substring(0, 2)}:${hex.substring(2, 4)}:${hex.substring(4, 6)}:'
            '${hex.substring(6, 8)}:${hex.substring(8, 10)}:${hex.substring(10, 12)}'
        .toUpperCase();
  }

  /// Generate default IP address based on device type
  static String? getDefaultIP(legacy.DeviceType type, int index) {
    switch (type) {
      case legacy.DeviceType.router:
        return '192.168.$index.1';
      case legacy.DeviceType.server:
        return '192.168.1.${100 + index}';
      case legacy.DeviceType.computer:
      case legacy.DeviceType.accessPoint:
        return null; // Will use DHCP
      case legacy.DeviceType.switch_:
        return '192.168.1.${200 + index}';
      case legacy.DeviceType.firewall:
        return '192.168.1.${250 + index}';
    }
  }
}
