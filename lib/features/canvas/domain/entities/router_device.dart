import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_property.dart';

/// Layer 3 Router - Connects different networks
class RouterDevice extends NetworkDevice
    implements IPowerable, IRoutable, IConfigurable, IServiceHost {
  String name;
  bool _isPoweredOn;
  List<RouterInterface> interfaces;
  List<RouteEntry> _routingTable;
  bool natEnabled;
  bool dhcpServiceEnabled;
  bool firewallEnabled;
  bool showIpOnCanvas;

  RouterDevice({
    required super.deviceId,
    required super.position,
    String? name,
    bool isPoweredOn = true,
    List<RouterInterface>? interfaces,
    this.natEnabled = false,
    this.dhcpServiceEnabled = false,
    this.firewallEnabled = false,
    this.showIpOnCanvas = false,
  }) : name = name ?? deviceId,
       _isPoweredOn = isPoweredOn,
       interfaces =
           interfaces ??
           [
             RouterInterface(
               interfaceId: 'LAN',
               ipAddress: '192.168.1.1',
               subnetMask: '255.255.255.0',
               status: 'UP',
             ),
             RouterInterface(
               interfaceId: 'WAN',
               ipAddress: '203.0.113.2',
               subnetMask: '255.255.255.252',
               status: 'UP',
             ),
           ],
       _routingTable = [],
       super(deviceType: 'Router') {
    _initializeRoutingTable();
  }

  void _initializeRoutingTable() {
    for (var iface in interfaces) {
      _routingTable.add(
        RouteEntry(
          destination: _getNetworkAddress(iface.ipAddress, iface.subnetMask),
          subnetMask: iface.subnetMask,
          gateway: '0.0.0.0',
          interface: iface.interfaceId,
          type: 'Connected',
        ),
      );
    }
  }

  String _getNetworkAddress(String ip, String mask) {
    // Simplified - in real implementation, do actual subnet calculation
    return ip.substring(0, ip.lastIndexOf('.')) + '.0';
  }

  @override
  IconData get icon => Icons.router;

  @override
  Color get color => Colors.blue;

  @override
  String get displayName => showIpOnCanvas && interfaces.isNotEmpty
      ? interfaces.first.ipAddress
      : name;

  @override
  DeviceStatus get status {
    if (!_isPoweredOn) return DeviceStatus.offline;
    final activeInterfaces = interfaces.where((i) => i.status == 'UP').length;
    if (activeInterfaces == 0) return DeviceStatus.warning;
    return DeviceStatus.online;
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() => _isPoweredOn = true;

  @override
  void powerOff() {
    _isPoweredOn = false;
    for (var iface in interfaces) {
      iface.status = 'DOWN';
    }
  }

  @override
  void reboot() {
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), () {
      powerOn();
      for (var iface in interfaces) {
        iface.status = 'UP';
      }
    });
  }

  // IRoutable implementation
  @override
  List<Map<String, dynamic>> get routingTable =>
      _routingTable.map((r) => r.toMap()).toList();

  @override
  void addStaticRoute(String destination, String mask, String gateway) {
    final existingIndex = _routingTable.indexWhere(
      (r) => r.destination == destination && r.subnetMask == mask,
    );

    final route = RouteEntry(
      destination: destination,
      subnetMask: mask,
      gateway: gateway,
      interface: _findInterfaceForGateway(gateway),
      type: 'Static',
    );

    if (existingIndex != -1) {
      _routingTable[existingIndex] = route;
    } else {
      _routingTable.add(route);
    }
  }

  @override
  void removeStaticRoute(String destination) {
    _routingTable.removeWhere(
      (r) => r.destination == destination && r.type == 'Static',
    );
  }

  String _findInterfaceForGateway(String gateway) {
    // Find which interface this gateway is on
    for (var iface in interfaces) {
      // Simplified check
      if (gateway.startsWith(iface.ipAddress.substring(0, 10))) {
        return iface.interfaceId;
      }
    }
    return interfaces.first.interfaceId;
  }

  // IServiceHost implementation
  @override
  List<String> get runningServices {
    List<String> services = [];
    if (dhcpServiceEnabled) services.add('DHCP');
    if (firewallEnabled) services.add('Firewall');
    if (natEnabled) services.add('NAT');
    return services;
  }

  @override
  void startService(String serviceName) {
    switch (serviceName.toUpperCase()) {
      case 'DHCP':
        dhcpServiceEnabled = true;
        break;
      case 'FIREWALL':
        firewallEnabled = true;
        break;
      case 'NAT':
        natEnabled = true;
        break;
    }
  }

  @override
  void stopService(String serviceName) {
    switch (serviceName.toUpperCase()) {
      case 'DHCP':
        dhcpServiceEnabled = false;
        break;
      case 'FIREWALL':
        firewallEnabled = false;
        break;
      case 'NAT':
        natEnabled = false;
        break;
    }
  }

  @override
  void configureService(String serviceName, Map<String, dynamic> config) {
    // Configuration will be handled by specific service panels
  }

  // IConfigurable implementation
  @override
  Map<String, dynamic> get configuration => {
    'interfaces': interfaces.map((i) => i.toMap()).toList(),
    'routingTable': routingTable,
    'natEnabled': natEnabled,
    'dhcpServiceEnabled': dhcpServiceEnabled,
    'firewallEnabled': firewallEnabled,
  };

  @override
  void updateConfiguration(Map<String, dynamic> config) {
    if (config.containsKey('natEnabled')) {
      natEnabled = config['natEnabled'];
    }
  }

  @override
  String get capabilityName => 'Layer 3 Router';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  @override
  List<DeviceProperty> get properties {
    final List<DeviceProperty> props = [
      StringProperty(id: 'name', label: 'Device Name', value: name),
      BooleanProperty(
        id: 'showIpOnCanvas',
        label: 'Show IP on Canvas',
        value: showIpOnCanvas,
      ),
      StatusProperty(
        id: 'powerState',
        label: 'Power',
        value: _isPoweredOn ? 'ON' : 'OFF',
        color: _isPoweredOn ? Colors.green : Colors.red,
      ),
      IntegerProperty(
        id: 'interfaceCount',
        label: 'Interfaces',
        value: interfaces.length,
        isReadOnly: true,
      ),
      IntegerProperty(
        id: 'routeCount',
        label: 'Routes',
        value: _routingTable.length,
        isReadOnly: true,
      ),
    ];

    // Add IP addresses for each interface (read-only)
    for (var iface in interfaces) {
      props.add(
        IpAddressProperty(
          id: 'ip_${iface.interfaceId}',
          label: '${iface.interfaceId} IP',
          value: iface.ipAddress,
          isReadOnly: true,
        ),
      );
    }

    props.addAll([
      BooleanProperty(
        id: 'natEnabled',
        label: 'NAT Enabled',
        value: natEnabled,
      ),
      BooleanProperty(
        id: 'dhcpEnabled',
        label: 'DHCP Service',
        value: dhcpServiceEnabled,
      ),
      BooleanProperty(
        id: 'firewallEnabled',
        label: 'Firewall',
        value: firewallEnabled,
      ),
    ]);

    return props;
  }

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
        id: 'configure',
        label: 'Configure Router',
        icon: Icons.settings,
        onExecute: () {},
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'routing_table',
        label: 'View Routing Table',
        icon: Icons.table_chart,
        onExecute: () {},
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'nat_toggle',
        label: natEnabled ? 'Disable NAT' : 'Enable NAT',
        icon: Icons.swap_horiz,
        onExecute: () => natEnabled ? stopService('NAT') : startService('NAT'),
        isEnabled: _isPoweredOn,
      ),
    ];
  }

  void setInterfaceIp(String interfaceId, String ip, String subnet) {
    final iface = interfaces.firstWhere((i) => i.interfaceId == interfaceId);
    iface.ipAddress = ip;
    iface.subnetMask = subnet;
    _initializeRoutingTable(); // Rebuild connected routes
  }

  void setInterfaceStatus(String interfaceId, String status) {
    final iface = interfaces.firstWhere((i) => i.interfaceId == interfaceId);
    iface.status = status;
  }
}

/// Router Interface
class RouterInterface {
  final String interfaceId;
  String ipAddress;
  String subnetMask;
  String status; // "UP" | "DOWN"

  RouterInterface({
    required this.interfaceId,
    required this.ipAddress,
    required this.subnetMask,
    this.status = 'UP',
  });

  Map<String, dynamic> toMap() => {
    'interfaceId': interfaceId,
    'ipAddress': ipAddress,
    'subnetMask': subnetMask,
    'status': status,
  };
}

/// Routing Table Entry
class RouteEntry {
  final String destination;
  final String subnetMask;
  final String gateway;
  final String interface;
  final String type; // "Connected" | "Static" | "Dynamic"

  RouteEntry({
    required this.destination,
    required this.subnetMask,
    required this.gateway,
    required this.interface,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'destination': destination,
    'subnetMask': subnetMask,
    'gateway': gateway,
    'interface': interface,
    'type': type,
  };
}
