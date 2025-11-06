import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/canvas/domain/entities/network_device.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_capability.dart';
import 'package:netsim_mobile/features/canvas/domain/interfaces/device_property.dart';

/// End Device (PC/Workstation) - Player's main interaction point
class EndDevice extends NetworkDevice
    implements
        IPowerable,
        INetworkConfigurable,
        IConnectable,
        ITerminalAccessible {
  // Properties
  String hostname;
  final String macAddress;
  bool _isPoweredOn;
  String _linkState;

  // IP Configuration
  String ipConfigMode; // "STATIC" | "DHCP"
  String? staticIpAddress;
  String? staticSubnetMask;
  String? staticDefaultGateway;
  String? staticDnsServer1;
  String? staticDnsServer2;

  String? dhcpIpAddress;
  String? dhcpSubnetMask;
  String? dhcpDefaultGateway;
  String? dhcpDnsServer1;
  DateTime? dhcpLeaseObtained;
  DateTime? dhcpLeaseExpires;

  // Current active configuration
  String? currentIpAddress;
  String? currentSubnetMask;
  String? currentDefaultGateway;
  List<String> currentDnsServers;
  List<Map<String, String>> arpCache;

  // Tools and state
  List<String> installedTools;
  String statusMessage;

  EndDevice({
    required super.deviceId,
    required super.position,
    required this.hostname,
    required this.macAddress,
    String deviceType = 'PC',
    this.ipConfigMode = 'DHCP',
    bool isPoweredOn = true,
    String linkState = 'DOWN',
    this.installedTools = const ['ipconfig', 'ping', 'nslookup', 'traceroute'],
    this.statusMessage = 'Not connected',
    this.currentDnsServers = const [],
    this.arpCache = const [],
  }) : _isPoweredOn = isPoweredOn,
       _linkState = linkState,
       super(deviceType: deviceType);

  @override
  IconData get icon => Icons.computer;

  @override
  Color get color => Colors.purple;

  @override
  String get displayName => hostname;

  @override
  DeviceStatus get status {
    if (!_isPoweredOn) return DeviceStatus.offline;
    if (_linkState == 'DOWN') return DeviceStatus.warning;
    if (currentIpAddress == null) return DeviceStatus.notConfigured;
    return DeviceStatus.online;
  }

  // IPowerable implementation
  @override
  bool get isPoweredOn => _isPoweredOn;

  @override
  void powerOn() {
    _isPoweredOn = true;
    statusMessage = _linkState == 'UP' ? 'Booting...' : 'No cable connected';
  }

  @override
  void powerOff() {
    _isPoweredOn = false;
    statusMessage = 'Powered off';
  }

  @override
  void reboot() {
    powerOff();
    Future.delayed(const Duration(milliseconds: 500), powerOn);
  }

  // INetworkConfigurable implementation
  @override
  String? get ipAddress => currentIpAddress;

  @override
  String? get subnetMask => currentSubnetMask;

  @override
  String? get defaultGateway => currentDefaultGateway;

  @override
  void setStaticIp(String ip, String subnet, String gateway) {
    ipConfigMode = 'STATIC';
    staticIpAddress = ip;
    staticSubnetMask = subnet;
    staticDefaultGateway = gateway;

    currentIpAddress = ip;
    currentSubnetMask = subnet;
    currentDefaultGateway = gateway;

    statusMessage = 'Static IP configured';
  }

  @override
  void enableDhcp() {
    ipConfigMode = 'DHCP';
    staticIpAddress = null;
    statusMessage = 'Requesting DHCP...';
    // Simulation engine will assign DHCP values
  }

  // IConnectable implementation
  @override
  String get linkState => _linkState;

  @override
  void connectCable(String targetDeviceId, int targetPort) {
    _linkState = 'UP';
    statusMessage = 'Cable connected';
  }

  @override
  void disconnectCable() {
    _linkState = 'DOWN';
    currentIpAddress = null;
    statusMessage = 'Cable disconnected';
  }

  // ITerminalAccessible implementation
  @override
  List<String> get availableCommands => installedTools;

  @override
  String runCommand(String command, List<String> args) {
    // Simulation logic will be handled by game engine
    return 'Executing $command ${args.join(' ')}...';
  }

  // Capability and Property implementations
  @override
  String get capabilityName => 'End Device';

  @override
  List<DeviceAction> get availableActions => getAvailableActions();

  @override
  List<DeviceCapability> get capabilities => [this];

  /// Whether IP address can be edited (true for EndDevice, false for Server/Router/etc)
  bool get canEditIpAddress => true;

  @override
  List<DeviceProperty> get properties => [
    StringProperty(id: 'hostname', label: 'Hostname', value: hostname),
    MacAddressProperty(
      id: 'macAddress',
      label: 'MAC Address',
      value: macAddress,
    ),
    StatusProperty(
      id: 'powerState',
      label: 'Power',
      value: _isPoweredOn ? 'ON' : 'OFF',
      color: _isPoweredOn ? Colors.green : Colors.red,
    ),
    StatusProperty(
      id: 'linkState',
      label: 'Link',
      value: _linkState,
      color: _linkState == 'UP' ? Colors.green : Colors.orange,
    ),
    if (canEditIpAddress)
      SelectionProperty(
        id: 'ipConfigMode',
        label: 'IP Configuration',
        value: ipConfigMode,
        options: ['STATIC', 'DHCP'],
      ),
    IpAddressProperty(
      id: 'currentIp',
      label: 'IP Address',
      value: currentIpAddress ?? 'Not assigned',
      isReadOnly: !canEditIpAddress || ipConfigMode == 'DHCP',
    ),
    IpAddressProperty(
      id: 'currentSubnet',
      label: 'Subnet Mask',
      value: currentSubnetMask ?? 'Not assigned',
      isReadOnly: !canEditIpAddress || ipConfigMode == 'DHCP',
    ),
    IpAddressProperty(
      id: 'currentGateway',
      label: 'Default Gateway',
      value: currentDefaultGateway ?? 'Not assigned',
      isReadOnly: !canEditIpAddress || ipConfigMode == 'DHCP',
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
        id: 'open_terminal',
        label: 'Open Terminal',
        icon: Icons.terminal,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'ip_config',
        label: 'Configure IP',
        icon: Icons.settings_ethernet,
        onExecute: () {}, // UI will handle this
        isEnabled: _isPoweredOn,
      ),
      DeviceAction(
        id: 'dhcp_renew',
        label: 'Renew DHCP',
        icon: Icons.refresh,
        onExecute: enableDhcp,
        isEnabled: _isPoweredOn && ipConfigMode == 'DHCP',
      ),
      if (_linkState == 'DOWN')
        DeviceAction(
          id: 'connect_cable',
          label: 'Connect Cable',
          icon: Icons.cable,
          onExecute: () {}, // UI will handle drag/drop
        ),
    ];
  }
}
