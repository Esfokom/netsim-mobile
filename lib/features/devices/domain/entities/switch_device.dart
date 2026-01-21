import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/services/simulation_engine.dart';
import 'package:netsim_mobile/core/utils/app_logger.dart';

/// Layer 2 Switch - Connects devices on the same local network
class SwitchDevice extends NetworkDevice
    implements IPowerable, ISwitchable, IConfigurable {
  String name;
  bool _isPoweredOn;
  int portCount;
  List<SwitchPort> ports;
  final List<MacTableEntry> _macAddressTable;
  bool isManaged;
  List<VlanConfig> vlanDatabase;

  SwitchDevice({
    required super.deviceId,
    required super.position,
    String? name,
    this.portCount = 8,
    bool isPoweredOn = true,
    this.isManaged = false,
    List<SwitchPort>? ports,
    List<VlanConfig>? vlans,
  }) : name = name ?? deviceId,
       _isPoweredOn = isPoweredOn,
       ports =
           ports ??
           List.generate(
             portCount,
             (index) =>
                 SwitchPort(portId: index + 1, linkState: 'DOWN', vlanId: 1),
           ),
       vlanDatabase = vlans ?? [VlanConfig(vlanId: 1, name: 'Default')],
       _macAddressTable = [],
       super(deviceType: 'Switch');

  @override
  IconData get icon => Icons.hub;

  @override
  Color get color => Colors.green;

  @override
  String get displayName => name;

  @override
  DeviceStatus get status {
    // Simple two-state model: online when powered on, offline when powered off
    return _isPoweredOn ? DeviceStatus.online : DeviceStatus.offline;
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() {
    _isPoweredOn = true;
  }

  @override
  void powerOff() {
    _isPoweredOn = false;
    _macAddressTable.clear();
  }

  @override
  void reboot() {
    _macAddressTable.clear();
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), powerOn);
  }

  // ISwitchable implementation
  @override
  List<Map<String, dynamic>> get macAddressTable =>
      _macAddressTable.map((entry) => entry.toMap()).toList();

  @override
  void clearMacAddressTable() {
    _macAddressTable.clear();
  }

  @override
  void createVlan(int vlanId, String name) {
    if (!isManaged) return;
    if (!vlanDatabase.any((v) => v.vlanId == vlanId)) {
      vlanDatabase.add(VlanConfig(vlanId: vlanId, name: name));
    }
  }

  @override
  void assignPortToVlan(int portId, int vlanId) {
    if (!isManaged) return;
    final portIndex = ports.indexWhere((p) => p.portId == portId);
    if (portIndex != -1) {
      ports[portIndex].vlanId = vlanId;
    }
  }

  // IConfigurable implementation
  @override
  Map<String, dynamic> get configuration => {
    'portCount': portCount,
    'isManaged': isManaged,
    'vlans': vlanDatabase.map((v) => v.toMap()).toList(),
    'ports': ports.map((p) => p.toMap()).toList(),
  };

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('isManaged')) {
      isManaged = config['isManaged'];
    }
    if (config.containsKey('portCount')) {
      setPortCount(config['portCount']);
    }
  }

  /// Set the number of ports on the switch (min 3, max 12)
  /// Disconnects devices on ports that are removed
  void setPortCount(int newCount) {
    if (newCount < 3 || newCount > 12) {
      appLogger.w('Invalid port count: $newCount. Must be between 3 and 12.');
      return;
    }

    if (newCount < portCount) {
      // Removing ports - disconnect links on removed ports
      for (int i = newCount + 1; i <= portCount; i++) {
        final port = ports.firstWhere(
          (p) => p.portId == i,
          orElse: () => SwitchPort(portId: -1),
        );
        if (port.portId != -1 && port.connectedLinkId != null) {
          port.connectedLinkId = null;
          port.linkState = 'DOWN';
        }
      }
      // Remove excess ports
      ports.removeWhere((p) => p.portId > newCount);
    } else if (newCount > portCount) {
      // Adding ports
      for (int i = portCount + 1; i <= newCount; i++) {
        ports.add(SwitchPort(portId: i, linkState: 'DOWN', vlanId: 1));
      }
    }

    portCount = newCount;
  }

  @override
  String get capabilityName => 'Layer 2 Switch';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  @override
  List<DeviceProperty> get properties => [
    StringProperty(id: 'name', label: 'Device Name', value: name),
    StatusProperty(
      id: 'powerState',
      label: 'Power',
      value: _isPoweredOn ? 'ON' : 'OFF',
      color: _isPoweredOn ? Colors.green : Colors.red,
    ),
    IntegerProperty(
      id: 'portCount',
      label: 'Port Count',
      value: portCount,
      isReadOnly: true,
    ),
    IntegerProperty(
      id: 'activePortsCount',
      label: 'Active Ports',
      value: ports.where((p) => p.linkState == 'UP').length,
      isReadOnly: true,
    ),
    BooleanProperty(
      id: 'isManaged',
      label: 'Managed Switch',
      value: isManaged,
      isReadOnly: true,
    ),
    IntegerProperty(
      id: 'macTableSize',
      label: 'MAC Table Entries',
      value: _macAddressTable.length,
      isReadOnly: true,
    ),
    if (isManaged)
      IntegerProperty(
        id: 'vlanCount',
        label: 'Configured VLANs',
        value: vlanDatabase.length,
        isReadOnly: true,
      ),
  ];

  @override
  List<DeviceAction> getAvailableActions() {
    return [
      DeviceAction(
        id: 'power_toggle',
        label: _isPoweredOn ? 'Power Off' : 'Power On',
        icon: Icons.power_settings_new,
        onExecute: _isPoweredOn ? powerOff : powerOn,
      ),
      DeviceAction(
        id: 'reboot',
        label: 'Reboot',
        icon: Icons.restart_alt,
        onExecute: reboot,
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'clear_mac_table',
        label: 'Clear MAC Table',
        icon: Icons.clear_all,
        onExecute: clearMacAddressTable,
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'configure_ports',
        label: 'Configure Ports',
        icon: Icons.settings_input_component,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'view_cam_table',
        label: 'View CAM Table',
        icon: Icons.table_rows,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'adjust_port_count',
        label: 'Adjust Port Count',
        icon: Icons.add_box,
        onExecute: () {}, // UI will handle this
        isEnabled: true, // Always enabled for configuration
      ),
      if (isManaged)
        DeviceAction(
          id: 'configure',
          label: 'Configure VLANs',
          icon: Icons.settings,
          onExecute: () {}, // UI will handle this
          isEnabled: _isPoweredOn,
        ),
    ];
  }

  /// Add MAC address to table (called by simulation engine)
  void learnMacAddress(String macAddress, int portId) {
    if (!_isPoweredOn) return;

    _macAddressTable.removeWhere((entry) => entry.macAddress == macAddress);
    _macAddressTable.add(
      MacTableEntry(
        macAddress: macAddress,
        portId: portId,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Get list of available (unconnected) ports
  List<SwitchPort> getAvailablePorts() {
    return ports
        .where(
          (p) =>
              p.isEnabled && p.connectedLinkId == null && p.linkState == 'DOWN',
        )
        .toList();
  }

  /// Get port by port ID
  SwitchPort? getPortById(int portId) {
    try {
      return ports.firstWhere((p) => p.portId == portId);
    } catch (e) {
      return null;
    }
  }

  /// Disconnect a port by link ID
  void disconnectPortByLinkId(String linkId) {
    final portIndex = ports.indexWhere((p) => p.connectedLinkId == linkId);
    if (portIndex != -1) {
      final port = ports[portIndex];
      appLogger.d('[Switch $name] Disconnecting port ${port.portId}');

      port.connectedLinkId = null;
      port.linkState = 'DOWN';
      port.connectedToMac = null;

      // Remove MAC entries learned on this port
      _macAddressTable.removeWhere((entry) => entry.portId == port.portId);

      appLogger.d('[Switch $name] Port ${port.portId} is now available');
    }
  }

  /// Connect a port to a link
  void connectPort(int portId, String linkId) {
    final port = getPortById(portId);
    if (port == null) {
      appLogger.w('[Switch $name] Port $portId not found');
      return;
    }

    if (port.connectedLinkId != null) {
      appLogger.w(
        '[Switch $name] Port $portId is already connected to ${port.connectedLinkId}',
      );
      return;
    }

    if (!port.isEnabled) {
      appLogger.w('[Switch $name] Port $portId is disabled');
      return;
    }

    port.connectedLinkId = linkId;
    port.linkState = 'UP';
    appLogger.d('[Switch $name] Port $portId connected to link $linkId');
  }

  /// Handle incoming packet
  void handlePacket(
    Packet packet,
    String incomingLinkId,
    SimulationEngine engine,
  ) {
    if (!_isPoweredOn) return;

    appLogger.d(
      '[Switch $name] Received ${packet.type} packet: ${packet.sourceMac} -> ${packet.destMac}',
    );

    // 1. Determine Ingress Port
    int ingressPortId = -1;
    for (var port in ports) {
      if (port.connectedLinkId == incomingLinkId) {
        ingressPortId = port.portId;
        break;
      }
    }

    if (ingressPortId == -1) {
      appLogger.w(
        '[Switch $name] Could not find ingress port for link $incomingLinkId',
      );
      return;
    }

    final ingressPort = ports.firstWhere((p) => p.portId == ingressPortId);
    if (!ingressPort.isEnabled) {
      appLogger.d(
        '[Switch $name] Port $ingressPortId is disabled. Dropping packet.',
      );
      return;
    }

    appLogger.d('[Switch $name] Packet received on port $ingressPortId');

    // 2. Learn Source MAC
    learnMacAddress(packet.sourceMac, ingressPortId);
    appLogger.d(
      '[Switch $name] Learned MAC ${packet.sourceMac} on port $ingressPortId',
    );

    // 3. Forwarding Decision
    if (packet.destMac == 'FF:FF:FF:FF:FF:FF') {
      // Broadcast to all ports except ingress
      appLogger.i(
        '[Switch $name] Broadcasting packet to all ports except port $ingressPortId',
      );
      _floodPacket(packet, ingressPortId, engine);
    } else {
      // Unicast
      final entry = _macAddressTable.firstWhere(
        (e) => e.macAddress == packet.destMac,
        orElse: () => MacTableEntry(
          macAddress: '',
          portId: -1,
          timestamp: DateTime.now(),
        ),
      );

      if (entry.portId != -1) {
        // Known destination
        appLogger.i(
          '[Switch $name] Forwarding to known destination on port ${entry.portId}',
        );
        _forwardToPort(packet, entry.portId, engine);
      } else {
        // Unknown destination -> Flood
        appLogger.i(
          '[Switch $name] Unknown destination, flooding to all ports except port $ingressPortId',
        );
        _floodPacket(packet, ingressPortId, engine);
      }
    }
  }

  void _forwardToPort(Packet packet, int portId, SimulationEngine engine) {
    final port = ports.firstWhere((p) => p.portId == portId);
    if (port.isEnabled && port.connectedLinkId != null) {
      engine.deliverPacketOnLinkFrom(packet, port.connectedLinkId!, deviceId);
    } else {
      appLogger.d(
        '[Switch] Cannot forward to port $portId (disabled or disconnected)',
      );
    }
  }

  void _floodPacket(Packet packet, int ingressPortId, SimulationEngine engine) {
    appLogger.d(
      '[Switch $name] Flooding packet to all enabled ports except port $ingressPortId',
    );
    int forwardCount = 0;
    for (var port in ports) {
      if (port.portId != ingressPortId &&
          port.isEnabled &&
          port.connectedLinkId != null) {
        appLogger.d(
          '[Switch $name] Flooding to port ${port.portId} via link ${port.connectedLinkId}',
        );
        engine.deliverPacketOnLinkFrom(packet, port.connectedLinkId!, deviceId);
        forwardCount++;
      }
    }
    appLogger.d('[Switch $name] Flooded packet to $forwardCount ports');
  }
}

class SwitchPort {
  final int portId;
  String linkState; // "UP" | "DOWN"
  String? connectedToMac;
  int vlanId;
  String mode; // "Access" | "Trunk"
  bool isEnabled;
  String? connectedLinkId; // Link ID connected to this port

  SwitchPort({
    required this.portId,
    this.linkState = 'DOWN',
    this.connectedToMac,
    this.vlanId = 1,
    this.mode = 'Access',
    this.isEnabled = true,
    this.connectedLinkId,
  });

  Map<String, dynamic> toMap() => {
    'portId': portId,
    'linkState': linkState,
    'connectedToMac': connectedToMac,
    'vlanId': vlanId,
    'mode': mode,
    'isEnabled': isEnabled,
    'connectedLinkId': connectedLinkId,
  };
}

/// MAC Address Table Entry
class MacTableEntry {
  final String macAddress;
  final int portId;
  final DateTime timestamp;

  MacTableEntry({
    required this.macAddress,
    required this.portId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'macAddress': macAddress,
    'portId': portId,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// VLAN Configuration
class VlanConfig {
  final int vlanId;
  final String name;

  VlanConfig({required this.vlanId, required this.name});

  Map<String, dynamic> toMap() => {'vlanId': vlanId, 'name': name};
}
