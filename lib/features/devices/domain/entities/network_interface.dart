import 'package:flutter/material.dart';

/// Status of a network interface
enum InterfaceStatus {
  up,
  down,
  disabled;

  String get displayName {
    switch (this) {
      case InterfaceStatus.up:
        return 'UP';
      case InterfaceStatus.down:
        return 'DOWN';
      case InterfaceStatus.disabled:
        return 'DISABLED';
    }
  }

  Color get color {
    switch (this) {
      case InterfaceStatus.up:
        return Colors.green;
      case InterfaceStatus.down:
        return Colors.orange;
      case InterfaceStatus.disabled:
        return Colors.red;
    }
  }
}

/// Represents a network interface on a device (e.g., eth0, eth1)
/// This is the foundation for proper routing and multi-homed device support
class NetworkInterface {
  /// Interface name (e.g., "eth0", "eth1", "wlan0")
  final String name;

  /// MAC address of this interface (Layer 2)
  final String macAddress;

  /// IP address configuration (Layer 3)
  String? ipAddress;
  String? subnetMask;
  String? defaultGateway;

  /// Current status of the interface
  InterfaceStatus status;

  /// Connected device information (for simulation)
  String? connectedDeviceId;
  int? connectedPort; // Port number if connected to a switch

  /// MTU (Maximum Transmission Unit)
  final int mtu;

  /// Statistics
  int packetsSent;
  int packetsReceived;
  int bytesSent;
  int bytesReceived;
  int errors;

  NetworkInterface({
    required this.name,
    required this.macAddress,
    this.ipAddress,
    this.subnetMask,
    this.defaultGateway,
    this.status = InterfaceStatus.down,
    this.connectedDeviceId,
    this.connectedPort,
    this.mtu = 1500,
    this.packetsSent = 0,
    this.packetsReceived = 0,
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.errors = 0,
  });

  /// Check if interface is operational (up and has IP)
  bool get isOperational =>
      status == InterfaceStatus.up && ipAddress != null && subnetMask != null;

  /// Check if this interface is on the same subnet as the given IP
  bool isOnSameSubnet(String targetIp) {
    if (ipAddress == null || subnetMask == null) return false;

    try {
      final myIpParts = ipAddress!.split('.').map(int.parse).toList();
      final targetIpParts = targetIp.split('.').map(int.parse).toList();
      final maskParts = subnetMask!.split('.').map(int.parse).toList();

      if (myIpParts.length != 4 ||
          targetIpParts.length != 4 ||
          maskParts.length != 4) {
        return false;
      }

      // Compare network portions
      for (int i = 0; i < 4; i++) {
        if ((myIpParts[i] & maskParts[i]) !=
            (targetIpParts[i] & maskParts[i])) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get network address for this interface
  String? get networkAddress {
    if (ipAddress == null || subnetMask == null) return null;

    try {
      final ipParts = ipAddress!.split('.').map(int.parse).toList();
      final maskParts = subnetMask!.split('.').map(int.parse).toList();

      if (ipParts.length != 4 || maskParts.length != 4) return null;

      final networkParts = List.generate(4, (i) => ipParts[i] & maskParts[i]);

      return networkParts.join('.');
    } catch (e) {
      return null;
    }
  }

  /// Bring interface up
  void bringUp() {
    if (status == InterfaceStatus.disabled) return;
    status = InterfaceStatus.up;
  }

  /// Bring interface down
  void bringDown() {
    if (status == InterfaceStatus.disabled) return;
    status = InterfaceStatus.down;
  }

  /// Enable interface (from disabled state)
  void enable() {
    if (status == InterfaceStatus.disabled) {
      status = InterfaceStatus.down;
    }
  }

  /// Disable interface
  void disable() {
    status = InterfaceStatus.disabled;
  }

  /// Update statistics when sending a packet
  void recordPacketSent(int bytes) {
    packetsSent++;
    bytesSent += bytes;
  }

  /// Update statistics when receiving a packet
  void recordPacketReceived(int bytes) {
    packetsReceived++;
    bytesReceived += bytes;
  }

  /// Record an error
  void recordError() {
    errors++;
  }

  /// Reset statistics
  void resetStatistics() {
    packetsSent = 0;
    packetsReceived = 0;
    bytesSent = 0;
    bytesReceived = 0;
    errors = 0;
  }

  /// Create a copy with updated fields
  NetworkInterface copyWith({
    String? name,
    String? macAddress,
    String? ipAddress,
    String? subnetMask,
    String? defaultGateway,
    InterfaceStatus? status,
    String? connectedDeviceId,
    int? connectedPort,
    int? mtu,
    int? packetsSent,
    int? packetsReceived,
    int? bytesSent,
    int? bytesReceived,
    int? errors,
  }) {
    return NetworkInterface(
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      defaultGateway: defaultGateway ?? this.defaultGateway,
      status: status ?? this.status,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      connectedPort: connectedPort ?? this.connectedPort,
      mtu: mtu ?? this.mtu,
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      errors: errors ?? this.errors,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'subnetMask': subnetMask,
      'defaultGateway': defaultGateway,
      'status': status.name,
      'connectedDeviceId': connectedDeviceId,
      'connectedPort': connectedPort,
      'mtu': mtu,
      'packetsSent': packetsSent,
      'packetsReceived': packetsReceived,
      'bytesSent': bytesSent,
      'bytesReceived': bytesReceived,
      'errors': errors,
    };
  }

  /// Create from JSON
  factory NetworkInterface.fromJson(Map<String, dynamic> json) {
    return NetworkInterface(
      name: json['name'] as String,
      macAddress: json['macAddress'] as String,
      ipAddress: json['ipAddress'] as String?,
      subnetMask: json['subnetMask'] as String?,
      defaultGateway: json['defaultGateway'] as String?,
      status: InterfaceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InterfaceStatus.down,
      ),
      connectedDeviceId: json['connectedDeviceId'] as String?,
      connectedPort: json['connectedPort'] as int?,
      mtu: json['mtu'] as int? ?? 1500,
      packetsSent: json['packetsSent'] as int? ?? 0,
      packetsReceived: json['packetsReceived'] as int? ?? 0,
      bytesSent: json['bytesSent'] as int? ?? 0,
      bytesReceived: json['bytesReceived'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'NetworkInterface($name: ${ipAddress ?? "no IP"} via $macAddress, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkInterface &&
        other.name == name &&
        other.macAddress == macAddress;
  }

  @override
  int get hashCode => name.hashCode ^ macAddress.hashCode;
}
