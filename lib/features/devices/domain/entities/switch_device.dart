import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';

/// Layer 2 Switch - Connects devices on the same local network
class SwitchDevice extends NetworkDevice
    implements IPowerable, ISwitchable, IConfigurable {
  String name;
  bool _isPoweredOn;
  final int portCount;
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
}

/// Switch port configuration
class SwitchPort {
  final int portId;
  String linkState; // "UP" | "DOWN"
  String? connectedToMac;
  int vlanId;
  String mode; // "Access" | "Trunk"

  SwitchPort({
    required this.portId,
    this.linkState = 'DOWN',
    this.connectedToMac,
    this.vlanId = 1,
    this.mode = 'Access',
  });

  Map<String, dynamic> toMap() => {
    'portId': portId,
    'linkState': linkState,
    'connectedToMac': connectedToMac,
    'vlanId': vlanId,
    'mode': mode,
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
